import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../controllers/activities_controller.dart';

/// Initial Activities Screen View for daily habits.
class ActivitiesView extends GetView<ActivitiesController> {
  const ActivitiesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Activities & Habits',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.occurrences.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.track_changes_rounded,
              title: 'No habits configured',
              description:
                  'Track daily recurring activities, habits, and routines.',
              actionLabel: 'New Activity',
              onAction: () {
                // Placeholder action for Phase 2
              },
            );
          }
          return ListView.builder(
            itemCount: controller.occurrences.length,
            itemBuilder: (context, index) {
              final item = controller.occurrences[index];
              return ListTile(
                title: Text(
                  item.activityTitle ?? 'Activity #${item.activityId}',
                ),
                subtitle: Text('Date: ${item.occurrenceDate}'),
                trailing: Checkbox(
                  value: item.isCompleted,
                  onChanged: (val) =>
                      controller.toggleActivity(item.id!, item.isCompleted),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
