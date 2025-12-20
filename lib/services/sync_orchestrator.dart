import 'dart:async';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import 'task_storage.dart';
import 'stats_storage.dart';
import 'supabase_task_repository.dart';
import 'supabase_analytics_repository.dart';
import 'task_sync_service.dart';
import 'supabase_auth_service.dart';

class SyncOrchestrator {
  static final SyncOrchestrator _instance = SyncOrchestrator._internal();
  factory SyncOrchestrator() => _instance;
  SyncOrchestrator._internal();

  final SupabaseTaskRepository _remoteRepo = SupabaseTaskRepository();
  final SupabaseAuthService _authService = SupabaseAuthService();
  bool _isSyncing = false;
  StreamSubscription? _authSubscription;
  Timer? _syncDebounceTimer;
  bool _syncScheduled = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _syncDebounceDelay = Duration(seconds: 2);
  
  void initialize() {
    // Listen for auth changes to trigger sync
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        scheduleSync();
      }
    });
  }

  /// Schedule a sync with debouncing to batch multiple changes
  void scheduleSync() {
    if (_syncScheduled) {
      // Cancel existing timer and reschedule
      _syncDebounceTimer?.cancel();
    }

    _syncScheduled = true;
    _syncDebounceTimer = Timer(_syncDebounceDelay, () {
      _syncScheduled = false;
      syncNow();
    });
    
    debugPrint('Sync scheduled (debounced)');
  }

  Future<void> deleteRemoteTask(String taskId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      debugPrint('🔥 Instant Delete: Removing task $taskId from Supabase...');
      await _remoteRepo.deleteTask(taskId);
      debugPrint('✅ Instant Delete: Task $taskId removed from Supabase');
    } catch (e) {
      debugPrint('⚠️ Create/Delete failed: $e');
      // We don't rethrow because UI already updated.
      // Next full sync will catch it if it failed (by checking missing local tasks vs remote)
      // Actually strictly speaking, full sync might revive it if we don't track deletions.
      // But for "Instant Delete" best effort, this is the start.
    }
  }

  Future<void> syncNow() async {
    if (_isSyncing) return;
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return; // Not signed in, local only mode

    _isSyncing = true;
    try {
      debugPrint('Starting Sync...');
      
      // 1. Fetch Remote & Local Tasks
      final remoteTasks = await _remoteRepo.getTasks();
      final localTasks = await TaskStorage.loadTasks();
      
      debugPrint('Sync: Fetched ${remoteTasks.length} remote and ${localTasks.length} local tasks');

      // ----------------------------------------------------------------------
      // PHASE 1: Process Local Deletions (Tombstones)
      // ----------------------------------------------------------------------
      // If we have a local task marked isDeleted, we MUST delete it on server (Hard Delete)
      // and then remove it locally.
      final tasksToDelete = localTasks.where((t) => t.isDeleted).toList();
      for (final task in tasksToDelete) {
        debugPrint('🗑️ Processing local deletion for "${task.title}"');
        await _remoteRepo.deleteTask(task.id);
        localTasks.removeWhere((t) => t.id == task.id); // Remove from memory
      }
      
      if (tasksToDelete.isNotEmpty) {
         // Save intermediate state to prevent resurrections if crash happens
         await TaskStorage.saveTasks(localTasks); 
         debugPrint('Sync: Processed & removed ${tasksToDelete.length} local deletions');
      }

      // ----------------------------------------------------------------------
      // PHASE 2: Inferential Deletion (Server -> Local)
      // ----------------------------------------------------------------------
      // If a task is known to be synced (lastSynced != null) but is missing from
      // the fresh remote list, it means it was deleted on another device.
      // We must Hard Delete it locally.
      
      // Refresh remote tasks to be sure (in case Phase 1 affected query, though unlikely)
      // Actually we can use the list from step 1 for inference check if we haven't touched it.
      // But let's rely on the initial fetch 'remoteTasks'.
      
      final remoteIds = remoteTasks.map((t) => t.id).toSet();
      final inferredDeletions = <Task>[];
      
      localTasks.removeWhere((task) {
        // Only infer deletion for tasks that we KNOW were on the server before
        final wasSynced = task.lastSynced != null;
        final isMissingRemote = !remoteIds.contains(task.id);
        
        if (wasSynced && isMissingRemote) {
          debugPrint('🗑️ Inferential Delete: "${task.title}" missing from server, deleting locally.');
          inferredDeletions.add(task);
          return true; // Remove from list
        }
        return false;
      });
      
      if (inferredDeletions.isNotEmpty) {
        await TaskStorage.saveTasks(localTasks);
        debugPrint('Sync: Inferred & removed ${inferredDeletions.length} external deletions');
      }

      // ----------------------------------------------------------------------
      // PHASE 3: Push Local Updates / Creates
      // ----------------------------------------------------------------------
      int created = 0, updated = 0;
      
      for (final localTask in localTasks) {
        final remoteVersion = remoteTasks.firstWhere(
          (t) => t.id == localTask.id, 
          orElse: () => Task(id: 'missing', title: '', isDeleted: true)
        );
        
        if (remoteVersion.id == 'missing') {
          // New to remote (Create)
          debugPrint('📤 Creating task "${localTask.title}"');
          await _remoteRepo.createTask(localTask);
          created++;
        } else {
          // Exists remotely, check timestamp
          final remoteTime = remoteVersion.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);
          final localTime = localTask.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);
          
          debugPrint('🔍 Task "${localTask.title}": Local=${localTime.toIso8601String()}, Remote=${remoteTime.toIso8601String()}');
          
          if (localTime.isAfter(remoteTime)) {
             debugPrint('📤 Updating task "${localTask.title}" (newer locally)');
             await _remoteRepo.updateTask(localTask);
             updated++;
          } else if (localTime == remoteTime) {
             debugPrint('⏸️  Skipping task "${localTask.title}" (same timestamp)');
          } else {
             debugPrint('⏸️  Skipping task "${localTask.title}" (remote is newer)');
          }
        }
      }
      
      debugPrint('Sync: Pushed - Created: $created, Updated: $updated');

      // ----------------------------------------------------------------------
      // PHASE 4: Merge & Save
      // ----------------------------------------------------------------------
      // Fetch fresh remote state to include our pushes + any other device changes
      final freshRemoteTasks = await _remoteRepo.getTasks();
      
      final mergedTasks = TaskSyncService().mergeTasksWithDeduplication(localTasks, freshRemoteTasks);
      
      // Update lastSynced for all tasks (since we just synced)
      final now = DateTime.now().toUtc();
      final finalTasks = mergedTasks.map((t) => t.copyWith(
        lastSynced: now, // Mark as known-synced
        needsSync: false
      )).toList();
      
      await TaskStorage.saveTasks(finalTasks);
      debugPrint('Sync: Completed. Final task count: ${finalTasks.length}');
      
      // ----------------------------------------------------------------------

      // 5. Sync Analytics (Two-Way) - Keeping existing logic
      await _syncAnalytics();
      
      // Reset retry count on successful sync
      _retryCount = 0;
      debugPrint('Sync completed successfully');
      
    } catch (e) {
      debugPrint('Sync Error: $e');
      
      if (_retryCount < _maxRetries) {
        _retryCount++;
        final retryDelay = Duration(seconds: 2 * _retryCount);
        debugPrint('Retrying sync in ${retryDelay.inSeconds}s (attempt $_retryCount/$_maxRetries)');
        Timer(retryDelay, () => syncNow());
      } else {
        debugPrint('Max retries reached. Sync failed permanently.');
        _retryCount = 0;
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncAnalytics() async {
    try {
      debugPrint('Syncing Analytics...');
      final allStats = await StatsStorage.getAllStats();
      final analyticsRepo = SupabaseAnalyticsRepository();
      
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentStats = allStats.where((s) => s.date.isAfter(thirtyDaysAgo)).toList();

      // Upload Local
      for (final stat in recentStats) {
        await analyticsRepo.syncDailyStats(stat);
      }

      // Download & Merge Remote
      for (int i = 0; i < 7; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        final remoteStat = await analyticsRepo.fetchDailyStats(date);
        await StatsStorage.saveSessionStats(remoteStat);
      }
    } catch (e) {
      debugPrint('Analytics Sync Error: $e');
    }
  }



  // Sync a single task by ID
  Future<void> syncTask(String taskId) async {
    try {
      if (!_authService.isSignedIn) return;

      // 1. Get Local Task
      final localTasks = await TaskStorage.loadTasks();
      final localTaskIndex = localTasks.indexWhere((t) => t.id == taskId);
      if (localTaskIndex == -1) return; // Task not found locally
      final localTask = localTasks[localTaskIndex];

      // 2. Fetch Remote Task
      final remoteTask = await _remoteRepo.getTask(taskId);

      debugPrint('Syncing single task "${localTask.title}"...');

      // 3. Compare and Push/Update
      if (remoteTask == null) {
        // Needs creation on remote
        debugPrint('📤 Single Sync: Creating remote task');
        await _remoteRepo.createTask(localTask);
      } else {
        // Compare timestamps
        final remoteTime = remoteTask.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);
        final localTime = localTask.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);
        
        debugPrint('🔍 Single Sync: Local=${localTime.toIso8601String()}, Remote=${remoteTime.toIso8601String()}');

        if (localTime.isAfter(remoteTime)) {
           debugPrint('📤 Single Sync: Pushing local update');
           await _remoteRepo.updateTask(localTask);
        } else if (remoteTime.isAfter(localTime)) {
           debugPrint('📥 Single Sync: Pulling remote update');
           // Update local storage
           localTasks[localTaskIndex] = remoteTask;
           await TaskStorage.saveTasks(localTasks);
        } else {
           debugPrint('✅ Single Sync: Already in sync');
        }
      }
    } catch (e) {
      debugPrint('Error syncing single task: $e');
    }
  }

  // Get sync info for a task (Source: Cloud/Local)
  Future<Map<String, dynamic>> getTaskSyncInfo(String taskId) async {
    if (!_authService.isSignedIn) {
      return {'status': 'Local Only', 'details': 'Not signed in', 'icon': Icons.cloud_off};
    }

    try {
      final remoteTask = await _remoteRepo.getTask(taskId);
      if (remoteTask != null) {
        final lastMod = remoteTask.lastModified != null 
            ? DateFormat('MMM d, h:mm a').format(remoteTask.lastModified!.toLocal())
            : 'Unknown';
        return {
          'status': 'Synced',
          'details': 'Available on Cloud\nLast Cloud Update: $lastMod',
          'icon': Icons.cloud_done,
          'isSynced': true
        };
      } else {
         return {
          'status': 'Local Only',
          'details': 'Not yet synced to cloud',
          'icon': Icons.cloud_upload_outlined,
          'isSynced': false
        };
      }
    } catch (e) {
      return {'status': 'Error', 'details': 'Could not check status', 'icon': Icons.error_outline};
    }
  }

  void dispose() {
    _authSubscription?.cancel();
    _syncDebounceTimer?.cancel();
  }
}
