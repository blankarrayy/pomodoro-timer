import '../services/unique_id_service.dart';

class Task {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final String? notes;
  final DateTime? lastSynced;
  final DateTime? lastModified;
  final bool isDeleted;
  final bool needsSync;

  Task({
    String? id,
    required this.title,
    this.isCompleted = false,
    DateTime? createdAt,
    this.dueDate,
    this.completedAt,
    this.notes,
    this.lastSynced,
    this.lastModified,
    this.isDeleted = false,
    this.needsSync = true,
  }) : 
    this.id = id ?? UniqueIdService.generateTaskId(),
    this.createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? dueDate,
    DateTime? completedAt,
    String? notes,
    DateTime? lastSynced,
    DateTime? lastModified,
    bool? isDeleted,
    bool? needsSync,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      lastSynced: lastSynced ?? this.lastSynced,
      lastModified: lastModified ?? this.lastModified,
      isDeleted: isDeleted ?? this.isDeleted,
      needsSync: needsSync ?? this.needsSync,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'is_completed': isCompleted,
    'created_at': createdAt.toIso8601String(),
    'due_date': dueDate?.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'notes': notes,
    'last_synced': lastSynced?.toIso8601String(),
    'last_modified': lastModified?.toIso8601String(),
    'is_deleted': isDeleted,
    'needs_sync': needsSync,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    // Support both snake_case (remote) and camelCase (legacy local) if needed, 
    // or just migrate. For now, let's prefer snake_case but fallback could be wise if local storage is mixed.
    // However, clean migration is safer. Let's stick to snake_case for the future.
    // WAIT: Local storage JSON might still be camelCase! 
    // If I change this, I break local storage loading for existing tasks!
    // I must handle both or migrate local storage.
    // Strategy: Update toJson to snake_case (for new saves/sync). 
    // Update fromJson to check BOTH.
    isCompleted: json['is_completed'] ?? json['isCompleted'] ?? false,
    createdAt: DateTime.parse(json['created_at'] ?? json['createdAt']),
    dueDate: (json['due_date'] ?? json['dueDate']) != null 
        ? DateTime.parse(json['due_date'] ?? json['dueDate']) 
        : null,
    completedAt: (json['completed_at'] ?? json['completedAt']) != null 
        ? DateTime.parse(json['completed_at'] ?? json['completedAt']) 
        : null,
    notes: json['notes'],
    lastSynced: (json['last_synced'] ?? json['lastSynced']) != null 
        ? DateTime.parse(json['last_synced'] ?? json['lastSynced']) 
        : null,
    lastModified: (json['last_modified'] ?? json['lastModified']) != null 
        ? DateTime.parse(json['last_modified'] ?? json['lastModified']) 
        : null,
    isDeleted: json['is_deleted'] ?? json['isDeleted'] ?? false,
    needsSync: json['needs_sync'] ?? json['needsSync'] ?? true,
  );

  /// Generate a content hash for this task (for deduplication)
  String get contentHash => UniqueIdService.generateContentHash(title, notes, dueDate, isCompleted);

  /// Check if this task has the same content as another task
  bool hasSameContentAs(Task other) {
    return UniqueIdService.hasSameContent(
      title, notes, dueDate, isCompleted,
      other.title, other.notes, other.dueDate, other.isCompleted,
    );
  }

  /// Check if this task is a duplicate of another task
  bool isDuplicateOf(Task other) {
    return id != other.id && hasSameContentAs(other);
  }
}