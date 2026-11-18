import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/custom_card.dart';

/// Card showing high-level task and activity metrics for the date selected on the calendar.
class DateSummaryCard extends StatelessWidget {
  final DateTime date;
  final int tasksTotal;
  final int tasksCompleted;
  final int tasksPending;
  final int tasksOverdue;
  final int activitiesTotal;
  final int activitiesCompleted;
  final int activitiesSkipped;
  final int activitiesPending;

  const DateSummaryCard({
    super.key,
    required this.date,
    required this.tasksTotal,
    required this.tasksCompleted,
    required this.tasksPending,
    required this.tasksOverdue,
    required this.activitiesTotal,
    required this.activitiesCompleted,
    required this.activitiesSkipped,
    required this.activitiesPending,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = AppDateUtils.isToday(AppDateUtils.toIsoDate(date));

    return CustomCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.event_note_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppDateUtils.formatDisplay(date),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Row(
            children: [
              // Tasks summary column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tasks ($tasksTotal)',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildBadge(
                          '$tasksCompleted Done',
                          AppColors.completed.withValues(alpha: 0.15),
                          AppColors.completed,
                        ),
                        _buildBadge(
                          '$tasksPending Due',
                          AppColors.pending.withValues(alpha: 0.15),
                          AppColors.pending,
                        ),
                        if (tasksOverdue > 0)
                          _buildBadge(
                            '$tasksOverdue Overdue',
                            AppColors.overdue.withValues(alpha: 0.15),
                            AppColors.overdue,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Activities summary column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.completed,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Activities ($activitiesTotal)',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildBadge(
                          '$activitiesCompleted Done',
                          AppColors.completed.withValues(alpha: 0.15),
                          AppColors.completed,
                        ),
                        if (activitiesSkipped > 0)
                          _buildBadge(
                            '$activitiesSkipped Skip',
                            Colors.purple.withValues(alpha: 0.15),
                            Colors.purple,
                          ),
                        _buildBadge(
                          '$activitiesPending Due',
                          AppColors.pending.withValues(alpha: 0.15),
                          AppColors.pending,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
