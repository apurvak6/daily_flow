import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/date_selector.dart';
import '../../../core/widgets/donut_chart.dart';
import '../controllers/reports_controller.dart';

/// Daily reporting view showing task & activity metrics, donut charts, and summary cards.
class DailyReport extends StatelessWidget {
  const DailyReport({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ReportsController>();
    final theme = Theme.of(context);

    return Obx(() {
      final stats = ctrl.dailyStats;
      final taskCompleted = stats['taskCompleted'] ?? 0;
      final taskPending = stats['taskPending'] ?? 0;
      final taskOverdue = stats['taskOverdue'] ?? 0;
      final taskTotal = stats['taskTotal'] ?? 0;
      final taskPct = stats['taskCompletionPct'] ?? 0;

      final actCompleted = stats['activityCompleted'] ?? 0;
      final actPending = stats['activityPending'] ?? 0;
      final actSkipped = stats['activitySkipped'] ?? 0;
      final actTotal = stats['activityTotal'] ?? 0;
      final actPct = stats['activityCompletionPct'] ?? 0;

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selector Navigation
            DateSelector(
              selectedDate: ctrl.selectedDate.value,
              onDateChanged: ctrl.changeDate,
              onPrevious: ctrl.goToPreviousDay,
              onNext: ctrl.goToNextDay,
              onToday: ctrl.goToToday,
            ),
            const SizedBox(height: 16),

            // Daily Task Completion Card & Donut Chart
            _ReportSectionCard(
              title: 'Daily Tasks Performance',
              subtitle: '$taskCompleted of $taskTotal completed ($taskPct%)',
              icon: Icons.check_circle_outline_rounded,
              child: Column(
                children: [
                  DonutChart(
                    height: 170,
                    centerPrimaryText: '$taskPct%',
                    centerSecondaryText: 'Completion',
                    segments: [
                      DonutSegment(
                        label: 'Completed',
                        value: taskCompleted.toDouble(),
                        color: AppColors.completed,
                      ),
                      DonutSegment(
                        label: 'Pending',
                        value: taskPending.toDouble(),
                        color: AppColors.pending,
                      ),
                      DonutSegment(
                        label: 'Overdue',
                        value: taskOverdue.toDouble(),
                        color: AppColors.overdue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: 'Completed',
                          count: taskCompleted,
                          color: AppColors.completed,
                          icon: Icons.check_circle_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricTile(
                          label: 'Pending',
                          count: taskPending,
                          color: AppColors.pending,
                          icon: Icons.hourglass_top_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricTile(
                          label: 'Overdue',
                          count: taskOverdue,
                          color: AppColors.overdue,
                          icon: Icons.error_outline_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Daily Activities Performance Card & Donut Chart
            _ReportSectionCard(
              title: 'Daily Activities Performance',
              subtitle: '$actCompleted of $actTotal completed ($actPct%)',
              icon: Icons.local_fire_department_rounded,
              child: Column(
                children: [
                  DonutChart(
                    height: 170,
                    centerPrimaryText: '$actPct%',
                    centerSecondaryText: 'Completion',
                    segments: [
                      DonutSegment(
                        label: 'Completed',
                        value: actCompleted.toDouble(),
                        color: AppColors.completed,
                      ),
                      DonutSegment(
                        label: 'Pending',
                        value: actPending.toDouble(),
                        color: AppColors.pending,
                      ),
                      DonutSegment(
                        label: 'Skipped',
                        value: actSkipped.toDouble(),
                        color: theme.colorScheme.outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: 'Completed',
                          count: actCompleted,
                          color: AppColors.completed,
                          icon: Icons.check_circle_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricTile(
                          label: 'Pending',
                          count: actPending,
                          color: AppColors.pending,
                          icon: Icons.schedule_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricTile(
                          label: 'Skipped',
                          count: actSkipped,
                          color: theme.colorScheme.outline,
                          icon: Icons.skip_next_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    });
  }
}

class _ReportSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _ReportSectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _MetricTile({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
