import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/task_occurrence_model.dart';

/// Reusable task list card displaying task metadata, priority, category, and action menu.
class TaskCard extends StatelessWidget {
  final TaskOccurrenceModel occurrence;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.occurrence,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = occurrence.isCompleted;
    final isOverdue =
        !isDone && AppDateUtils.isOverdue(occurrence.occurrenceDate);

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      color: isDone
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
          : theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: isDone,
                    onChanged: onToggle,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    activeColor: AppColors.completed,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      occurrence.taskTitle ?? 'Untitled Task',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (occurrence.taskDescription != null &&
                        occurrence.taskDescription!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        occurrence.taskDescription!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Action Popup Menu
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (action) {
                  if (action == 'edit') {
                    onEdit();
                  } else if (action == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppColors.overdue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Delete',
                          style: TextStyle(color: AppColors.overdue),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Metadata Badges Row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Category Chip
              if (occurrence.category != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _resolveCategoryColor(
                      occurrence.category!,
                    ).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _resolveCategoryIcon(occurrence.category!),
                        size: 13,
                        color: _resolveCategoryColor(occurrence.category!),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        occurrence.category!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _resolveCategoryColor(occurrence.category!),
                        ),
                      ),
                    ],
                  ),
                ),

              // Priority Badge
              StatusBadge(status: _resolvePriority(occurrence.priority)),

              // Status (Completed / Overdue / Pending)
              if (isDone)
                const StatusBadge(status: BadgeStatus.completed)
              else if (isOverdue)
                const StatusBadge(status: BadgeStatus.overdue)
              else
                const StatusBadge(status: BadgeStatus.pending),

              // Recurrence Chip
              if (occurrence.isRecurring == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.repeat_rounded,
                        size: 13,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Recurring',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              // Due Time
              if (occurrence.dueTime != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      occurrence.dueTime!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  BadgeStatus _resolvePriority(String? priority) {
    switch (priority) {
      case AppConstants.priorityLow:
        return BadgeStatus.priorityLow;
      case AppConstants.priorityHigh:
        return BadgeStatus.priorityHigh;
      default:
        return BadgeStatus.priorityMedium;
    }
  }

  Color _resolveCategoryColor(String category) {
    switch (category) {
      case 'Work':
        return const Color(0xFF3B82F6); // Blue
      case 'Personal':
        return const Color(0xFF8B5CF6); // Purple
      case 'Health':
        return const Color(0xFF10B981); // Emerald
      case 'Food':
        return const Color(0xFFF97316); // Orange
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  IconData _resolveCategoryIcon(String category) {
    switch (category) {
      case 'Work':
        return Icons.business_center_outlined;
      case 'Personal':
        return Icons.person_outline;
      case 'Health':
        return Icons.favorite_border;
      case 'Food':
        return Icons.restaurant_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}
