import 'package:get/get.dart';
import '../../core/services/notification_service.dart';
import '../datasources/activity_local_datasource.dart';
import '../models/activity_model.dart';
import '../models/activity_occurrence_model.dart';

/// Repository interface governing Activity and ActivityOccurrence domain operations.
abstract class ActivityRepository {
  Future<int> createActivity(ActivityModel activity);
  Future<int> updateActivity(ActivityModel activity);
  Future<int> deleteActivity(int activityId);
  Future<ActivityModel?> getActivityById(int activityId);
  Future<List<ActivityModel>> getAllActivities({bool onlyActive = false});
  Future<List<ActivityOccurrenceModel>> getOccurrencesForDate(String isoDate);
  Future<List<ActivityOccurrenceModel>> getOccurrencesBetween(
    String startDate,
    String endDate,
  );
  Future<int> setOccurrenceStatus(int occurrenceId, String status);
  Future<int> toggleOccurrenceCompletion(int occurrenceId, bool isCompleted);
  Future<int> skipOccurrence(int occurrenceId);
  Future<int> logOccurrenceProgress(
    int occurrenceId,
    int actualValue,
    int targetValue,
  );
  Future<Map<String, int>> getDailyStats(String isoDate);
}

/// Implementation of [ActivityRepository] bridging ViewModel/Controller to [ActivityLocalDataSource].
class ActivityRepositoryImpl implements ActivityRepository {
  final ActivityLocalDataSource _dataSource;
  final NotificationService? _notificationService;

  ActivityRepositoryImpl({
    ActivityLocalDataSource? dataSource,
    NotificationService? notificationService,
  })  : _dataSource = dataSource ?? ActivityLocalDataSourceImpl(),
        _notificationService = notificationService ??
            (Get.isRegistered<NotificationService>()
                ? Get.find<NotificationService>()
                : null);

  @override
  Future<int> createActivity(ActivityModel activity) async {
    final id = await _dataSource.insertActivity(activity);
    if (id > 0 && _notificationService != null) {
      await _notificationService.scheduleActivityNotification(
        activity.copyWith(id: id),
      );
    }
    return id;
  }

  @override
  Future<int> updateActivity(ActivityModel activity) async {
    final count = await _dataSource.updateActivity(activity);
    if (_notificationService != null && activity.id != null) {
      if (!activity.isActive || !activity.isReminderEnabled) {
        await _notificationService.cancelActivityNotification(activity.id!);
      } else {
        await _notificationService.scheduleActivityNotification(activity);
      }
    }
    return count;
  }

  @override
  Future<int> deleteActivity(int activityId) async {
    final count = await _dataSource.deleteActivity(activityId);
    if (_notificationService != null) {
      await _notificationService.cancelActivityNotification(activityId);
    }
    return count;
  }

  @override
  Future<ActivityModel?> getActivityById(int activityId) async {
    return await _dataSource.getActivityById(activityId);
  }

  @override
  Future<List<ActivityModel>> getAllActivities({
    bool onlyActive = false,
  }) async {
    return await _dataSource.getAllActivities(onlyActive: onlyActive);
  }

  @override
  Future<List<ActivityOccurrenceModel>> getOccurrencesForDate(
    String isoDate,
  ) async {
    return await _dataSource.getOccurrencesForDate(isoDate);
  }

  @override
  Future<List<ActivityOccurrenceModel>> getOccurrencesBetween(
    String startDate,
    String endDate,
  ) async {
    return await _dataSource.getOccurrencesBetween(startDate, endDate);
  }

  @override
  Future<int> setOccurrenceStatus(int occurrenceId, String status) async {
    return await _dataSource.setOccurrenceStatus(occurrenceId, status);
  }

  @override
  Future<int> toggleOccurrenceCompletion(
    int occurrenceId,
    bool isCompleted,
  ) async {
    return await _dataSource.setOccurrenceCompletion(occurrenceId, isCompleted);
  }

  @override
  Future<int> skipOccurrence(int occurrenceId) async {
    return await _dataSource.skipOccurrence(occurrenceId);
  }

  @override
  Future<int> logOccurrenceProgress(
    int occurrenceId,
    int actualValue,
    int targetValue,
  ) async {
    return await _dataSource.updateOccurrenceValue(
      occurrenceId,
      actualValue,
      targetValue,
    );
  }

  @override
  Future<Map<String, int>> getDailyStats(String isoDate) async {
    return await _dataSource.getDailyStats(isoDate);
  }
}
