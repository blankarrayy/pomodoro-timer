import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../ui/app_theme.dart';

class TaskItem extends ConsumerStatefulWidget {
  final Task task;
  final VoidCallback onEdit;

  const TaskItem({
    super.key,
    required this.task,
    required this.onEdit,
  });

  @override
  ConsumerState<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends ConsumerState<TaskItem> {
  bool _isCompleting = false;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleCompletion() async {
    // If it's already completed and we are unchecking, just do it instantly
    if (widget.task.isCompleted) {
      await ref.read(taskProvider.notifier).toggleTaskCompletion(widget.task.id);
      return;
    }

    // Start completion sequence (Checkmark visual)
    setState(() {
      _isCompleting = true;
    });
    
    // Short pause to see the checkmark (250ms)
    await Future.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;

    // Start fade out
    setState(() {
      _isVisible = false;
    });

    // Wait for fade animation (0.5s)
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Actually update state
    await ref.read(taskProvider.notifier).toggleTaskCompletion(widget.task.id);
  }

  @override
  Widget build(BuildContext context) {
    
    final isOverdue = widget.task.dueDate != null &&
        widget.task.dueDate!.isBefore(DateTime.now()) &&
        !widget.task.isCompleted;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _isVisible ? 1.0 : 0.0,
      curve: Curves.easeOut,
      child: Dismissible(
        key: Key(widget.task.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
        ),
        onDismissed: (_) => ref.read(taskProvider.notifier).removeTask(widget.task.id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOverdue
                  ? Colors.red.withOpacity(0.3)
                  : Colors.white.withOpacity(0.05),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onEdit,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Checkbox Area
                    GestureDetector(
                      onTap: _isCompleting ? null : _handleCompletion,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: widget.task.isCompleted || _isCompleting
                                ? AppTheme.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: widget.task.isCompleted || _isCompleting
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary.withOpacity(0.5),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: widget.task.isCompleted || _isCompleting
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Content Area
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.task.title,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
                              color: widget.task.isCompleted
                                  ? AppTheme.textSecondary.withOpacity(0.5)
                                  : AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (widget.task.notes != null && widget.task.notes!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.task.notes!,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (widget.task.dueDate != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 10,
                                  color: isOverdue
                                      ? Colors.red
                                      : AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('MMM d').format(widget.task.dueDate!),
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color: isOverdue
                                        ? Colors.red
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
