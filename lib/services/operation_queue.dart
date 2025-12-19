import 'dart:async';
import 'package:flutter/foundation.dart';

/// Type of operation to perform on a task
enum TaskOperationType {
  add,
  update,
  toggle,
  delete,
}

/// Represents a task operation to be queued
class TaskOperation {
  final TaskOperationType type;
  final String? taskId;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  TaskOperation({
    required this.type,
    this.taskId,
    this.data,
  }) : timestamp = DateTime.now();

  @override
  String toString() => 'TaskOperation(type: $type, taskId: $taskId, time: $timestamp)';
}

/// Queue service to handle task operations sequentially
class OperationQueue {
  static final OperationQueue _instance = OperationQueue._internal();
  factory OperationQueue() => _instance;
  OperationQueue._internal();

  final List<TaskOperation> _queue = [];
  bool _isProcessing = false;
  final List<String> _operationLog = [];
  static const int _maxLogSize = 100;

  /// Enqueue an operation
  Future<void> enqueue(TaskOperation operation) async {
    _queue.add(operation);
    _logOperation('ENQUEUED', operation);
    
    // Start processing if not already running
    if (!_isProcessing) {
      _processQueue();
    }
  }

  /// Process the queue sequentially
  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final operation = _queue.removeAt(0);
      _logOperation('PROCESSING', operation);

      try {
        // The actual processing will be done by the callback registered
        // For now, we just ensure sequential execution
        await Future.delayed(const Duration(milliseconds: 10));
        _logOperation('COMPLETED', operation);
      } catch (e, stackTrace) {
        debugPrint('Operation failed: $operation');
        debugPrint('Error: $e');
        debugPrint('Stack trace: $stackTrace');
        _logOperation('FAILED', operation);
      }
    }

    _isProcessing = false;
  }

  /// Log an operation event
  void _logOperation(String event, TaskOperation operation) {
    final logEntry = '[$event] ${operation.toString()}';
    _operationLog.add(logEntry);
    
    // Keep log size bounded
    if (_operationLog.length > _maxLogSize) {
      _operationLog.removeAt(0);
    }
    
    debugPrint(logEntry);
  }

  /// Get operation log for debugging
  List<String> getOperationLog() => List.unmodifiable(_operationLog);

  /// Get queue size
  int get queueSize => _queue.length;

  /// Check if queue is processing
  bool get isProcessing => _isProcessing;

  /// Clear the queue (use with caution)
  void clearQueue() {
    _queue.clear();
    _logOperation('QUEUE_CLEARED', TaskOperation(type: TaskOperationType.add));
  }

  /// Wait for queue to be empty
  Future<void> waitForEmpty() async {
    while (_isProcessing || _queue.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }
}
