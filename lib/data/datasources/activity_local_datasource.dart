import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/db_constants.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/date_utils.dart';
import '../models/activity_model.dart';
import '../models/activity_occurrence_model.dart';

/// Contract for activity SQLite local data access.
abstract class ActivityLocalDataSource {
  Future<int> insertActivity(ActivityModel activity);
  Future<int> updateActivity(ActivityModel activity);
  Future<int> deleteActivity(int activityId);
  Future<ActivityModel?> getActivityById(int activityId);
  Future<List<ActivityModel>> getAllActivities({bool onlyActive = false});
  Future<List<ActivityOccurrenceModel>> getOccurrencesForDate(String isoDate);
  Future<List<ActivityOccurrenceModel>> getOccurrencesBetween(
    String startDate,
    String endDate,
  );
  Future<int> setOccurrenceCompletion(int occurrenceId, bool isCompleted);
  Future<int> updateOccurrenceValue(
    int occurrenceId,
    int actualValue,
    int targetValue,
  );

  /// Mark an occurrence as skipped. Updates notes to "Skipped" and clears completion flag.
  Future<int> skipOccurrence(int occurrenceId);
  Future<int> getCompletedCountForDate(String isoDate);
  Future<int> getTotalCountForDate(String isoDate);
}

/// Implementation of [ActivityLocalDataSource] leveraging SQLite through [DatabaseHelper].
class ActivityLocalDataSourceImpl implements ActivityLocalDataSource {
  final DatabaseHelper _dbHelper;

