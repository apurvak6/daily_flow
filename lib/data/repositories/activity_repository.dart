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
  Future<int> toggleOccurrenceCompletion(int occurrenceId, bool isCompleted);
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

  ActivityRepositoryImpl({ActivityLocalDataSource? dataSource})
    : _dataSource = dataSource ?? ActivityLocalDataSourceImpl();

  @override
  Future<int> createActivity(ActivityModel activity) async {
    return await _dataSource.insertActivity(activity);
  }

  @override
  Future<int> updateActivity(ActivityModel activity) async {
    return await _dataSource.updateActivity(activity);
  }

  @override
  Future<int> deleteActivity(int activityId) async {
    return await _dataSource.deleteActivity(activityId);
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
  Future<int> toggleOccurrenceCompletion(
    int occurrenceId,
    bool isCompleted,
  ) async {
    return await _dataSource.setOccurrenceCompletion(occurrenceId, isCompleted);
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
    final completed = await _dataSource.getCompletedCountForDate(isoDate);
    final total = await _dataSource.getTotalCountForDate(isoDate);
    return {
      'completed': completed,
      'total': total,
      'pending': total > completed ? total - completed : 0,
    };
  }
}
