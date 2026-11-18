import 'package:get/get.dart';
import '../../core/utils/date_utils.dart';
import '../../data/datasources/activity_local_datasource.dart';
import '../../data/datasources/task_local_datasource.dart';

/// Service responsible for aggregating statistics used by the Reports UI.
/// All queries are performed directly on the SQLite database via the existing
/// local data sources. No extra tables are created – we only reuse the
/// `task_occurrences`, `activity_occurrences`, `tasks` and `activities`
/// tables.
class ReportingService extends GetxService {
  final TaskLocalDataSource _taskDataSource;
  final ActivityLocalDataSource _activityDataSource;

  ReportingService({
    TaskLocalDataSource? taskDataSource,
    ActivityLocalDataSource? activityDataSource,
  }) : _taskDataSource = taskDataSource ?? TaskLocalDataSourceImpl(),
       _activityDataSource =
           activityDataSource ?? ActivityLocalDataSourceImpl();

  // Expose getters for testing purposes
  TaskLocalDataSource get taskDataSource => _taskDataSource;
  ActivityLocalDataSource get activityDataSource => _activityDataSource;

  /// Daily statistics for a given ISO date (yyyy-MM-dd).
  /// Returns a map with keys:
  /// - taskCompleted, taskTotal, taskPending, taskOverdue, taskCompletionPct
  /// - activityCompleted, activityTotal, activityPending, activitySkipped, activityCompletionPct
  Future<Map<String, int>> getDailyStats(String isoDate) async {
    // 1. Ensure recurring occurrences are populated for this date
    await _taskDataSource.getOccurrencesForDate(isoDate);
    await _activityDataSource.getOccurrencesForDate(isoDate);

    final taskCompleted = await _taskDataSource.getCompletedCountForDate(
      isoDate,
    );
    final taskTotal = await _taskDataSource.getTotalCountForDate(isoDate);

    final todayIso = AppDateUtils.todayIso;
    int taskOverdue = 0;
    if (isoDate == todayIso) {
      taskOverdue = await _taskDataSource.getOverdueCount(todayIso);
    } else if (isoDate.compareTo(todayIso) < 0) {
      // For a past date, uncompleted tasks on that date are overdue
      taskOverdue = taskTotal > taskCompleted ? taskTotal - taskCompleted : 0;
    } else {
      taskOverdue = 0;
    }

    final activityCompleted = await _activityDataSource
        .getCompletedCountForDate(isoDate);
    final activityTotal = await _activityDataSource.getTotalCountForDate(
      isoDate,
    );
    final activitySkipped = await _activityDataSource.getSkippedCountForDate(
      isoDate,
    );

    final taskPending = taskTotal > taskCompleted
        ? taskTotal - taskCompleted
        : 0;
    final activityPending =
        (activityTotal - activityCompleted - activitySkipped) > 0
        ? activityTotal - activityCompleted - activitySkipped
        : 0;

    final taskCompletionPct = taskTotal == 0
        ? 0
        : (taskCompleted * 100 ~/ taskTotal);
    final activityCompletionPct = activityTotal == 0
        ? 0
        : (activityCompleted * 100 ~/ activityTotal);

    return {
      'taskCompleted': taskCompleted,
      'taskTotal': taskTotal,
      'taskPending': taskPending,
      'taskOverdue': taskOverdue,
      'taskCompletionPct': taskCompletionPct,
      'activityCompleted': activityCompleted,
      'activityTotal': activityTotal,
      'activityPending': activityPending,
      'activitySkipped': activitySkipped,
      'activityCompletionPct': activityCompletionPct,
    };
  }

