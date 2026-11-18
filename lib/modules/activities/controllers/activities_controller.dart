import 'package:get/get.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/models/activity_occurrence_model.dart';
import '../../../data/repositories/activity_repository.dart';
import '../../calendar/controllers/calendar_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

/// ViewModel controller for daily recurring activities, habits, and status tracking.
class ActivitiesController extends GetxController {
  final ActivityRepository activityRepository;

  ActivitiesController({required this.activityRepository});

  final RxBool isLoading = false.obs;
  final RxString selectedDate = AppDateUtils.todayIso.obs;
  final RxList<ActivityOccurrenceModel> occurrences =
      <ActivityOccurrenceModel>[].obs;
  final RxList<ActivityModel> allActivities = <ActivityModel>[].obs;
  final RxString statusFilter =
      'all'.obs; // 'all', 'pending', 'completed', 'skipped'

  final RxInt totalCount = 0.obs;
  final RxInt completedCount = 0.obs;
  final RxInt skippedCount = 0.obs;
  final RxInt pendingCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadAllActivities();
    loadActivitiesForSelectedDate();
  }

  /// Load master activity definitions (templates)
  Future<void> loadAllActivities() async {
    try {
      final list = await activityRepository.getAllActivities();
      allActivities.assignAll(list);
    } catch (e, stack) {
      AppLogger.error(
        'Failed to load activity definitions',
        e,
        stack,
        'ActivitiesController',
      );
    }
  }

  /// Load occurrences for the currently selected date and update stats
  Future<void> loadActivitiesForSelectedDate() async {
    try {
      isLoading.value = true;
      final results = await activityRepository.getOccurrencesForDate(
        selectedDate.value,
      );
      occurrences.assignAll(results);

      final stats = await activityRepository.getDailyStats(selectedDate.value);
      totalCount.value = stats['total'] ?? 0;
      completedCount.value = stats['completed'] ?? 0;
      skippedCount.value = stats['skipped'] ?? 0;
      pendingCount.value = stats['pending'] ?? 0;
    } catch (e, stack) {
      AppLogger.error(
        'Failed to load activities for date ${selectedDate.value}',
        e,
        stack,
        'ActivitiesController',
      );
    } finally {
      isLoading.value = false;
    }
  }

  List<ActivityOccurrenceModel> get filteredOccurrences {
    if (statusFilter.value == 'completed') {
      return occurrences.where((o) => o.isCompletedStatus).toList();
    }
    if (statusFilter.value == 'skipped') {
      return occurrences.where((o) => o.isSkipped).toList();
    }
    if (statusFilter.value == 'pending') {
      return occurrences.where((o) => o.isPending).toList();
    }
    return occurrences;
  }

  double get completionPercentage {
    if (totalCount.value == 0) return 0.0;
    return (completedCount.value / totalCount.value) * 100;
  }

  void setFilter(String filter) {
    statusFilter.value = filter;
  }

  void changeDate(String isoDate) {
    selectedDate.value = isoDate;
    loadActivitiesForSelectedDate();
  }

  Future<void> markCompleted(int occurrenceId) async {
    try {
      await activityRepository.setOccurrenceStatus(occurrenceId, 'completed');
      await loadActivitiesForSelectedDate();
      _notifyDashboard();
    } catch (e, stack) {
      AppLogger.error(
        'Failed to mark activity completed',
        e,
        stack,
        'ActivitiesController',
      );
    }
  }

  Future<void> markSkipped(int occurrenceId) async {
    try {
      await activityRepository.setOccurrenceStatus(occurrenceId, 'skipped');
      await loadActivitiesForSelectedDate();
      _notifyDashboard();
    } catch (e, stack) {
      AppLogger.error(
        'Failed to mark activity skipped',
        e,
        stack,
        'ActivitiesController',
      );
    }
  }

  Future<void> markPending(int occurrenceId) async {
    try {
      await activityRepository.setOccurrenceStatus(occurrenceId, 'pending');
      await loadActivitiesForSelectedDate();
      _notifyDashboard();
    } catch (e, stack) {
      AppLogger.error(
        'Failed to mark activity pending',
        e,
        stack,
        'ActivitiesController',
      );
    }
  }

  Future<void> toggleActivity(int occurrenceId, bool currentStatus) async {
    try {
      await activityRepository.toggleOccurrenceCompletion(
        occurrenceId,
        !currentStatus,
      );
      await loadActivitiesForSelectedDate();
      _notifyDashboard();
    } catch (e, stack) {
      AppLogger.error(
        'Failed to toggle activity',
        e,
        stack,
        'ActivitiesController',
      );
    }
  }

  Future<void> logProgress(
    int occurrenceId,
    int actualValue,
    int targetValue,
  ) async {
    try {
      await activityRepository.logOccurrenceProgress(
        occurrenceId,
        actualValue,
        targetValue,
      );
      await loadActivitiesForSelectedDate();
      _notifyDashboard();
    } catch (e, stack) {
      AppLogger.error(
        'Failed to log activity progress',
        e,
        stack,
        'ActivitiesController',
      );
    }
  }

  Future<void> createActivity(ActivityModel activity) async {
    try {
      await activityRepository.createActivity(activity);
      await loadAllActivities();
      await loadActivitiesForSelectedDate();
      _notifyDashboard();
    } catch (e, stack) {
      AppLogger.error(
        'Failed to create activity',
        e,
        stack,
        'ActivitiesController',
      );
    }
  }

  Future<void> updateActivity(ActivityModel activity) async {
    try {
      await activityRepository.updateActivity(activity);
      await loadAllActivities();
      await loadActivitiesForSelectedDate();
      _notifyDashboard();
    } catch (e, stack) {
      AppLogger.error(
        'Failed to update activity',
        e,
        stack,
        'ActivitiesController',
      );
    }
  }

  Future<void> toggleActivityActive(ActivityModel activity) async {
    try {
      final updated = activity.copyWith(isActive: !activity.isActive);
      await activityRepository.updateActivity(updated);
      await loadAllActivities();
      await loadActivitiesForSelectedDate();
      _notifyDashboard();
    } catch (e, stack) {
      AppLogger.error(
        'Failed to toggle activity active status',
        e,
        stack,
        'ActivitiesController',
      );
    }
  }

  Future<void> deleteActivity(int activityId) async {
    try {
      await activityRepository.deleteActivity(activityId);
      await loadAllActivities();
      await loadActivitiesForSelectedDate();
      _notifyDashboard();
    } catch (e, stack) {
      AppLogger.error(
        'Failed to delete activity',
        e,
        stack,
        'ActivitiesController',
      );
    }
  }

  void _notifyDashboard() {
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().refreshDashboard();
    }
    if (Get.isRegistered<CalendarController>()) {
      final cal = Get.find<CalendarController>();
      cal.loadSelectedDateDetails(cal.selectedDay.value);
      cal.loadMonthEvents(cal.focusedDay.value);
    }
  }
}
