import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../controllers/reports_controller.dart';

/// Initial Reports Screen View for analytics and charts.
class ReportsView extends GetView<ReportsController> {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Statistics & Reports',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: EmptyStateWidget(
          icon: Icons.bar_chart_rounded,
          title: 'Analytics & Insights',
          description:
              'Daily and weekly performance charts with fl_chart ready for Phase 2.',
        ),
      ),
    );
  }
}
