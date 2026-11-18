import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import 'dashboard_metric_tile.dart';

/// Card displaying the daily task completion progress and breakdown metrics.
class DailyProgressCard extends StatelessWidget {
  final int totalCount;
  final int completedCount;
  final int pendingCount;
  final int overdueCount;
  final double percentage;
  final VoidCallback? onPendingTap;
  final VoidCallback? onCompletedTap;
  final VoidCallback? onOverdueTap;

  const DailyProgressCard({
    super.key,
    required this.totalCount,
    required this.completedCount,
    required this.pendingCount,
    required this.overdueCount,
    required this.percentage,
    this.onPendingTap,
    this.onCompletedTap,
    this.onOverdueTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clampedPercent = (percentage / 100).clamp(0.0, 1.0);

    return CustomCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Completion',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getProgressMotivation(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: clampedPercent == 1.0 && totalCount > 0
                      ? AppColors.completedContainerLight
                      : theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: clampedPercent == 1.0 && totalCount > 0
                        ? AppColors.completed
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: clampedPercent,
              minHeight: 10,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                clampedPercent == 1.0 && totalCount > 0
                    ? AppColors.completed
                    : theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              DashboardMetricTile(
                label: 'Today',
                count: totalCount,
                icon: Icons.checklist_rounded,
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
              ),
              const SizedBox(width: 8),
              DashboardMetricTile(
                label: 'Pending',
                count: pendingCount,
                icon: Icons.schedule_rounded,
                color: AppColors.pending,
                backgroundColor: AppColors.pendingContainerLight.withValues(
                  alpha: 0.4,
                ),
                onTap: onPendingTap,
              ),
              const SizedBox(width: 8),
              DashboardMetricTile(
                label: 'Done',
                count: completedCount,
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.completed,
                backgroundColor: AppColors.completedContainerLight.withValues(
                  alpha: 0.4,
                ),
                onTap: onCompletedTap,
              ),
              const SizedBox(width: 8),
              DashboardMetricTile(
                label: 'Overdue',
                count: overdueCount,
                icon: Icons.warning_amber_rounded,
                color: AppColors.overdue,
                backgroundColor: AppColors.overdueContainerLight.withValues(
                  alpha: 0.4,
                ),
                onTap: onOverdueTap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getProgressMotivation() {
    if (totalCount == 0) return 'No tasks scheduled yet today';
    if (percentage == 100.0) return '🎉 Fantastic! All tasks completed today!';
    if (percentage >= 75.0) return 'Almost there! Keep the streak going!';
    if (percentage >= 50.0) return 'Halfway through! Stay focused!';
    return '$completedCount of $totalCount tasks completed';
  }
}
