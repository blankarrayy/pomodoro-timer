import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import 'task_storage.dart';
import 'stats_storage.dart';
import 'supabase_task_repository.dart';
import 'supabase_analytics_repository.dart';

class SyncOrchestrator {
  static final SyncOrchestrator _instance = SyncOrchestrator._internal();
  factory SyncOrchestrator() => _instance;
  SyncOrchestrator._internal();

  final SupabaseTaskRepository _remoteRepo = SupabaseTaskRepository();
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

  Future<void> syncNow() async {
    if (_isSyncing) return;
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return; // Not signed in, local only mode

    // Check connectivity (simple check)
    // Note: Use a package or Supabase's realtime status in production
    // For now assume we might have connection
    
    _isSyncing = true;
    try {
      debugPrint('Starting Sync...');
      
      // 1. Upload Local Tasks (One-way migration/sync for now)
      final localTasks = await TaskStorage.loadTasks();
      
      for (final task in localTasks) {
        // Generate Hash
        final hash = '${task.title}_${task.dueDate?.toIso8601String() ?? 'nodate'}';
        
        // Check if exists remotely
        final existing = await _remoteRepo.findTaskByHash(hash);
        
        // Check if deleted
        if (task.isDeleted) {
           // Update remote to be deleted too (Soft Delete)
           if (existing != null) {
              debugPrint('Syncing deletion for: ${task.title}');
              // We just update the task, as isDeleted is part of the model now
              await _remoteRepo.updateTask(task);
           }
           continue; 
        }

        if (existing == null) {
          // Does not exist, create it
          debugPrint('Uploading task: ${task.title}');
          await _remoteRepo.createTask(task);
        } else {
          debugPrint('Task exists, updating: ${task.title}');
          // Update remote with local state (since we are syncing local -> remote)
          // Ideally we check timestamps, but for "Upload Local" mode, we overwrite.
          await _remoteRepo.updateTask(task);
        }
      }
      
      // 2. Sync Analytics (Two-Way)
      debugPrint('Syncing Analytics...');
      final allStats = await StatsStorage.getAllStats();
      final analyticsRepo = SupabaseAnalyticsRepository();
      
      // Sync last 30 days only to be efficient
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentStats = allStats.where((s) => s.date.isAfter(thirtyDaysAgo)).toList();

      // A. Upload Local
      for (final stat in recentStats) {
        await analyticsRepo.syncDailyStats(stat);
      }

      // B. Download & Merge Remote
      // We check the last 7 days specifically to update the chart immediately
      for (int i = 0; i < 7; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        final remoteStat = await analyticsRepo.fetchDailyStats(date);
        
        // Save the authoritative remote state to local
        await StatsStorage.saveSessionStats(remoteStat);
      }

      // 3. Download & Merge updates from Server
      final remoteTasks = await _remoteRepo.getTasks();
      debugPrint('Fetched ${remoteTasks.length} tasks from server.');
      
      await _mergeRemoteTasks(remoteTasks);
      
      // Reset retry count on successful sync
      _retryCount = 0;
      debugPrint('Sync completed successfully');
      
    } catch (e) {
      debugPrint('Sync Error: $e');
      
      // Retry logic with exponential backoff
      if (_retryCount < _maxRetries) {
        _retryCount++;
        final retryDelay = Duration(seconds: 2 * _retryCount); // 2s, 4s, 8s
        debugPrint('Retrying sync in ${retryDelay.inSeconds}s (attempt $_retryCount/$_maxRetries)');
        
        Timer(retryDelay, () => syncNow());
      } else {
        debugPrint('Max retries reached. Sync failed permanently.');
        _retryCount = 0; // Reset for next sync attempt
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _mergeRemoteTasks(List<Task> remoteTasks) async {
    final localTasks = await TaskStorage.loadTasks();
    final localTaskMap = {for (var t in localTasks) t.id: t};
    bool hasChanges = false;

    for (final remoteTask in remoteTasks) {
      final localTask = localTaskMap[remoteTask.id];

      if (localTask == null) {
        // New task from server
        // Ensure we don't re-add a task we definitely deleted locally if we were tracking deletions separately.
        // But since we use soft-deletes (isDeleted), if the remote task is isDeleted=false and we don't have it,
        // it likely means it's a new task or we hard-deleted it.
        // Given the current simple architecture, we'll accept it.
        localTasks.add(remoteTask);
        hasChanges = true;
      } else {
        // Conflict resolution: Last Write Wins
        // If remote is newer than local, update local
        final remoteTime = remoteTask.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);
        final localTime = localTask.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);

        if (remoteTime.isAfter(localTime)) {
          debugPrint('Updating local task ${remoteTask.title} from remote');
          localTasks[localTasks.indexOf(localTask)] = remoteTask;
          hasChanges = true;
        }
      }
    }

    if (hasChanges) {
      await TaskStorage.saveTasks(localTasks);
    }
  
    }


  void dispose() {
    _authSubscription?.cancel();
    _syncDebounceTimer?.cancel();
  }
}
