import 'package:get/get.dart';
import '../../core/services/notification_service.dart';
import '../datasources/task_local_datasource.dart';
import '../models/task_model.dart';
import '../models/task_occurrence_model.dart';

/// Repository interface governing Task and TaskOccurrence domain operations.
abstract class TaskRepository {
  Future<int> createTask(TaskModel task);
  Future<int> updateTask(TaskModel task);
  Future<int> deleteTask(int taskId);
  Future<TaskModel?> getTaskById(int taskId);
  Future<List<TaskModel>> getAllTasks();
  Future<List<TaskOccurrenceModel>> getOccurrencesForDate(String isoDate);
  Future<List<TaskOccurrenceModel>> getOccurrencesBetween(
    String startDate,
    String endDate,
  );
  Future<List<TaskOccurrenceModel>> getOverdueOccurrences(String todayIso);
  Future<List<TaskOccurrenceModel>> getUpcomingOccurrences(
    String fromIsoDate, {
    int limit = 10,
  });
  Future<int> getOverdueCount(String todayIso);
  Future<int> toggleOccurrenceCompletion(int occurrenceId, bool isCompleted);
  Future<Map<String, int>> getDailyStats(String isoDate);
}

/// Implementation of [TaskRepository] bridging ViewModel/Controller to [TaskLocalDataSource].
class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource _dataSource;
  final NotificationService? _notificationService;

  TaskRepositoryImpl({
    TaskLocalDataSource? dataSource,
    NotificationService? notificationService,
  }) : _dataSource = dataSource ?? TaskLocalDataSourceImpl(),
       _notificationService =
           notificationService ??
           (Get.isRegistered<NotificationService>()
               ? Get.find<NotificationService>()
               : null);

  @override
  Future<int> createTask(TaskModel task) async {
    final id = await _dataSource.insertTask(task);
    if (id > 0 && _notificationService != null) {
      await _notificationService.scheduleTaskNotification(
        task.copyWith(id: id),
      );
    }
    return id;
  }

  @override
  Future<int> updateTask(TaskModel task) async {
    final count = await _dataSource.updateTask(task);
    if (_notificationService != null) {
      if (task.isCompleted || task.reminderTime == null) {
        if (task.id != null) {
          await _notificationService.cancelTaskNotification(task.id!);
        }
      } else {
        await _notificationService.scheduleTaskNotification(task);
      }
    }
    return count;
  }

  @override
  Future<int> deleteTask(int taskId) async {
    final count = await _dataSource.deleteTask(taskId);
    if (_notificationService != null) {
      await _notificationService.cancelTaskNotification(taskId);
    }
    return count;
  }

  @override
  Future<TaskModel?> getTaskById(int taskId) async {
    return await _dataSource.getTaskById(taskId);
  }

  @override
  Future<List<TaskModel>> getAllTasks() async {
    return await _dataSource.getAllTasks();
  }

  @override
  Future<List<TaskOccurrenceModel>> getOccurrencesForDate(
    String isoDate,
  ) async {
    return await _dataSource.getOccurrencesForDate(isoDate);
  }

  @override
  Future<List<TaskOccurrenceModel>> getOccurrencesBetween(
    String startDate,
    String endDate,
  ) async {
    return await _dataSource.getOccurrencesBetween(startDate, endDate);
  }

  @override
  Future<List<TaskOccurrenceModel>> getOverdueOccurrences(
    String todayIso,
  ) async {
    return await _dataSource.getOverdueOccurrences(todayIso);
  }

  @override
  Future<List<TaskOccurrenceModel>> getUpcomingOccurrences(
    String fromIsoDate, {
    int limit = 10,
  }) async {
    return await _dataSource.getUpcomingOccurrences(fromIsoDate, limit: limit);
  }

  @override
  Future<int> getOverdueCount(String todayIso) async {
    return await _dataSource.getOverdueCount(todayIso);
  }

  @override
  Future<int> toggleOccurrenceCompletion(
    int occurrenceId,
    bool isCompleted,
  ) async {
    return await _dataSource.setOccurrenceCompletion(occurrenceId, isCompleted);
  }

  @override
  Future<Map<String, int>> getDailyStats(String isoDate) async {
    final completed = await _dataSource.getCompletedCountForDate(isoDate);
    final total = await _dataSource.getTotalCountForDate(isoDate);
    final overdue = await _dataSource.getOverdueCount(isoDate);
    return {
      'completed': completed,
      'total': total,
      'pending': total > completed ? total - completed : 0,
      'overdue': overdue,
    };
  }
}
