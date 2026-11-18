import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../activities/widgets/activity_card.dart';
import '../../activities/widgets/activity_form_sheet.dart';
import '../../tasks/widgets/task_card.dart';
import '../../tasks/widgets/task_form_sheet.dart';
import '../controllers/calendar_controller.dart';
import '../widgets/date_summary_card.dart';

/// Full-featured Calendar View displaying monthly schedule, event dots, and date details for tasks & activities.
class CalendarView extends GetView<CalendarController> {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Calendar & Schedule',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Convenient "Today" Action Button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => controller.goToToday(),
              icon: const Icon(Icons.today_rounded, size: 18),
              label: const Text('Today'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ),
          // Refresh Button
          IconButton(
            onPressed: () {
              controller.loadMonthEvents(controller.focusedDay.value);
              controller.loadSelectedDateDetails(controller.selectedDay.value);
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Calendar',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Monthly TableCalendar
            _buildCalendar(theme),
            const Divider(height: 1),

            // 2. Selected Date Summary and Item Lists
            Expanded(
              child: Obx(() {
                if (controller.isLoadingDetails.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Selected Date Summary Card
                      DateSummaryCard(
                        date: controller.selectedDay.value,
                        tasksTotal: controller.tasksTotal.value,
                        tasksCompleted: controller.tasksCompleted.value,
                        tasksPending: controller.tasksPending.value,
                        tasksOverdue: controller.tasksOverdue.value,
                        activitiesTotal: controller.activitiesTotal.value,
                        activitiesCompleted:
                            controller.activitiesCompleted.value,
                        activitiesSkipped: controller.activitiesSkipped.value,
                        activitiesPending: controller.activitiesPending.value,
                      ),

                      // Segmented Tab Selector for Tasks vs Activities
                      _buildDetailTabs(theme),

                      // List Content based on active tab
                      controller.detailTab.value == 0
                          ? _buildTasksList(context, theme)
                          : _buildActivitiesList(context, theme),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(ThemeData theme) {
    return Obx(
      () => TableCalendar<String>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2035, 12, 31),
        focusedDay: controller.focusedDay.value,
        currentDay: AppDateUtils.today,
        selectedDayPredicate: (day) =>
            isSameDay(controller.selectedDay.value, day),
        onDaySelected: (selectedDay, focusedDay) =>
            controller.onDaySelected(selectedDay, focusedDay),
        onPageChanged: (focusedDay) => controller.onPageChanged(focusedDay),
        eventLoader: (day) => controller.getEventsForDay(day),
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: const {CalendarFormat.month: 'Month'},
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: theme.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w800,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left_rounded,
            color: theme.colorScheme.onSurface,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurface,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: theme.textTheme.bodySmall!.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          weekendStyle: theme.textTheme.bodySmall!.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.error.withValues(alpha: 0.8),
          ),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: true,
          outsideTextStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
          ),
          weekendTextStyle: TextStyle(
            color: theme.colorScheme.error.withValues(alpha: 0.8),
          ),
          todayDecoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.primary, width: 1.5),
          ),
          todayTextStyle: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
          selectedDecoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return null;
            final hasTask = events.contains('task');
            final hasActivity = events.contains('activity');

            return Positioned(
              bottom: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasTask)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (hasActivity)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: const BoxDecoration(
                        color: AppColors.completed,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailTabs(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: ChoiceChip(
              label: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 16),
                  const SizedBox(width: 6),
                  Text('Tasks (${controller.tasksTotal.value})'),
                ],
              ),
              selected: controller.detailTab.value == 0,
              onSelected: (val) {
                if (val) controller.setDetailTab(0);
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ChoiceChip(
              label: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.track_changes_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text('Activities (${controller.activitiesTotal.value})'),
                ],
              ),
              selected: controller.detailTab.value == 1,
              onSelected: (val) {
                if (val) controller.setDetailTab(1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(BuildContext context, ThemeData theme) {
    final tasks = controller.selectedTasks;

    if (tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: EmptyStateWidget(
          icon: Icons.task_alt_rounded,
          title: 'No tasks scheduled',
          description:
              'No tasks planned for ${AppDateUtils.formatDisplay(controller.selectedDay.value)}.',
          actionLabel: 'Add Task for this Date',
          onAction: () => TaskFormSheet.show(
            context,
            initialDateIso: controller.selectedDateIso,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: tasks.map((occ) {
          return TaskCard(
            occurrence: occ,
            onToggle: (val) => controller.toggleTask(occ.id!, occ.isCompleted),
            onEdit: () async {
              final task = await controller.taskRepository.getTaskById(
                occ.taskId,
              );
              if (context.mounted && task != null) {
                TaskFormSheet.show(context, taskToEdit: task);
              }
            },
            onDelete: () async {
              await controller.taskRepository.deleteTask(occ.taskId);
              controller.loadSelectedDateDetails(controller.selectedDay.value);
              controller.loadMonthEvents(controller.focusedDay.value);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActivitiesList(BuildContext context, ThemeData theme) {
    final activities = controller.selectedActivities;

    if (activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: EmptyStateWidget(
          icon: Icons.fitness_center_rounded,
          title: 'No activities scheduled',
          description:
              'No recurring activities or habits found for ${AppDateUtils.formatDisplay(controller.selectedDay.value)}.',
          actionLabel: 'New Activity',
          onAction: () => ActivityFormSheet.show(context),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: activities.map((occ) {
          return ActivityCard(
            occurrence: occ,
            onComplete: () =>
                controller.setActivityStatus(occ.id!, 'completed'),
            onSkip: () => controller.setActivityStatus(occ.id!, 'skipped'),
            onPending: () => controller.setActivityStatus(occ.id!, 'pending'),
            onEdit: () async {
              final act = await controller.activityRepository.getActivityById(
                occ.activityId,
              );
              if (context.mounted && act != null) {
                ActivityFormSheet.show(context, activityToEdit: act);
              }
            },
            onDelete: () async {
              await controller.activityRepository.deleteActivity(
                occ.activityId,
              );
              controller.loadSelectedDateDetails(controller.selectedDay.value);
              controller.loadMonthEvents(controller.focusedDay.value);
            },
          );
        }).toList(),
      ),
    );
  }
}
