import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/task_state.dart';
import '../services/task_storage.dart';
import '../services/supabase_auth_service.dart';
import '../services/sync_orchestrator.dart';
import '../services/task_sync_service.dart';
import 'stats_provider.dart';

class TaskNotifier extends Notifier<TaskState> {
  final SupabaseAuthService _authService = SupabaseAuthService();
  final SyncOrchestrator _syncOrchestrator = SyncOrchestrator();
  final TaskSyncService _syncService = TaskSyncService();
  
  StreamSubscription? _authStateSubscription;

  @override
  TaskState build() {
    // Initialize services and subscription on dispose
    ref.onDispose(() {
      _authStateSubscription?.cancel();
    });

    // Schedule async initialization
    Future.microtask(() => _initializeServices());
    _loadTasks();

    return const TaskState(
      tasks: [],
      isSignedIn: false,
      isSyncing: false,
      syncStatus: 'Not synced',
    );
  }
  
  bool get isSyncing => state.isSyncing;
  String get syncStatus => state.syncStatus;
  bool get isSignedIn => state.isSignedIn;
  String? get userEmail => state.userEmail;
  
  Future<void> _initializeServices() async {
    _authStateSubscription = _authService.authStateChanges.listen((data) async {
      final user = data.session?.user;
      final isSignedIn = user != null;
      
      state = state.copyWith(
        isSignedIn: isSignedIn,
        userEmail: user?.email,
        syncStatus: isSignedIn ? 'Ready to sync' : 'Not signed in',
      );

      if (isSignedIn) {
         await syncTasks();
      }
    });

    final currentUser = _authService.currentUser;
    state = state.copyWith(
      isSignedIn: currentUser != null,
      userEmail: currentUser?.email,
      syncStatus: currentUser != null ? 'Ready to sync' : 'Not signed in',
    );
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await TaskStorage.loadTasks();
      state = state.copyWith(tasks: tasks);
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }
  }

  Future<void> syncTasks() async {
    if (state.isSyncing || !state.isSignedIn) return;

    try {
      state = state.copyWith(isSyncing: true, syncStatus: 'Syncing...');
      
      await _syncOrchestrator.syncNow();
      
      // Reload tasks from storage to reflect any changes from the server
      await _loadTasks();

      // Invalidate stats providers to force a refresh of the analytics UI
      // We use the container's ref to invalidate other providers
      ref.invalidate(recentStatsProvider);
      ref.invalidate(todayStatsProvider);
      ref.invalidate(statsProvider);
      
      state = state.copyWith(
        isSyncing: false,
        syncStatus: 'Synced at ${DateTime.now().toString().substring(11, 16)}',
      );
    } catch (e) {
      debugPrint('Error syncing: $e');
      state = state.copyWith(
        isSyncing: false,
        syncStatus: 'Sync failed',
      );
    }
  }

  Future<void> addTask(String title, {String? notes, DateTime? dueDate}) async {
    try {
      final newTask = Task(
        title: title,
        notes: notes,
        dueDate: dueDate,
        needsSync: true,
      );
      
      if (_syncService.wouldBeDuplicate(newTask, state.tasks)) {
         debugPrint('Duplicate task detected: $title');
         return;
      }

      final newTasks = [...state.tasks, newTask];
      state = state.copyWith(tasks: newTasks);
      await TaskStorage.saveTasks(newTasks);
      
      if (state.isSignedIn) _syncOrchestrator.scheduleSync();
    } catch (e) {
      debugPrint('Error adding task: $e');
    }
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    final taskIndex = state.tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;

    final task = state.tasks[taskIndex];
    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: !task.isCompleted ? DateTime.now() : null,
      lastModified: DateTime.now(),
      needsSync: true,
    );
    
    _updateTaskLocally(taskIndex, updatedTask);
  }

  Future<void> editTask(String id, {String? title, String? notes, DateTime? dueDate}) async {
    final taskIndex = state.tasks.indexWhere((task) => task.id == id);
    if (taskIndex == -1) return;
    
    final originalTask = state.tasks[taskIndex];
    final updatedTask = originalTask.copyWith(
      title: title ?? originalTask.title,
      notes: notes ?? originalTask.notes,
      dueDate: dueDate ?? originalTask.dueDate,
      lastModified: DateTime.now(),
      needsSync: true,
    );

    _updateTaskLocally(taskIndex, updatedTask);
  }

  Future<void> removeTask(String taskId) async {
    final taskIndex = state.tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;
    
    // 1. Remove locally immediately
    final newTasks = [...state.tasks];
    newTasks.removeAt(taskIndex);
    
    state = state.copyWith(tasks: newTasks);
    await TaskStorage.saveTasks(newTasks);
    
    // 2. Fire and Forget Remote Delete (Instant)
    if (state.isSignedIn) {
      _syncOrchestrator.deleteRemoteTask(taskId);
    }
  }

  Future<void> _updateTaskLocally(int index, Task updatedTask) async {
    final newTasks = [...state.tasks];
    newTasks[index] = updatedTask;
    state = state.copyWith(tasks: newTasks);
    await TaskStorage.saveTasks(newTasks);
    if (state.isSignedIn) _syncOrchestrator.scheduleSync();
  }

  Future<void> forceSyncAll() async {
    await syncTasks();
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
  
  Future<Map<String, int>> getSyncStats() async => await TaskStorage.getSyncStats();
  Future<DateTime?> getLastSyncTime() async => await TaskStorage.getLastSyncTime();
  Future<List<Task>> getTasksNeedingSync() async => await TaskStorage.getTasksNeedingSync();
}

final taskProvider = NotifierProvider<TaskNotifier, TaskState>(() {
  return TaskNotifier();
});

final tasksProvider = Provider<List<Task>>((ref) {
  return ref.watch(taskProvider).tasks.where((t) => !t.isDeleted).toList();
});
final syncStatusProvider = Provider<String>((ref) => ref.watch(taskProvider).syncStatus);
final isSyncingProvider = Provider<bool>((ref) => ref.watch(taskProvider).isSyncing);
final isSignedInProvider = Provider<bool>((ref) => ref.watch(taskProvider).isSignedIn);
final userEmailProvider = Provider<String?>((ref) => ref.watch(taskProvider).userEmail);

final syncStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  return await ref.read(taskProvider.notifier).getSyncStats();
});

final lastSyncTimeProvider = FutureProvider<DateTime?>((ref) async {
  return await ref.read(taskProvider.notifier).getLastSyncTime();
});

final tasksNeedingSyncProvider = FutureProvider<List<Task>>((ref) async {
  return await ref.read(taskProvider.notifier).getTasksNeedingSync();
});
