import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../controllers/tasks_controller.dart';
import '../widgets/date_selector_ribbon.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_sheet.dart';

/// Full-featured Task Management Screen adhering to MVVM and GetX.
class TasksView extends GetView<TasksController> {
  const TasksView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Task Management',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Pick Date',
            onPressed: () async {
              final current = AppDateUtils.fromIsoDate(
                controller.selectedDate.value,
              );
              final picked = await showDatePicker(
                context: context,
                initialDate: current,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) {
                controller.changeDate(AppDateUtils.toIsoDate(picked));
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.tonalIcon(
              onPressed: () => TaskFormSheet.show(
                context,
                initialDateIso: controller.selectedDate.value,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => TaskFormSheet.show(
          context,
          initialDateIso: controller.selectedDate.value,
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Task'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Date Selector Ribbon
            Obx(
              () => DateSelectorRibbon(
                selectedDateIso: controller.selectedDate.value,
                onDateSelected: controller.changeDate,
              ),
            ),
            const SizedBox(height: 4),

            // 2. Search & Filter Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SearchBar(
                hintText: 'Search tasks by title or note...',
                leading: const Icon(Icons.search, size: 20),
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStatePropertyAll(
                  theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                ),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                onChanged: controller.setSearchQuery,
              ),
            ),
            const SizedBox(height: 8),

            // 3. Category & Status Filter Chips
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Status Filter: All, Pending, Completed
                  _buildStatusFilterChip('All'),
                  const SizedBox(width: 6),
                  _buildStatusFilterChip('Pending'),
                  const SizedBox(width: 6),
                  _buildStatusFilterChip('Completed'),
                  const SizedBox(width: 12),
                  const VerticalDivider(width: 1, indent: 6, endIndent: 6),
                  const SizedBox(width: 12),

                  // Category Filter Chips
                  _buildCategoryFilterChip('All'),
                  ...AppConstants.defaultTaskCategories.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _buildCategoryFilterChip(cat),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 4. Task List Body
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value &&
                    controller.occurrences.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.errorMessage.value.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 44,
                          color: AppColors.overdue,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          controller.errorMessage.value,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () =>
                              controller.loadTasksForSelectedDate(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final items = controller.filteredOccurrences;

                if (items.isEmpty) {
                  final isFiltered =
                      controller.searchQuery.isNotEmpty ||
                      controller.selectedCategory.value != 'All' ||
                      controller.selectedStatus.value != 'All';

                  return EmptyStateWidget(
                    icon: isFiltered
                        ? Icons.filter_alt_off_rounded
                        : Icons.checklist_rounded,
                    title: isFiltered
                        ? 'No matching tasks found'
                        : 'No tasks for this day',
                    description: isFiltered
                        ? 'Try clearing search filters or selecting another category.'
                        : 'Schedule tasks for this date to stay productive.',
                    actionLabel: isFiltered ? 'Clear Filters' : 'Add Task',
                    onAction: () {
                      if (isFiltered) {
                        controller.setSearchQuery('');
                        controller.setCategoryFilter('All');
                        controller.setStatusFilter('All');
                      } else {
                        TaskFormSheet.show(
                          context,
                          initialDateIso: controller.selectedDate.value,
                        );
                      }
                    },
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 4,
                    bottom: 80,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return TaskCard(
                      occurrence: item,
                      onToggle: (val) => controller.toggleTaskCompletion(
                        item.id!,
                        item.isCompleted,
                      ),
                      onEdit: () async {
                        final task = await controller.getTaskForEdit(
                          item.taskId,
                        );
                        if (context.mounted && task != null) {
                          TaskFormSheet.show(context, taskToEdit: task);
                        }
                      },
                      onDelete: () => _confirmDeleteTask(context, item),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilterChip(String label) {
    return Obx(() {
      final isSelected = controller.selectedStatus.value == label;
      return FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) controller.setStatusFilter(label);
        },
        padding: const EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
      );
    });
  }

  Widget _buildCategoryFilterChip(String category) {
    return Obx(() {
      final isSelected = controller.selectedCategory.value == category;
      return FilterChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) controller.setCategoryFilter(category);
        },
        padding: const EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
      );
    });
  }

  void _confirmDeleteTask(BuildContext context, dynamic item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Task?'),
          content: Text(
            'Are you sure you want to delete "${item.taskTitle ?? 'this task'}"? '
            'All occurrence history for this task will be permanently removed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.overdue),
              onPressed: () {
                Navigator.of(context).pop();
                controller.deleteTask(item.taskId);
                Get.snackbar(
                  'Task Deleted',
                  'Task and related occurrences have been removed.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.surfaceLight,
                  colorText: AppColors.textPrimaryLight,
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 2),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
