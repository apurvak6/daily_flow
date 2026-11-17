import 'package:get/get.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/task_occurrence_model.dart';
import '../../../data/repositories/task_repository.dart';

/// ViewModel controller for task management and date-wise occurrences.
class TasksController extends GetxController {
  final TaskRepository taskRepository;

  TasksController({required this.taskRepository});

  final RxBool isLoading = false.obs;
  final RxString selectedDate = AppDateUtils.todayIso.obs;
  final RxList<TaskOccurrenceModel> occurrences = <TaskOccurrenceModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadTasksForSelectedDate();
  }

  Future<void> loadTasksForSelectedDate() async {
    try {
      isLoading.value = true;
      final results = await taskRepository.getOccurrencesForDate(
        selectedDate.value,
      );
      occurrences.assignAll(results);
    } catch (e, stack) {
      AppLogger.error('Failed to load tasks', e, stack, 'TasksController');
    } finally {
      isLoading.value = false;
    }
  }

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
    } catch (e, stack) {
      AppLogger.error(
        'Failed to toggle task completion',
        e,
        stack,
        'TasksController',
      );
    }
  }

  void changeDate(String isoDate) {
    selectedDate.value = isoDate;
    loadTasksForSelectedDate();
  }
}
