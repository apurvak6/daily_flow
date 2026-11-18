import 'package:get/get.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/activity_occurrence_model.dart';
import '../../../data/models/task_occurrence_model.dart';
import '../../../data/repositories/activity_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

/// ViewModel controller for the Monthly Calendar view, event aggregation, and date-specific details.
class CalendarController extends GetxController {
  final TaskRepository taskRepository;
  final ActivityRepository activityRepository;

  CalendarController({
    required this.taskRepository,
    required this.activityRepository,
  });

  final Rx<DateTime> focusedDay = DateTime.now().obs;
  final Rx<DateTime> selectedDay = DateTime.now().obs;
  final RxBool isLoadingDetails = false.obs;
  final RxBool isLoadingMonth = false.obs;

  // Selected date occurrences
  final RxList<TaskOccurrenceModel> selectedTasks = <TaskOccurrenceModel>[].obs;
  final RxList<ActivityOccurrenceModel> selectedActivities =
      <ActivityOccurrenceModel>[].obs;

  // Task statistics for selected date
  final RxInt tasksTotal = 0.obs;
  final RxInt tasksCompleted = 0.obs;
  final RxInt tasksPending = 0.obs;
  final RxInt tasksOverdue = 0.obs;

  // Activity statistics for selected date
  final RxInt activitiesTotal = 0.obs;
  final RxInt activitiesCompleted = 0.obs;
  final RxInt activitiesSkipped = 0.obs;
  final RxInt activitiesPending = 0.obs;

  // Selected tab in date details: 0 = Tasks, 1 = Activities
  final RxInt detailTab = 0.obs;

  // Maps ISO date to event types: 'task', 'activity'
  final RxMap<String, List<String>> monthEvents = <String, List<String>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadMonthEvents(focusedDay.value);
    loadSelectedDateDetails(selectedDay.value);
  }

  String get selectedDateIso => AppDateUtils.toIsoDate(selectedDay.value);

  void onDaySelected(DateTime selected, DateTime focused) {
    selectedDay.value = selected;
    focusedDay.value = focused;
    loadSelectedDateDetails(selected);
  }

  void onPageChanged(DateTime focused) {
    focusedDay.value = focused;
    loadMonthEvents(focused);
  }

  void goToToday() {
    final now = AppDateUtils.today;
    selectedDay.value = now;
    focusedDay.value = now;
    loadMonthEvents(now);
    loadSelectedDateDetails(now);
  }

  void setDetailTab(int index) {
    detailTab.value = index;
  }

  /// Load tasks and activities occurrences across the visible month window to populate markers.
  Future<void> loadMonthEvents(DateTime month) async {
    try {
      isLoadingMonth.value = true;
      // Start 7 days before month start and 7 days after month end to cover calendar buffer
      final first = DateTime(
        month.year,
        month.month,
        1,
      ).subtract(const Duration(days: 7));
      final last = DateTime(
        month.year,
        month.month + 1,
        0,
      ).add(const Duration(days: 7));

      final startIso = AppDateUtils.toIsoDate(first);
      final endIso = AppDateUtils.toIsoDate(last);

      final taskOccurrences = await taskRepository.getOccurrencesBetween(
        startIso,
        endIso,
      );
      final actOccurrences = await activityRepository.getOccurrencesBetween(
        startIso,
        endIso,
      );

      final Map<String, List<String>> eventMap = {};

      for (final t in taskOccurrences) {
        eventMap.putIfAbsent(t.occurrenceDate, () => []);
        if (!eventMap[t.occurrenceDate]!.contains('task')) {
          eventMap[t.occurrenceDate]!.add('task');
        }
      }

      for (final a in actOccurrences) {
        eventMap.putIfAbsent(a.occurrenceDate, () => []);
        if (!eventMap[a.occurrenceDate]!.contains('activity')) {
          eventMap[a.occurrenceDate]!.add('activity');
        }
      }

      monthEvents.assignAll(eventMap);
    } catch (e, stack) {
      AppLogger.error(
        'Failed to load month events',
        e,
        stack,
        'CalendarController',
      );
    } finally {
      isLoadingMonth.value = false;
    }
  }

  /// Event loader method passed to TableCalendar.
  List<String> getEventsForDay(DateTime day) {
    final iso = AppDateUtils.toIsoDate(day);
    return monthEvents[iso] ?? [];
  }

  /// Load detailed tasks and activities for the selected date.
  Future<void> loadSelectedDateDetails(DateTime date) async {
    try {
      isLoadingDetails.value = true;
      final iso = AppDateUtils.toIsoDate(date);

      final tasks = await taskRepository.getOccurrencesForDate(iso);
      final activities = await activityRepository.getOccurrencesForDate(iso);

      selectedTasks.assignAll(tasks);
      selectedActivities.assignAll(activities);

      // Calculate task stats
      tasksTotal.value = tasks.length;
      final completedT = tasks.where((t) => t.isCompleted).length;
      final overdueT = tasks
          .where((t) => !t.isCompleted && AppDateUtils.isOverdue(iso))
          .length;
      tasksCompleted.value = completedT;
      tasksOverdue.value = overdueT;
      tasksPending.value = (tasks.length - completedT - overdueT) > 0
          ? (tasks.length - completedT - overdueT)
          : 0;

      // Calculate activity stats
      activitiesTotal.value = activities.length;
      final completedA = activities.where((a) => a.isCompletedStatus).length;
      final skippedA = activities.where((a) => a.isSkipped).length;
      activitiesCompleted.value = completedA;
      activitiesSkipped.value = skippedA;
      activitiesPending.value = (activities.length - completedA - skippedA) > 0
          ? (activities.length - completedA - skippedA)
          : 0;
    } catch (e, stack) {
      AppLogger.error(
        'Failed to load date details',
        e,
        stack,
        'CalendarController',
      );
    } finally {
      isLoadingDetails.value = false;
    }
  }

  Future<void> toggleTask(int occurrenceId, bool currentStatus) async {
    try {
      await taskRepository.toggleOccurrenceCompletion(
        occurrenceId,
        !currentStatus,
      );
      await loadSelectedDateDetails(selectedDay.value);
      await loadMonthEvents(focusedDay.value);
      _notifyDashboard();
    } catch (e, stack) {
      AppLogger.error(
        'Failed to toggle task in calendar',
        e,
        stack,
        'CalendarController',
      );
    }
  }

  Future<void> setActivityStatus(int occurrenceId, String status) async {
    try {
      await activityRepository.setOccurrenceStatus(occurrenceId, status);
      await loadSelectedDateDetails(selectedDay.value);
      await loadMonthEvents(focusedDay.value);
      _notifyDashboard();
    } catch (e, stack) {
      AppLogger.error(
        'Failed to update activity status in calendar',
        e,
        stack,
        'CalendarController',
      );
    }
  }

  void _notifyDashboard() {
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().refreshDashboard();
    }
  }
}
