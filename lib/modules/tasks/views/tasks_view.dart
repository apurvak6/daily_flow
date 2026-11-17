import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../controllers/tasks_controller.dart';

/// Initial Tasks Screen View adhering to MVVM and GetX.
class TasksView extends GetView<TasksController> {
  const TasksView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tasks',
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
              icon: Icons.checklist_rounded,
              title: 'No tasks scheduled',
              description:
                  'You are all caught up for today! Add a new task to get started.',
              actionLabel: 'New Task',
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
                title: Text(item.taskTitle ?? 'Task #${item.taskId}'),
                subtitle: Text('Date: ${item.occurrenceDate}'),
                trailing: Checkbox(
                  value: item.isCompleted,
                  onChanged: (val) => controller.toggleTaskCompletion(
                    item.id!,
                    item.isCompleted,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
