import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../controllers/calendar_controller.dart';

/// Initial Calendar Screen View.
class CalendarView extends GetView<CalendarController> {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Calendar View',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: EmptyStateWidget(
          icon: Icons.calendar_month_rounded,
          title: 'Calendar & Timeline',
          description:
              'Calendar view integration with table_calendar ready for Phase 2.',
        ),
      ),
    );
  }
}
