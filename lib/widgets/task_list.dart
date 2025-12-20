import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../ui/app_theme.dart';
import 'task_item.dart';

class TaskList extends ConsumerStatefulWidget {
  const TaskList({super.key});

  @override
  ConsumerState<TaskList> createState() => _TaskListState();
}

class _TaskListState extends ConsumerState<TaskList> {
  int _selectedTabIndex = 0; // 0 for Todo, 1 for Completed

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final isSignedIn = ref.watch(isSignedInProvider);
    final isSyncing = ref.watch(isSyncingProvider);

    // Filter tasks
    final todoTasks = tasks.where((t) => !t.isCompleted).toList();
    final completedTasks = tasks.where((t) => t.isCompleted).toList();
    
    final currentTasks = _selectedTabIndex == 0 ? todoTasks : completedTasks;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Sensitivity check
        if (details.primaryVelocity!.abs() < 300) return;

        if (details.primaryVelocity! < 0) {
          // Swipe Left -> Next Tab (To Do -> Completed)
          if (_selectedTabIndex == 0) {
            setState(() => _selectedTabIndex = 1);
          }
        } else if (details.primaryVelocity! > 0) {
          // Swipe Right -> Previous Tab (Completed -> To Do)
          if (_selectedTabIndex == 1) {
            setState(() => _selectedTabIndex = 0);
          }
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, ref, isSignedIn, isSyncing),
          const SizedBox(height: 16),
          _buildTabBar(),
          const SizedBox(height: 16),
          currentTasks.isEmpty
              ? _buildEmptyState(context, isCompletedTab: _selectedTabIndex == 1)
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: currentTasks.length,
                  itemBuilder: (context, index) {
                    return TaskItem(
                      key: Key(currentTasks[index].id),
                      task: currentTasks[index],
                      onEdit: () => _showEditTaskSheet(context, ref, currentTasks[index]),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 45, // Increased height by 25% (was 36)
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          _buildTabItem('To Do', 0),
          _buildTabItem('Completed', 1),
        ],
      ),
    );
  }
  
  Widget _buildTabItem(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : null,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildHeader(BuildContext context, WidgetRef ref, bool isSignedIn, bool isSyncing) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Tasks',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        if (isSignedIn)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isSyncing
                  ? AppTheme.primary.withOpacity(0.2)
                  : AppTheme.surfaceLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSyncing ? Icons.sync : Icons.cloud_done_rounded,
                  size: 12,
                  color: isSyncing
                      ? AppTheme.primary
                      : AppTheme.textSecondary,
                ),
                if (isSyncing) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 8,
                    height: 8,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        if (isSignedIn) const SizedBox(width: 8),
        if (isSignedIn)
          IconButton(
            onPressed: isSyncing ? null : () => ref.read(taskProvider.notifier).syncTasks(),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.surfaceLight.withOpacity(0.3),
              padding: const EdgeInsets.all(8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Icon(
              Icons.refresh_rounded,
              size: 18,
              color: isSyncing ? AppTheme.textSecondary.withOpacity(0.5) : AppTheme.textSecondary,
            ),
            tooltip: 'Resync Tasks',
          ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _showAddTaskSheet(context, ref),
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.primary.withOpacity(0.2),
            padding: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(
            Icons.add_rounded,
            size: 18,
            color: AppTheme.primary,
          ),
          tooltip: 'Add Task',
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isCompletedTab}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCompletedTab ? Icons.check_circle_outline : Icons.assignment_outlined,
              size: 40,
              color: AppTheme.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              isCompletedTab ? 'No completed tasks' : 'No tasks yet',
              style: GoogleFonts.outfit(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isCompletedTab ? 'Finish some tasks!' : 'Tap + to create one',
              style: GoogleFonts.outfit(
                color: AppTheme.textSecondary.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TaskFormSheet(ref: ref),
    );
  }

  void _showEditTaskSheet(BuildContext context, WidgetRef ref, Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TaskFormSheet(ref: ref, task: task),
    );
  }
}

class _TaskFormSheet extends StatefulWidget {
  final WidgetRef ref;
  final Task? task;

  const _TaskFormSheet({required this.ref, this.task});

  @override
  State<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<_TaskFormSheet> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title);
    _notesController = TextEditingController(text: widget.task?.notes);
    _selectedDate = widget.task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.task == null ? 'New Task' : 'Edit Task',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
              ),
            ],
          ),
          if (widget.task != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  widget.ref.read(taskProvider.notifier).removeTask(widget.task!.id);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                label: const Text(
                  'Delete Task',
                  style: TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.redAccent.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            autofocus: true,
            style: GoogleFonts.outfit(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Title',
              hintText: 'Enter task title',
              filled: true,
              fillColor: AppTheme.surfaceLight.withOpacity(0.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 3,
            style: GoogleFonts.outfit(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'Add details...',
              filled: true,
              fillColor: AppTheme.surfaceLight.withOpacity(0.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: AppTheme.darkTheme,
                    child: child!,
                  );
                },
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.surfaceLight,
                ),
                borderRadius: BorderRadius.circular(16),
                color: AppTheme.surfaceLight.withOpacity(0.5),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate == null
                        ? 'Add deadline (optional)'
                        : DateFormat('MMM d, yyyy').format(_selectedDate!),
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: _selectedDate == null
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary,
                    ),
                  ),
                  if (_selectedDate != null) ...[
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() => _selectedDate = null),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_titleController.text.trim().isEmpty) return;
                
                if (widget.task == null) {
                  widget.ref.read(taskProvider.notifier).addTask(
                        _titleController.text.trim(),
                        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                        dueDate: _selectedDate,
                      );
                } else {
                  widget.ref.read(taskProvider.notifier).editTask(
                        widget.task!.id,
                        title: _titleController.text.trim(),
                        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                        dueDate: _selectedDate,
                      );
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(widget.task == null ? 'Create Task' : 'Save Changes', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

