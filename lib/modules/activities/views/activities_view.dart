import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../tasks/widgets/date_selector_ribbon.dart';
import '../controllers/activities_controller.dart';
import '../widgets/activity_card.dart';
import '../widgets/activity_form_sheet.dart';
import '../widgets/activity_template_card.dart';

/// Screen for Daily Activity Management, Routine Logging, and Configured Habit Templates.
class ActivitiesView extends GetView<ActivitiesController> {
  const ActivitiesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Daily Activities',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.schedule_rounded, size: 20),
                text: "Daily Schedule",
              ),
              Tab(
                icon: Icon(Icons.list_alt_rounded, size: 20),
                text: "All Routines",
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: () {
                controller.loadAllActivities();
                controller.loadActivitiesForSelectedDate();
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => ActivityFormSheet.show(context),
          icon: const Icon(Icons.add),
          label: const Text('New Activity'),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Date Occurrences Schedule
            _buildScheduleTab(context, theme),

            // Tab 2: Master Activity Templates List
            _buildAllActivitiesTab(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTab(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        // 1. Date selector ribbon
        Obx(
          () => DateSelectorRibbon(
            selectedDateIso: controller.selectedDate.value,
            onDateSelected: controller.changeDate,
          ),
        ),

        // 2. Summary stats & Filter chips
        Obx(() {
          final total = controller.totalCount.value;
          final completed = controller.completedCount.value;
          final skipped = controller.skippedCount.value;
          final pending = controller.pendingCount.value;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Quick Summary Row
                Row(
                  children: [
                    _buildStatPill(
                      theme,
                      'Total: $total',
                      theme.colorScheme.surfaceContainerHighest,
                      theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    _buildStatPill(
                      theme,
                      'Done: $completed',
                      AppColors.completed.withValues(alpha: 0.15),
                      AppColors.completed,
                    ),
                    const SizedBox(width: 8),
                    _buildStatPill(
                      theme,
                      'Skipped: $skipped',
                      Colors.purple.withValues(alpha: 0.15),
                      Colors.purple,
                    ),
                    const SizedBox(width: 8),
                    _buildStatPill(
                      theme,
                      'Pending: $pending',
                      AppColors.pending.withValues(alpha: 0.15),
                      AppColors.pending,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Status Filter Chips
                Row(
                  children: [
                    _buildFilterChip('All', 'all'),
                    const SizedBox(width: 6),
                    _buildFilterChip('Pending', 'pending'),
                    const SizedBox(width: 6),
                    _buildFilterChip('Completed', 'completed'),
                    const SizedBox(width: 6),
                    _buildFilterChip('Skipped', 'skipped'),
                  ],
                ),
              ],
            ),
          );
        }),
        const Divider(height: 1),

        // 3. Occurrences List
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final items = controller.filteredOccurrences;

            if (items.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.track_changes_rounded,
                title: 'No activities found',
                description: controller.statusFilter.value == 'all'
                    ? 'No activities scheduled for ${AppDateUtils.formatDisplay(AppDateUtils.fromIsoDate(controller.selectedDate.value))}. Tap "New Activity" to configure your daily habits!'
                    : 'No ${controller.statusFilter.value} activities for this date.',
                actionLabel: controller.statusFilter.value == 'all'
                    ? 'Add Daily Activity'
                    : 'Show All',
                onAction: () {
                  if (controller.statusFilter.value == 'all') {
                    ActivityFormSheet.show(context);
                  } else {
                    controller.setFilter('all');
                  }
                },
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final occ = items[index];
                return ActivityCard(
                  occurrence: occ,
                  onComplete: () => controller.markCompleted(occ.id!),
                  onSkip: () => controller.markSkipped(occ.id!),
                  onPending: () => controller.markPending(occ.id!),
                  onEdit: () async {
                    final master = await controller.activityRepository
                        .getActivityById(occ.activityId);
                    if (context.mounted && master != null) {
                      ActivityFormSheet.show(context, activityToEdit: master);
                    }
                  },
                  onDelete: () => _confirmDelete(context, occ.activityId),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAllActivitiesTab(BuildContext context, ThemeData theme) {
    return Obx(() {
      final list = controller.allActivities;

      if (list.isEmpty) {
        return EmptyStateWidget(
          icon: Icons.fitness_center_rounded,
          title: 'No Routines Configured',
          description:
              'Set up recurring daily activities like Breakfast, Lunch, Exercise, Medication, or Custom Routines.',
          actionLabel: 'Add Routine',
          onAction: () => ActivityFormSheet.show(context),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final activity = list[index];
          return ActivityTemplateCard(
            activity: activity,
            onToggleActive: (val) => controller.toggleActivityActive(activity),
            onEdit: () =>
                ActivityFormSheet.show(context, activityToEdit: activity),
            onDelete: () => _confirmDelete(context, activity.id!),
          );
        },
      );
    });
  }

  Widget _buildStatPill(
    ThemeData theme,
    String text,
    Color bgColor,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Obx(() {
      final isSelected = controller.statusFilter.value == value;
      return FilterChip(
        label: Text(label),
        selected: isSelected,
        visualDensity: VisualDensity.compact,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
        onSelected: (_) => controller.setFilter(value),
      );
    });
  }

  void _confirmDelete(BuildContext context, int activityId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Activity?'),
        content: const Text(
          'This will permanently delete this activity and all of its occurrence history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteActivity(activityId);
              Get.snackbar(
                'Activity Deleted',
                'Activity and history removed successfully.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red.withValues(alpha: 0.9),
                colorText: Colors.white,
                margin: const EdgeInsets.all(16),
                borderRadius: 12,
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
