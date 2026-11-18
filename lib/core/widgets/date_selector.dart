import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/date_utils.dart';

/// Premium interactive date selector with previous/next buttons and date picker.
class DateSelector extends StatelessWidget {
  final String selectedDate;
  final ValueChanged<String> onDateChanged;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onToday;

  const DateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.onPrevious,
    this.onNext,
    this.onToday,
  });

  Future<void> _pickDate(BuildContext context) async {
    final initial = DateTime.tryParse(selectedDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      onDateChanged(picked.toIso8601String().substring(0, 10));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dt = DateTime.tryParse(selectedDate) ?? DateTime.now();
    final isToday = selectedDate == AppDateUtils.todayIso;

    String dateTitle;
    if (isToday) {
      dateTitle = 'Today, ${DateFormat('MMM d').format(dt)}';
    } else {
      dateTitle = DateFormat('EEE, MMM d, yyyy').format(dt);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Previous day',
            onPressed:
                onPrevious ??
                () {
                  final prev = dt.subtract(const Duration(days: 1));
                  onDateChanged(prev.toIso8601String().substring(0, 10));
                },
          ),
          Expanded(
            child: InkWell(
              onTap: () => _pickDate(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!isToday && onToday != null)
            TextButton(
              onPressed: onToday,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(50, 36),
              ),
              child: const Text('Today'),
            ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Next day',
            onPressed:
                onNext ??
                () {
                  final next = dt.add(const Duration(days: 1));
                  onDateChanged(next.toIso8601String().substring(0, 10));
                },
          ),
        ],
      ),
    );
  }
}