  /// Weekly statistics for a week starting on [isoStartDate] (Monday).
  /// Returns a map containing daily progression and aggregated totals.
  Future<Map<String, dynamic>> getWeeklyStats(String isoStartDate) async {
    final startDt = DateTime.parse(isoStartDate);
    final List<Map<String, dynamic>> daily = [];
    int weekTaskCompleted = 0;
    int weekTaskTotal = 0;
    int weekTaskPending = 0;
    int weekTaskOverdue = 0;
    int weekActivityCompleted = 0;
    int weekActivityTotal = 0;
    int weekActivityPending = 0;
    int weekActivitySkipped = 0;

    final todayIso = AppDateUtils.todayIso;
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 0; i < 7; i++) {
      final dt = startDt.add(Duration(days: i));
      final d = dt.toIso8601String().substring(0, 10);
      final stats = await getDailyStats(d);

      final tCompleted = stats['taskCompleted']!;
      final tTotal = stats['taskTotal']!;
      final tPending = stats['taskPending']!;
      final tOverdue = stats['taskOverdue']!;
      final aCompleted = stats['activityCompleted']!;
      final aTotal = stats['activityTotal']!;
      final aPending = stats['activityPending']!;
      final aSkipped = stats['activitySkipped']!;
      final tPct = tTotal == 0 ? 0 : (tCompleted * 100 ~/ tTotal);
      final aPct = aTotal == 0 ? 0 : (aCompleted * 100 ~/ aTotal);

      daily.add({
        'date': d,
        'dateInt': int.parse(d.replaceAll('-', '')),
        'dayIndex': i,
        'dayName': dayNames[i],
        'taskCompleted': tCompleted,
        'taskTotal': tTotal,
        'taskPending': tPending,
        'taskOverdue': tOverdue,
        'completionPct': tPct,
        'activityCompleted': aCompleted,
        'activityTotal': aTotal,
        'activityPending': aPending,
        'activitySkipped': aSkipped,
        'activityCompletionPct': aPct,
      });

      weekTaskCompleted += tCompleted;
      weekTaskTotal += tTotal;
      weekTaskPending += tPending;
      if (d.compareTo(todayIso) <= 0) {
        weekTaskOverdue += tOverdue;
      }
      weekActivityCompleted += aCompleted;
      weekActivityTotal += aTotal;
      weekActivityPending += aPending;
      weekActivitySkipped += aSkipped;
    }

    final endDt = startDt.add(const Duration(days: 6));
    final isoEndDate = endDt.toIso8601String().substring(0, 10);

    final weekTaskCompletionPct = weekTaskTotal == 0
        ? 0
        : (weekTaskCompleted * 100 ~/ weekTaskTotal);
    final weekActivityCompletionPct = weekActivityTotal == 0
        ? 0
        : (weekActivityCompleted * 100 ~/ weekActivityTotal);

    return {
      'startDate': isoStartDate,
      'endDate': isoEndDate,
      'daily': daily,
      'weekTaskCompleted': weekTaskCompleted,
      'weekTaskTotal': weekTaskTotal,
      'weekTaskPending': weekTaskPending,
      'weekTaskOverdue': weekTaskOverdue,
      'weekTaskCompletionPct': weekTaskCompletionPct,
      'weekActivityCompleted': weekActivityCompleted,
      'weekActivityTotal': weekActivityTotal,
      'weekActivityPending': weekActivityPending,
      'weekActivitySkipped': weekActivitySkipped,
      'weekActivityCompletionPct': weekActivityCompletionPct,
    };
  }

  /// Category‑wise activity summary across the entire database.
  /// Returns a list of maps: category, total, completed, pending, skipped, completionPct.
  Future<List<Map<String, dynamic>>> getCategoryActivitySummary() async {
    final raw = await _activityDataSource.getCategorySummary();
    return raw.map((row) {
      final total = (row['total'] as num?)?.toInt() ?? 0;
      final completed = (row['completed'] as num?)?.toInt() ?? 0;
      final skipped = (row['skipped'] as num?)?.toInt() ?? 0;
      final pending =
          (row['pending'] as num?)?.toInt() ??
          (total > (completed + skipped) ? total - completed - skipped : 0);
      final pct = total == 0 ? 0 : (completed * 100 ~/ total);

      return {
        'category': (row['category'] as String?) ?? 'General',
        'total': total,
        'completed': completed,
        'pending': pending,
        'skipped': skipped,
        'completionPct': pct,
      };
    }).toList();
  }

  /// History records for a specific date.
  /// Fetches tasks and activities for read-only inspection.
  Future<Map<String, dynamic>> getHistoryForDate(String isoDate) async {
    final tasks = await _taskDataSource.getOccurrencesForDate(isoDate);
    final activities = await _activityDataSource.getOccurrencesForDate(isoDate);
    final stats = await getDailyStats(isoDate);

    return {
      'date': isoDate,
      'tasks': tasks,
      'activities': activities,
      'stats': stats,
    };
  }
}
