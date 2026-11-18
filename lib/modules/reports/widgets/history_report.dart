import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/date_selector.dart';
import '../../../data/models/activity_occurrence_model.dart';
import '../../../data/models/task_occurrence_model.dart';
import '../controllers/reports_controller.dart';

/// Historical date-wise review of completed, pending, skipped, and overdue records.
/// Strictly read-only to preserve historical integrity.
class HistoryReport extends StatelessWidget {
  const HistoryReport({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ReportsController>();
    final theme = Theme.of(context);

    return Obx(() {
      final selectedDate = ctrl.selectedDate.value;
      final tasks = ctrl.historyTasks;
      final activities = ctrl.historyActivities;
      final filter = ctrl.historyFilter.value;

      final totalItems = tasks.length + activities.length;

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selector
            DateSelector(
              selectedDate: selectedDate,
              onDateChanged: ctrl.changeDate,
              onPrevious: ctrl.goToPreviousDay,
              onNext: ctrl.goToNextDay,
              onToday: ctrl.goToToday,
            ),
            const SizedBox(height: 16),

            // Read-only Notice Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_clock_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Historical records are read-only to preserve report integrity.',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Filter Tabs (All / Tasks / Activities)
            Row(
              children: [
                _FilterChip(
                  label: 'All ($totalItems)',
                  isSelected: filter == 'All',
                  onTap: () => ctrl.setHistoryFilter('All'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Tasks (${tasks.length})',
                  isSelected: filter == 'Tasks',
                  onTap: () => ctrl.setHistoryFilter('Tasks'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Activities (${activities.length})',
                  isSelected: filter == 'Activities',
                  onTap: () => ctrl.setHistoryFilter('Activities'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (totalItems == 0)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_busy_rounded,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No records found for this date',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Task Occurrences List
            if ((filter == 'All' || filter == 'Tasks') && tasks.isNotEmpty) ...[
              Text(
                'Tasks (${tasks.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              ...tasks.map(
                (task) => _TaskHistoryItem(
                  task: task,
                  isHistoricalDate:
                      selectedDate.compareTo(AppDateUtils.todayIso) < 0,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Activity Occurrences List
            if ((filter == 'All' || filter == 'Activities') &&
                activities.isNotEmpty) ...[
              Text(
                'Activities (${activities.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 8),
              ...activities.map((act) => _ActivityHistoryItem(occurrence: act)),
              const SizedBox(height: 24),
            ],
          ],
        ),
      );
    });
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _TaskHistoryItem extends StatelessWidget {
  final TaskOccurrenceModel task;
  final bool isHistoricalDate;

  const _TaskHistoryItem({required this.task, required this.isHistoricalDate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = task.isCompleted;
    final isOverdue = !isDone && isHistoricalDate;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isDone) {
      statusColor = AppColors.completed;
      statusText = 'Completed';
      statusIcon = Icons.check_circle_rounded;
    } else if (isOverdue) {
      statusColor = AppColors.overdue;
      statusText = 'Overdue';
      statusIcon = Icons.error_rounded;
    } else {
      statusColor = AppColors.pending;
      statusText = 'Pending';
      statusIcon = Icons.hourglass_top_rounded;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.taskTitle ?? 'Task #${task.taskId}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (task.category != null) ...[
                        Text(
                          task.category!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '•',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (task.dueTime != null)
                        Text(
                          task.dueTime!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusText,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityHistoryItem extends StatelessWidget {
  final ActivityOccurrenceModel occurrence;

  const _ActivityHistoryItem({required this.occurrence});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = occurrence.status;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (occurrence.isCompleted || status == 'completed') {
      statusColor = AppColors.completed;
      statusText = 'Completed';
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'skipped') {
      statusColor = theme.colorScheme.outline;
      statusText = 'Skipped';
      statusIcon = Icons.skip_next_rounded;
    } else {
      statusColor = AppColors.pending;
      statusText = 'Pending';
      statusIcon = Icons.schedule_rounded;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    occurrence.activityTitle ??
                        'Activity #${occurrence.activityId}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (occurrence.category != null) ...[
                        Text(
                          occurrence.category!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '•',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (occurrence.targetValue != null &&
                          occurrence.targetValue! > 0)
                        Text(
                          '${occurrence.actualValue}/${occurrence.targetValue} ${occurrence.unit ?? ''}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusText,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
