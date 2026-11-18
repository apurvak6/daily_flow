import 'package:get/get.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/task_occurrence_model.dart';
import '../../../data/repositories/activity_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../tasks/controllers/tasks_controller.dart';

/// Controller managing bottom navigation state and top-level dashboard metrics.
class DashboardController extends GetxController {
  static DashboardController get to => Get.find<DashboardController>();

  final TaskRepository taskRepository;
  final ActivityRepository activityRepository;

  DashboardController({
    required this.taskRepository,
    required this.activityRepository,
  });

  final RxInt currentIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Dashboard Metrics for Today
  final RxInt todayTotalCount = 0.obs;
  final RxInt todayCompletedCount = 0.obs;
  final RxInt todayPendingCount = 0.obs;
  final RxInt todayOverdueCount = 0.obs;
  final RxDouble completionPercentage = 0.0.obs;

  // Today's Time-based Activity Timeline & Upcoming Tasks
  final RxList<TaskOccurrenceModel> todayTimelineTasks =
      <TaskOccurrenceModel>[].obs;
  final RxList<TaskOccurrenceModel> upcomingTasks = <TaskOccurrenceModel>[].obs;
  final RxList<TaskOccurrenceModel> overdueTasks = <TaskOccurrenceModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    refreshDashboard();
  }

  void changeTabIndex(int index) {
    currentIndex.value = index;
    if (index == 0) {
      refreshDashboard();
    } else if (index == 1 && Get.isRegistered<TasksController>()) {
      TasksController.to.loadTasksForSelectedDate();
    }
  }

  /// Refreshes all metrics, timeline tasks, overdue tasks, and upcoming tasks.
  Future<void> refreshDashboard() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final todayIso = AppDateUtils.todayIso;

      // 1. Fetch today's occurrences & stats
      final todayOccurrences = await taskRepository.getOccurrencesForDate(
        todayIso,
      );
      final stats = await taskRepository.getDailyStats(todayIso);
      final overdue = await taskRepository.getOverdueOccurrences(todayIso);
      final upcoming = await taskRepository.getUpcomingOccurrences(
        todayIso,
        limit: 5,
      );

      todayTotalCount.value = stats['total'] ?? 0;
      todayCompletedCount.value = stats['completed'] ?? 0;
      todayPendingCount.value = stats['pending'] ?? 0;
      todayOverdueCount.value = stats['overdue'] ?? overdue.length;

      if (todayTotalCount.value > 0) {
        completionPercentage.value =
            (todayCompletedCount.value / todayTotalCount.value) * 100;
      } else {
        completionPercentage.value = 0.0;
      }

      todayTimelineTasks.assignAll(todayOccurrences);
      overdueTasks.assignAll(overdue);
      upcomingTasks.assignAll(upcoming);
    } catch (e, stack) {
      errorMessage.value = 'Failed to load dashboard data';
      AppLogger.error(
        'Error refreshing dashboard',
        e,
        stack,
        'DashboardController',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggles task completion from Dashboard timeline/upcoming cards.
  Future<void> toggleTask(int occurrenceId, bool currentStatus) async {
    try {
      await taskRepository.toggleOccurrenceCompletion(
        occurrenceId,
        !currentStatus,
      );
      await refreshDashboard();

      // Synchronize TasksController if active
      if (Get.isRegistered<TasksController>()) {
        TasksController.to.loadTasksForSelectedDate();
      }
    } catch (e, stack) {
      AppLogger.error(
        'Error toggling task from dashboard',
        e,
        stack,
        'DashboardController',
      );
    }
  }

  /// Deletes a task from the dashboard or timeline.
  Future<void> deleteTask(int taskId) async {
    try {
      await taskRepository.deleteTask(taskId);
      await refreshDashboard();

      if (Get.isRegistered<TasksController>()) {
        TasksController.to.loadTasksForSelectedDate();
      }
    } catch (e, stack) {
      AppLogger.error(
        'Error deleting task from dashboard',
        e,
        stack,
        'DashboardController',
      );
    }
  }
}