  ActivityLocalDataSourceImpl({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<int> insertActivity(ActivityModel activity) async {
    return await _dbHelper.runInTransaction<int>((txn) async {
      final now = DateTime.now().toIso8601String();
      final actMap = activity.copyWith(createdAt: now, updatedAt: now).toMap();

      final actId = await txn.insert(DbConstants.tableActivities, actMap);

      // Create initial occurrence for today
      final todayIso = AppDateUtils.todayIso;
      final occurrence = ActivityOccurrenceModel(
        activityId: actId,
        occurrenceDate: todayIso,
        createdAt: now,
        updatedAt: now,
      );

      await txn.insert(
        DbConstants.tableActivityOccurrences,
        occurrence.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      AppLogger.info(
        'Inserted activity #$actId with today occurrence',
        'ActivityLocalDataSource',
      );
      return actId;
    });
  }

  @override
  Future<int> updateActivity(ActivityModel activity) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final updated = activity.copyWith(updatedAt: now);

    return await db.update(
      DbConstants.tableActivities,
      updated.toMap(),
      where: '${DbConstants.colActId} = ?',
      whereArgs: [activity.id],
    );
  }

  @override
  Future<int> deleteActivity(int activityId) async {
    final db = await _dbHelper.database;
    // Foreign key with CASCADE removes occurrences
    return await db.delete(
      DbConstants.tableActivities,
      where: '${DbConstants.colActId} = ?',
      whereArgs: [activityId],
    );
  }

  @override
  Future<ActivityModel?> getActivityById(int activityId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DbConstants.tableActivities,
      where: '${DbConstants.colActId} = ?',
      whereArgs: [activityId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return ActivityModel.fromMap(results.first);
  }

  @override
  Future<List<ActivityModel>> getAllActivities({
    bool onlyActive = false,
  }) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DbConstants.tableActivities,
      where: onlyActive ? '${DbConstants.colActIsActive} = 1' : null,
      orderBy: '${DbConstants.colActId} ASC',
    );

    return results.map(ActivityModel.fromMap).toList();
  }

  @override
  Future<List<ActivityOccurrenceModel>> getOccurrencesForDate(
    String isoDate,
  ) async {
    return await _dbHelper.runInTransaction<List<ActivityOccurrenceModel>>((
      txn,
    ) async {
      final dateObj = AppDateUtils.fromIsoDate(isoDate);
      final isWeekday =
          dateObj.weekday >= DateTime.monday &&
          dateObj.weekday <= DateTime.friday;

      // 1. Check all active activities
      final activeActivities = await txn.query(
        DbConstants.tableActivities,
        where: '${DbConstants.colActIsActive} = 1',
      );

      final now = DateTime.now().toIso8601String();

      for (final raw in activeActivities) {
        final activity = ActivityModel.fromMap(raw);
        final frequency = activity.targetFrequency;

        bool shouldOccur = false;
        if (frequency == AppConstants.frequencyDaily) {
          shouldOccur = true;
        } else if (frequency == AppConstants.frequencyWeekdays && isWeekday) {
          shouldOccur = true;
        } else {
          shouldOccur = true;
        }

        if (shouldOccur && activity.id != null) {
          await txn.insert(DbConstants.tableActivityOccurrences, {
            DbConstants.colActOccActivityId: activity.id,
            DbConstants.colActOccDate: isoDate,
            DbConstants.colActOccIsCompleted: 0,
            DbConstants.colActOccActualValue: 0,
            DbConstants.colActOccCompletedAt: null,
            DbConstants.colActOccNotes: null,
            DbConstants.colActOccCreatedAt: now,
            DbConstants.colActOccUpdatedAt: now,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }

      // 2. Fetch occurrences with joined activity metadata
      final query =
          '''
        SELECT 
          o.${DbConstants.colActOccId},
          o.${DbConstants.colActOccActivityId},
          o.${DbConstants.colActOccDate},
          o.${DbConstants.colActOccIsCompleted},
          o.${DbConstants.colActOccActualValue},
          o.${DbConstants.colActOccCompletedAt},
          o.${DbConstants.colActOccNotes},
          o.${DbConstants.colActOccCreatedAt},
          o.${DbConstants.colActOccUpdatedAt},
          a.${DbConstants.colActTitle} AS activity_title,
          a.${DbConstants.colActDescription} AS activity_description,
          a.${DbConstants.colActCategory},
          a.${DbConstants.colActIcon},
          a.${DbConstants.colActColor},
          a.${DbConstants.colActTargetValue},
          a.${DbConstants.colActUnit}
        FROM ${DbConstants.tableActivityOccurrences} o
        INNER JOIN ${DbConstants.tableActivities} a ON o.${DbConstants.colActOccActivityId} = a.${DbConstants.colActId}
        WHERE o.${DbConstants.colActOccDate} = ?
        ORDER BY o.${DbConstants.colActOccIsCompleted} ASC, o.${DbConstants.colActOccId} ASC
      ''';

      final results = await txn.rawQuery(query, [isoDate]);
      return results.map(ActivityOccurrenceModel.fromMap).toList();
    });
  }

  @override
  Future<List<ActivityOccurrenceModel>> getOccurrencesBetween(
    String startDate,
    String endDate,
  ) async {
    final db = await _dbHelper.database;
    final query =
        '''
      SELECT 
        o.${DbConstants.colActOccId},
        o.${DbConstants.colActOccActivityId},
        o.${DbConstants.colActOccDate},
        o.${DbConstants.colActOccIsCompleted},
        o.${DbConstants.colActOccActualValue},
        o.${DbConstants.colActOccCompletedAt},
        o.${DbConstants.colActOccNotes},
        o.${DbConstants.colActOccCreatedAt},
        o.${DbConstants.colActOccUpdatedAt},
        a.${DbConstants.colActTitle} AS activity_title,
        a.${DbConstants.colActDescription} AS activity_description,
        a.${DbConstants.colActCategory},
        a.${DbConstants.colActIcon},
        a.${DbConstants.colActColor},
        a.${DbConstants.colActTargetValue},
        a.${DbConstants.colActUnit}
      FROM ${DbConstants.tableActivityOccurrences} o
      INNER JOIN ${DbConstants.tableActivities} a ON o.${DbConstants.colActOccActivityId} = a.${DbConstants.colActId}
      WHERE o.${DbConstants.colActOccDate} BETWEEN ? AND ?
      ORDER BY o.${DbConstants.colActOccDate} ASC, o.${DbConstants.colActOccIsCompleted} ASC
    ''';

    final results = await db.rawQuery(query, [startDate, endDate]);
    return results.map(ActivityOccurrenceModel.fromMap).toList();
  }

  @override
  Future<int> setOccurrenceCompletion(
    int occurrenceId,
    bool isCompleted,
  ) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    return await db.update(
      DbConstants.tableActivityOccurrences,
      {
        DbConstants.colActOccIsCompleted: isCompleted ? 1 : 0,
        DbConstants.colActOccCompletedAt: isCompleted ? now : null,
        DbConstants.colActOccUpdatedAt: now,
      },
      where: '${DbConstants.colActOccId} = ?',
      whereArgs: [occurrenceId],
    );
  }

  @override
  Future<int> skipOccurrence(int occurrenceId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    return await db.update(
      DbConstants.tableActivityOccurrences,
      {
        DbConstants.colActOccIsCompleted: 0,
        DbConstants.colActOccCompletedAt: null,
        DbConstants.colActOccNotes: 'Skipped',
        DbConstants.colActOccUpdatedAt: now,
      },
      where: '${DbConstants.colActOccId} = ?',
      whereArgs: [occurrenceId],
    );
  }

  @override
  Future<int> updateOccurrenceValue(
    int occurrenceId,
    int actualValue,
    int targetValue,
  ) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final isCompleted = actualValue >= targetValue;

    return await db.update(
      DbConstants.tableActivityOccurrences,
      {
        DbConstants.colActOccActualValue: actualValue,
        DbConstants.colActOccIsCompleted: isCompleted ? 1 : 0,
        DbConstants.colActOccCompletedAt: isCompleted ? now : null,
        DbConstants.colActOccUpdatedAt: now,
      },
      where: '${DbConstants.colActOccId} = ?',
      whereArgs: [occurrenceId],
    );
  }

  @override
  Future<int> getCompletedCountForDate(String isoDate) async {
    final db = await _dbHelper.database;
    final result = Sqflite.firstIntValue(
      await db.rawQuery(
        '''
      SELECT COUNT(*) FROM ${DbConstants.tableActivityOccurrences}
      WHERE ${DbConstants.colActOccDate} = ? AND ${DbConstants.colActOccIsCompleted} = 1
      ''',
        [isoDate],
      ),
    );
    return result ?? 0;
  }

  @override
  Future<int> getTotalCountForDate(String isoDate) async {
    final db = await _dbHelper.database;
    final result = Sqflite.firstIntValue(
      await db.rawQuery(
        '''
      SELECT COUNT(*) FROM ${DbConstants.tableActivityOccurrences}
      WHERE ${DbConstants.colActOccDate} = ?
      ''',
        [isoDate],
      ),
    );
    return result ?? 0;
  }
}
