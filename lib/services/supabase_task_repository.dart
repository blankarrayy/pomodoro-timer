import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';

class SupabaseTaskRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Task>> getTasks() async {
    final response = await _client
        .from('tasks')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((json) => Task.fromJson(json)).toList();
  }

  Future<Task> createTask(Task task) async {
    // Generate content hash for deduplication
    final contentHash = _generateContentHash(task);
    
    final taskData = task.toJson();
    taskData['user_id'] = _client.auth.currentUser!.id;
    taskData['content_hash'] = contentHash;
    
    // Remove local-only fields
    taskData.remove('needs_sync');
    taskData.remove('last_synced');
    taskData.remove('google_task_id'); // Ensure legacy field is gone
    
    final response = await _client
        .from('tasks')
        .upsert(taskData)
        .select()
        .single();
        
    return Task.fromJson(response);
  }

  Future<Task> updateTask(Task task) async {
     final taskData = task.toJson();
     
     // Remove local-only fields
     taskData.remove('needs_sync');
     taskData.remove('last_synced');
     taskData.remove('google_task_id');
     taskData.remove('user_id'); // Usually we don't update user_id, good safety practice

     final response = await _client
        .from('tasks')
        .update(taskData)
        .eq('id', task.id)
        .select()
        .single();
        
    return Task.fromJson(response);
  }

  Future<void> deleteTask(String taskId) async {
    await _client.from('tasks').delete().eq('id', taskId);
  }
  
  // Helper to find a task by content hash
  Future<Task?> findTaskByHash(String hash) async {
    final response = await _client
      .from('tasks')
      .select()
      .eq('content_hash', hash)
      .maybeSingle();
      
    return response != null ? Task.fromJson(response) : null;
  }
  
  String _generateContentHash(Task task) {
    // Basic hash from title + due date (if any)
    // This logic should match what we use locally
    return '${task.title}_${task.dueDate?.toIso8601String() ?? 'nodate'}';
  }
}
