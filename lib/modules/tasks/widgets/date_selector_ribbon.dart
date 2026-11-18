import 'package:flutter/material.dart';
import '../../../core/utils/date_utils.dart';

/// Horizontal ribbon for quick calendar date navigation.
class DateSelectorRibbon extends StatelessWidget {
  final String selectedDateIso;
  final ValueChanged<String> onDateSelected;

  const DateSelectorRibbon({
    super.key,
    required this.selectedDateIso,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeDate = AppDateUtils.fromIsoDate(selectedDateIso);
    final weekDays = AppDateUtils.daysOfWeek(activeDate);
    final isViewingToday = selectedDateIso == AppDateUtils.todayIso;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppDateUtils.formatDisplay(activeDate),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (!isViewingToday)
                TextButton.icon(
                  onPressed: () => onDateSelected(AppDateUtils.todayIso),
                  icon: const Icon(Icons.today, size: 16),
                  label: const Text('Today'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weekDays.map((day) {
              final dayIso = AppDateUtils.toIsoDate(day);
              final isSelected = dayIso == selectedDateIso;
              final isToday = dayIso == AppDateUtils.todayIso;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onDateSelected(dayIso),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : isToday
                          ? theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.5,
                            )
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : isToday
                            ? theme.colorScheme.primary.withValues(alpha: 0.4)
                            : theme.colorScheme.outline.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getWeekdayLetter(day.weekday),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.day}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getWeekdayLetter(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }
}
