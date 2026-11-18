import 'package:get/get.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/task_occurrence_model.dart';
import '../../../data/repositories/task_repository.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

/// ViewModel controller for task management and date-wise occurrences.
class TasksController extends GetxController {
  static TasksController get to => Get.find<TasksController>();

  final TaskRepository taskRepository;

  TasksController({required this.taskRepository});

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString selectedDate = AppDateUtils.todayIso.obs;
  final RxList<TaskOccurrenceModel> occurrences = <TaskOccurrenceModel>[].obs;

  // Search & Filter state
  final RxString selectedCategory = 'All'.obs;
  final RxString selectedStatus = 'All'.obs; // 'All', 'Pending', 'Completed'
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadTasksForSelectedDate();
  }

  /// Loads all occurrences for the currently selected date.
  Future<void> loadTasksForSelectedDate() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final results = await taskRepository.getOccurrencesForDate(
        selectedDate.value,
      );
      occurrences.assignAll(results);
    } catch (e, stack) {
      errorMessage.value = 'Failed to load tasks for date';
      AppLogger.error('Failed to load tasks', e, stack, 'TasksController');
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggles task completion and synchronizes the Dashboard.
  Future<void> toggleTaskCompletion(
    int occurrenceId,
    bool currentStatus,
  ) async {
    try {
      await taskRepository.toggleOccurrenceCompletion(
        occurrenceId,
        !currentStatus,
      );
      await loadTasksForSelectedDate();

      if (Get.isRegistered<DashboardController>()) {
        DashboardController.to.refreshDashboard();
      }
    } catch (e, stack) {
      AppLogger.error(
        'Failed to toggle task completion',
        e,
        stack,
        'TasksController',
      );
    }
  }

  /// Creates a new task and synchronizes the Dashboard.
  Future<bool> createTask(TaskModel task) async {
    try {
      isLoading.value = true;
      await taskRepository.createTask(task);
      await loadTasksForSelectedDate();

      if (Get.isRegistered<DashboardController>()) {
        DashboardController.to.refreshDashboard();
      }
      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to create task', e, stack, 'TasksController');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Updates an existing task and synchronizes the Dashboard.
  Future<bool> updateTask(TaskModel task) async {
    try {
      isLoading.value = true;
      await taskRepository.updateTask(task);
      await loadTasksForSelectedDate();

      if (Get.isRegistered<DashboardController>()) {
        DashboardController.to.refreshDashboard();
      }
      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to update task', e, stack, 'TasksController');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Deletes a task by ID (cascading occurrences) and synchronizes the Dashboard.
  Future<bool> deleteTask(int taskId) async {
    try {
      await taskRepository.deleteTask(taskId);
      await loadTasksForSelectedDate();

      if (Get.isRegistered<DashboardController>()) {
        DashboardController.to.refreshDashboard();
      }
      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to delete task', e, stack, 'TasksController');
      return false;
    }
  }

  /// Retrieves the master task model for editing.
  Future<TaskModel?> getTaskForEdit(int taskId) async {
    try {
      return await taskRepository.getTaskById(taskId);
    } catch (e, stack) {
      AppLogger.error(
        'Failed to fetch task for edit',
        e,
        stack,
        'TasksController',
      );
      return null;
    }
  }

  /// Changes the active calendar date.
  void changeDate(String isoDate) {
    selectedDate.value = isoDate;
    loadTasksForSelectedDate();
  }

  void setCategoryFilter(String category) {
    selectedCategory.value = category;
  }

  void setStatusFilter(String status) {
    selectedStatus.value = status;
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Returns occurrences filtered by category, status, and search query.
  List<TaskOccurrenceModel> get filteredOccurrences {
    return occurrences.where((item) {
      // 1. Search Query filter
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        final title = (item.taskTitle ?? '').toLowerCase();
        final desc = (item.taskDescription ?? '').toLowerCase();
        if (!title.contains(query) && !desc.contains(query)) {
          return false;
        }
      }

      // 2. Category filter
      if (selectedCategory.value != 'All') {
        if (item.category != selectedCategory.value) {
          return false;
        }
      }

      // 3. Status filter
      if (selectedStatus.value == 'Pending' && item.isCompleted) {
        return false;
      }
      if (selectedStatus.value == 'Completed' && !item.isCompleted) {
        return false;
      }

      return true;
    }).toList();
  }
}
