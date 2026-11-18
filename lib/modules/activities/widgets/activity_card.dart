import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/activity_occurrence_model.dart';

/// Interactive card for displaying daily activity occurrence status with Complete, Skip, and Pending actions.
class ActivityCard extends StatelessWidget {
  final ActivityOccurrenceModel occurrence;
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final VoidCallback onPending;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ActivityCard({
    super.key,
    required this.occurrence,
    required this.onComplete,
    required this.onSkip,
    required this.onPending,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = occurrence.isCompletedStatus;
    final isSkipped = occurrence.isSkipped;
    final isOverdue = occurrence.isMissedOrOverdue;

    Color cardBg = theme.colorScheme.surface;
    if (isDone) {
      cardBg = theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.35,
      );
    } else if (isSkipped) {
      cardBg = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2);
    }

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      color: cardBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getCategoryColor(
                    occurrence.category,
                  ).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(occurrence.category),
                  color: _getCategoryColor(occurrence.category),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Title, Category and Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      occurrence.activityTitle ??
                          'Activity #${occurrence.activityId}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: isDone
                            ? TextDecoration.lineThrough
                            : (isSkipped ? TextDecoration.lineThrough : null),
                        color: isDone || isSkipped
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (occurrence.activityDescription != null &&
                        occurrence.activityDescription!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        occurrence.activityDescription!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),

                    // Badges row: Category, Time, Reminder, Status
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Category Chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            occurrence.category ?? 'Personal',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),

                        // Scheduled Time (if set)
                        if (occurrence.scheduledTime != null &&
                            occurrence.scheduledTime!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 12,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  occurrence.scheduledTime!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Reminder Icon
                        if (occurrence.isReminderEnabled == true)
                          Icon(
                            Icons.notifications_active_rounded,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),

                        // Status Badge
                        if (isDone)
                          const StatusBadge(status: BadgeStatus.completed)
                        else if (isSkipped)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Skipped',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple,
                              ),
                            ),
                          )
                        else if (isOverdue)
                          const StatusBadge(
                            status: BadgeStatus.overdue,
                            customLabel: 'Missed',
                          )
                        else
                          const StatusBadge(status: BadgeStatus.pending),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Popup Menu
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  padding: EdgeInsets.zero,
                  onSelected: (val) {
                    if (val == 'edit' && onEdit != null) onEdit!();
                    if (val == 'delete' && onDelete != null) onDelete!();
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit Activity'),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Interactive Status Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isDone || isSkipped) ...[
                TextButton.icon(
                  onPressed: onPending,
                  icon: const Icon(Icons.undo_rounded, size: 16),
                  label: const Text('Reset to Pending'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: onSkip,
                  icon: const Icon(Icons.fast_forward_rounded, size: 16),
                  label: const Text('Skip'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple,
                    side: BorderSide(
                      color: Colors.purple.withValues(alpha: 0.5),
                    ),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Complete'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.completed,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'food':
      case 'breakfast':
      case 'lunch':
      case 'dinner':
        return Icons.restaurant_rounded;
      case 'health':
      case 'medication':
        return Icons.medication_rounded;
      case 'fitness':
      case 'exercise':
        return Icons.fitness_center_rounded;
      case 'meetings':
      case 'work':
        return Icons.meeting_room_rounded;
      case 'reading':
        return Icons.menu_book_rounded;
      case 'mindfulness':
        return Icons.self_improvement_rounded;
      case 'hydration':
        return Icons.water_drop_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'food':
      case 'breakfast':
      case 'lunch':
      case 'dinner':
        return Colors.orange;
      case 'health':
      case 'medication':
        return Colors.red;
      case 'fitness':
      case 'exercise':
        return Colors.green;
      case 'meetings':
      case 'work':
        return Colors.blue;
      case 'reading':
        return Colors.indigo;
      case 'mindfulness':
        return Colors.teal;
      case 'hydration':
        return Colors.cyan;
      default:
        return AppColors.primaryLight;
    }
  }
}
