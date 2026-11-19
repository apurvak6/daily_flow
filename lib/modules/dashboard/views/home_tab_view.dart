import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/status_badge.dart';
import '../../tasks/widgets/task_form_sheet.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/daily_progress_card.dart';
import '../widgets/task_timeline_item.dart';

/// Premium Dashboard Home Tab displaying today's metrics, progress, timeline, and upcoming tasks.
class HomeTabView extends GetView<DashboardController> {
  const HomeTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppConstants.appName,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Offline',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              AppDateUtils.formatDisplay(DateTime.now()),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => controller.refreshDashboard(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Dashboard',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => TaskFormSheet.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Task'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => controller.refreshDashboard(),
          child: Obx(() {
            // Loading State
            if (controller.isLoading.value &&
                controller.todayTimelineTasks.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // Error State
            if (controller.errorMessage.value.isNotEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppColors.overdue,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.errorMessage.value,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => controller.refreshDashboard(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // 1. Daily Progress & Metric Tiles Card
                DailyProgressCard(
                  totalCount: controller.todayTotalCount.value,
                  completedCount: controller.todayCompletedCount.value,
                  pendingCount: controller.todayPendingCount.value,
                  overdueCount: controller.todayOverdueCount.value,
                  percentage: controller.completionPercentage.value,
                  onPendingTap: () => controller.changeTabIndex(1),
                  onCompletedTap: () => controller.changeTabIndex(1),
                  onOverdueTap: () {
                    if (controller.overdueTasks.isNotEmpty) {
                      _showOverdueDialog(context);
                    }
                  },
                ),
                const SizedBox(height: 20),

                // 2. Overdue Tasks Alert Banner (if any)
                if (controller.todayOverdueCount.value > 0) ...[
                  _buildOverdueAlertBanner(context, theme),
                  const SizedBox(height: 20),
                ],

                // 2b. Daily Activities & Habits Quick Card
                CustomCard(
                  padding: const EdgeInsets.all(14),
                  borderRadius: 16,
                  child: InkWell(
                    onTap: () => Get.toNamed(Routes.activities),
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.completed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.track_changes_rounded,
                            color: AppColors.completed,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daily Activities & Habits',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Meals, workout, medication & daily routines',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Today's Time-Based Timeline Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Today's Timeline",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${controller.todayTimelineTasks.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => controller.changeTabIndex(1),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 4. Timeline Content / Empty State
                if (controller.todayTimelineTasks.isEmpty)
                  EmptyStateWidget(
                    icon: Icons.calendar_today_outlined,
                    title: 'No tasks scheduled for today',
                    description:
                        'Your day is clear! Tap "New Task" to plan your schedule.',
                    // actionLabel: 'Schedule a Task',
                    // onAction: () => TaskFormSheet.show(context),
                  )
                else
                  ...List.generate(controller.todayTimelineTasks.length, (
                    index,
                  ) {
                    final item = controller.todayTimelineTasks[index];
                    return TaskTimelineItem(
                      occurrence: item,
                      isFirst: index == 0,
                      isLast: index == controller.todayTimelineTasks.length - 1,
                      onToggle: (val) =>
                          controller.toggleTask(item.id!, item.isCompleted),
                      onTap: () async {
                        final task = await controller.taskRepository
                            .getTaskById(item.taskId);
                        if (context.mounted && task != null) {
                          TaskFormSheet.show(context, taskToEdit: task);
                        }
                      },
                    );
                  }),
                const SizedBox(height: 24),

                // 5. Upcoming Tasks Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upcoming Tasks',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (controller.upcomingTasks.isNotEmpty)
                      Text(
                        'Next ${controller.upcomingTasks.length}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (controller.upcomingTasks.isEmpty)
                  CustomCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    borderRadius: 14,
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_available_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No upcoming tasks scheduled in the next few days.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...controller.upcomingTasks.map((item) {
                    final date = AppDateUtils.fromIsoDate(item.occurrenceDate);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: CustomCard(
                        borderRadius: 14,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    DateFormat(
                                      'MMM',
                                    ).format(date).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.taskTitle ?? 'Task #${item.taskId}',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (item.category != null) ...[
                                        Text(
                                          item.category!,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          '•',
                                          style: TextStyle(fontSize: 10),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Text(
                                        item.dueTime ?? 'Anytime',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(
                              status: item.priority == AppConstants.priorityHigh
                                  ? BadgeStatus.priorityHigh
                                  : item.priority == AppConstants.priorityLow
                                  ? BadgeStatus.priorityLow
                                  : BadgeStatus.priorityMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 80), // Padding for FAB
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildOverdueAlertBanner(BuildContext context, ThemeData theme) {
    return CustomCard(
      color: AppColors.overdueContainerLight,
      customBorder: Border.all(color: AppColors.overdue.withValues(alpha: 0.3)),
      padding: const EdgeInsets.all(14),
      borderRadius: 14,
      onTap: () => _showOverdueDialog(context),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.overdue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${controller.todayOverdueCount.value} Overdue Task${controller.todayOverdueCount.value > 1 ? 's' : ''}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.overdue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap to inspect and complete pending past tasks.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.overdue.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.overdue,
          ),
        ],
      ),
    );
  }

  void _showOverdueDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.overdue),
              const SizedBox(width: 8),
              const Text('Overdue Tasks'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Obx(
              () => controller.overdueTasks.isEmpty
                  ? const Text('No overdue tasks!')
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: controller.overdueTasks.length,
                      itemBuilder: (context, index) {
                        final item = controller.overdueTasks[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.taskTitle ?? 'Task #${item.taskId}'),
                          subtitle: Text('Due: ${item.occurrenceDate}'),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.check_circle_outline,
                              color: AppColors.completed,
                            ),
                            onPressed: () {
                              controller.toggleTask(item.id!, false);
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
