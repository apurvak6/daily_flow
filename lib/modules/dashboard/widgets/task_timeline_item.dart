import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/task_occurrence_model.dart';

/// Chronological timeline row presenting a task in the daily schedule.
class TaskTimelineItem extends StatelessWidget {
  final TaskOccurrenceModel occurrence;
  final bool isFirst;
  final bool isLast;
  final ValueChanged<bool?> onToggle;
  final VoidCallback? onTap;

  const TaskTimelineItem({
    super.key,
    required this.occurrence,
    this.isFirst = false,
    this.isLast = false,
    required this.onToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = occurrence.isCompleted;
    final timeStr = occurrence.dueTime ?? 'All day';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Time Column
          SizedBox(
            width: 68,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                timeStr,
                textAlign: TextAlign.end,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDone
                      ? theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        )
                      : theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 2. Timeline Line & Node
          Column(
            children: [
              Container(
                width: 2,
                height: 16,
                color: isFirst
                    ? Colors.transparent
                    : theme.colorScheme.outline.withValues(alpha: 0.4),
              ),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? AppColors.completed
                      : theme.colorScheme.surface,
                  border: Border.all(
                    color: isDone
                        ? AppColors.completed
                        : theme.colorScheme.primary,
                    width: 2.5,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 8, color: Colors.white)
                    : null,
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast
                      ? Colors.transparent
                      : theme.colorScheme.outline.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // 3. Task Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CustomCard(
                onTap: onTap,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                borderRadius: 14,
                color: isDone
                    ? theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      )
                    : theme.colorScheme.surface,
                child: Row(
                  children: [
                    // Checkbox
                    SizedBox(
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
                    const SizedBox(width: 12),

                    // Title & Badges
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            occurrence.taskTitle ??
                                'Task #${occurrence.taskId}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isDone
                                  ? theme.colorScheme.onSurfaceVariant
                                  : theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (occurrence.category != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    occurrence.category!,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              StatusBadge(
                                status: _resolvePriority(occurrence.priority),
                              ),
                              if (occurrence.isRecurring == true)
                                Icon(
                                  Icons.repeat,
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
}
