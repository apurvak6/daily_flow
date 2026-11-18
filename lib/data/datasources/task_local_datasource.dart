import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/db_constants.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/date_utils.dart';
import '../models/task_model.dart';
import '../models/task_occurrence_model.dart';

/// Contract for task SQLite local data access.
abstract class TaskLocalDataSource {
  Future<int> insertTask(TaskModel task);
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
  Future<int> insertOccurrence(TaskOccurrenceModel occurrence);
  Future<int> updateOccurrence(TaskOccurrenceModel occurrence);
  Future<int> setOccurrenceCompletion(int occurrenceId, bool isCompleted);
  Future<int> getCompletedCountForDate(String isoDate);
  Future<int> getTotalCountForDate(String isoDate);
  Future<int> getOverdueCount(String todayIso);
}

/// Implementation of [TaskLocalDataSource] leveraging SQLite through [DatabaseHelper].
class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final DatabaseHelper _dbHelper;

  TaskLocalDataSourceImpl({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<int> insertTask(TaskModel task) async {
    return await _dbHelper.runInTransaction<int>((txn) async {
      final trimmedTitle = task.title.trim();

      // Guard against duplicate recurring and one-time tasks
      if (task.isRecurring) {
        // Recurring tasks repeat across dates; duplicate check is based on title and recurring flag
        final dupCheck = await txn.query(
          DbConstants.tableTasks,
          where:
              'LOWER(TRIM(${DbConstants.colTaskTitle})) = LOWER(?) AND ${DbConstants.colTaskIsRecurring} = 1',
          whereArgs: [trimmedTitle],
          limit: 1,
        );
        if (dupCheck.isNotEmpty) {
          AppLogger.warning(
            'Duplicate recurring task detected: "$trimmedTitle". Insertion aborted.',
            'TaskLocalDataSource',
          );
          return -1;
        }
      } else {
        // One-time tasks: duplicate check is based on title, due date and non-recurring flag
        final targetDate = task.dueDate ?? AppDateUtils.todayIso;
        final dupCheck = await txn.query(
          DbConstants.tableTasks,
          where:
              'LOWER(TRIM(${DbConstants.colTaskTitle})) = LOWER(?) AND ${DbConstants.colTaskDueDate} = ? AND ${DbConstants.colTaskIsRecurring} = 0',
          whereArgs: [trimmedTitle, targetDate],
          limit: 1,
        );
        if (dupCheck.isNotEmpty) {
          AppLogger.warning(
            'Duplicate one-time task detected: "$trimmedTitle" on $targetDate. Insertion aborted.',
            'TaskLocalDataSource',
          );
          return -1;
        }
      }

      final now = DateTime.now().toIso8601String();
      final taskMap = task
          .copyWith(title: trimmedTitle, createdAt: now, updatedAt: now)
          .toMap();

      final taskId = await txn.insert(DbConstants.tableTasks, taskMap);

      // If the task has a due date or is recurring, create initial occurrence for its due date/today
      final targetDate = task.dueDate ?? AppDateUtils.todayIso;
      final occurrence = TaskOccurrenceModel(
        taskId: taskId,
        occurrenceDate: targetDate,
        isCompleted: task.isCompleted,
        createdAt: now,
        updatedAt: now,
      );

      await txn.insert(
        DbConstants.tableTaskOccurrences,
        occurrence.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      AppLogger.info(
        'Inserted task #$taskId with initial occurrence for $targetDate',
        'TaskLocalDataSource',
      );
      return taskId;
    });
  }

  @override
  Future<int> updateTask(TaskModel task) async {
    return await _dbHelper.runInTransaction<int>((txn) async {
      final trimmedTitle = task.title.trim();

      // Guard against renaming to another existing recurring task
      if (task.isRecurring && task.id != null) {
        final dupCheck = await txn.query(
          DbConstants.tableTasks,
          where:
              'LOWER(TRIM(${DbConstants.colTaskTitle})) = LOWER(?) AND ${DbConstants.colTaskIsRecurring} = 1 AND ${DbConstants.colTaskId} != ?',
          whereArgs: [trimmedTitle, task.id],
          limit: 1,
        );
        if (dupCheck.isNotEmpty) {
          AppLogger.warning(
            'Duplicate recurring task detected on update: "$trimmedTitle". Update aborted.',
            'TaskLocalDataSource',
          );
          return -1;
        }
      }

      final now = DateTime.now().toIso8601String();
      final updatedTask = task.copyWith(
        title: trimmedTitle,
        updatedAt: now,
      );

      final count = await txn.update(
        DbConstants.tableTasks,
        updatedTask.toMap(),
        where: '${DbConstants.colTaskId} = ?',
        whereArgs: [task.id],
      );

      // -------------------------------------------------------------
      // 1️⃣  Handle a *change* in the `isRecurring` flag
      // -------------------------------------------------------------
      final oldTask = await txn.query(
        DbConstants.tableTasks,
        columns: [DbConstants.colTaskIsRecurring],
        where: '${DbConstants.colTaskId} = ?',
        whereArgs: [task.id],
        limit: 1,
      );
      final wasRecurring =
          (oldTask.first[DbConstants.colTaskIsRecurring] as int) == 1;

      if (wasRecurring && !task.isRecurring) {
        // The task just became *non‑recurring*: delete all future
        // occurrences that are still pending (keep the already‑completed
        // ones for history).
        await txn.delete(
          DbConstants.tableTaskOccurrences,
          where:
              '${DbConstants.colOccTaskId} = ? AND ${DbConstants.colOccDate} > ? AND ${DbConstants.colOccIsCompleted} = 0',
          whereArgs: [task.id, AppDateUtils.todayIso],
        );
      }
      // -------------------------------------------------------------
      // 2️⃣  If the task turned *recurring* we don’t need to do anything
      //     now – future occurrences will be created lazily when a date
      //     is requested (the existing INSERT‑IGNORE logic already avoids
      //     duplicates).
      // -------------------------------------------------------------

      // If task is non-recurring and dueDate changed, update uncompleted occurrence date
      if (!task.isRecurring && task.dueDate != null && task.id != null) {
        await txn.update(
          DbConstants.tableTaskOccurrences,
          {
            DbConstants.colOccDate: task.dueDate!,
            DbConstants.colOccUpdatedAt: now,
          },
          where:
              '${DbConstants.colOccTaskId} = ? AND ${DbConstants.colOccIsCompleted} = 0',
          whereArgs: [task.id],
        );
      }

      return count;
    });
  }

  @override
  Future<int> deleteTask(int taskId) async {
    final db = await _dbHelper.database;
    // Foreign key with ON DELETE CASCADE automatically removes related occurrences
    return await db.delete(
      DbConstants.tableTasks,
      where: '${DbConstants.colTaskId} = ?',
      whereArgs: [taskId],
    );
  }

  @override
  Future<TaskModel?> getTaskById(int taskId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DbConstants.tableTasks,
      where: '${DbConstants.colTaskId} = ?',
      whereArgs: [taskId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return TaskModel.fromMap(results.first);
  }

  @override
  Future<List<TaskModel>> getAllTasks() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DbConstants.tableTasks,
      orderBy:
          '${DbConstants.colTaskDueDate} ASC, ${DbConstants.colTaskId} DESC',
    );

    return results.map(TaskModel.fromMap).toList();
  }

  @override
  Future<List<TaskOccurrenceModel>> getOccurrencesForDate(
    String isoDate,
  ) async {
    return await _dbHelper.runInTransaction<List<TaskOccurrenceModel>>((
      txn,
    ) async {
      final dateObj = AppDateUtils.fromIsoDate(isoDate);
      final isWeekday =
          dateObj.weekday >= DateTime.monday &&
          dateObj.weekday <= DateTime.friday;

      // 1. Identify recurring tasks that should occur on this date
      final recurringTasks = await txn.query(
        DbConstants.tableTasks,
        where: '${DbConstants.colTaskIsRecurring} = 1',
      );

      final now = DateTime.now().toIso8601String();

      for (final rawTask in recurringTasks) {
        final task = TaskModel.fromMap(rawTask);
        final recurrenceType = task.recurrenceType;

        bool shouldOccur = false;
        if (recurrenceType == AppConstants.recurrenceDaily) {
          shouldOccur = true;
        } else if (recurrenceType == AppConstants.recurrenceWeekdays &&
            isWeekday) {
          shouldOccur = true;
        } else if (recurrenceType == AppConstants.recurrenceWeekly &&
            task.dueDate != null) {
          final due = AppDateUtils.fromIsoDate(task.dueDate!);
          shouldOccur = due.weekday == dateObj.weekday;
        }

        if (shouldOccur && task.id != null) {
          // INSERT OR IGNORE guarantees no duplicate creation
          await txn.insert(DbConstants.tableTaskOccurrences, {
            DbConstants.colOccTaskId: task.id,
            DbConstants.colOccDate: isoDate,
            DbConstants.colOccIsCompleted: 0,
            DbConstants.colOccCompletedAt: null,
            DbConstants.colOccNotes: null,
            DbConstants.colOccCreatedAt: now,
            DbConstants.colOccUpdatedAt: now,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }

      // 2. Fetch all occurrences for this date with joined task metadata
      final query =
          '''
        SELECT 
          o.${DbConstants.colOccId},
          o.${DbConstants.colOccTaskId},
          o.${DbConstants.colOccDate},
          o.${DbConstants.colOccIsCompleted},
          o.${DbConstants.colOccCompletedAt},
          o.${DbConstants.colOccNotes},
          o.${DbConstants.colOccCreatedAt},
          o.${DbConstants.colOccUpdatedAt},
          t.${DbConstants.colTaskTitle} AS task_title,
          t.${DbConstants.colTaskDescription} AS task_description,
          t.${DbConstants.colTaskPriority},
          t.${DbConstants.colTaskCategory},
          t.${DbConstants.colTaskDueTime},
          t.${DbConstants.colTaskIsRecurring}
        FROM ${DbConstants.tableTaskOccurrences} o
        INNER JOIN ${DbConstants.tableTasks} t ON o.${DbConstants.colOccTaskId} = t.${DbConstants.colTaskId}
        WHERE o.${DbConstants.colOccDate} = ?
        ORDER BY o.${DbConstants.colOccIsCompleted} ASC, t.${DbConstants.colTaskDueTime} ASC, o.${DbConstants.colOccId} ASC
      ''';

      final results = await txn.rawQuery(query, [isoDate]);
      return results.map(TaskOccurrenceModel.fromMap).toList();
    });
  }

  @override
  Future<List<TaskOccurrenceModel>> getOccurrencesBetween(
    String startDate,
    String endDate,
  ) async {
    final db = await _dbHelper.database;
    final query =
        '''
      SELECT 
        o.${DbConstants.colOccId},
        o.${DbConstants.colOccTaskId},
        o.${DbConstants.colOccDate},
        o.${DbConstants.colOccIsCompleted},
        o.${DbConstants.colOccCompletedAt},
        o.${DbConstants.colOccNotes},
        o.${DbConstants.colOccCreatedAt},
        o.${DbConstants.colOccUpdatedAt},
        t.${DbConstants.colTaskTitle} AS task_title,
        t.${DbConstants.colTaskDescription} AS task_description,
        t.${DbConstants.colTaskPriority},
        t.${DbConstants.colTaskCategory},
        t.${DbConstants.colTaskDueTime},
        t.${DbConstants.colTaskIsRecurring}
      FROM ${DbConstants.tableTaskOccurrences} o
      INNER JOIN ${DbConstants.tableTasks} t ON o.${DbConstants.colOccTaskId} = t.${DbConstants.colTaskId}
      WHERE o.${DbConstants.colOccDate} BETWEEN ? AND ?
      ORDER BY o.${DbConstants.colOccDate} ASC, o.${DbConstants.colOccIsCompleted} ASC
    ''';

    final results = await db.rawQuery(query, [startDate, endDate]);
    return results.map(TaskOccurrenceModel.fromMap).toList();
  }

  @override
  Future<List<TaskOccurrenceModel>> getOverdueOccurrences(
    String todayIso,
  ) async {
    final db = await _dbHelper.database;
    final query =
        '''
      SELECT 
        o.${DbConstants.colOccId},
        o.${DbConstants.colOccTaskId},
        o.${DbConstants.colOccDate},
        o.${DbConstants.colOccIsCompleted},
        o.${DbConstants.colOccCompletedAt},
        o.${DbConstants.colOccNotes},
        o.${DbConstants.colOccCreatedAt},
        o.${DbConstants.colOccUpdatedAt},
        t.${DbConstants.colTaskTitle} AS task_title,
        t.${DbConstants.colTaskDescription} AS task_description,
        t.${DbConstants.colTaskPriority},
        t.${DbConstants.colTaskCategory},
        t.${DbConstants.colTaskDueTime},
        t.${DbConstants.colTaskIsRecurring}
      FROM ${DbConstants.tableTaskOccurrences} o
      INNER JOIN ${DbConstants.tableTasks} t ON o.${DbConstants.colOccTaskId} = t.${DbConstants.colTaskId}
      WHERE o.${DbConstants.colOccDate} < ? AND o.${DbConstants.colOccIsCompleted} = 0
      ORDER BY o.${DbConstants.colOccDate} DESC, t.${DbConstants.colTaskDueTime} ASC
    ''';

    final results = await db.rawQuery(query, [todayIso]);
    return results.map(TaskOccurrenceModel.fromMap).toList();
  }

  @override
  Future<List<TaskOccurrenceModel>> getUpcomingOccurrences(
    String fromIsoDate, {
    int limit = 10,
  }) async {
    final db = await _dbHelper.database;
    final query =
        '''
      SELECT 
        o.${DbConstants.colOccId},
        o.${DbConstants.colOccTaskId},
        o.${DbConstants.colOccDate},
        o.${DbConstants.colOccIsCompleted},
        o.${DbConstants.colOccCompletedAt},
        o.${DbConstants.colOccNotes},
        o.${DbConstants.colOccCreatedAt},
        o.${DbConstants.colOccUpdatedAt},
        t.${DbConstants.colTaskTitle} AS task_title,
        t.${DbConstants.colTaskDescription} AS task_description,
        t.${DbConstants.colTaskPriority},
        t.${DbConstants.colTaskCategory},
        t.${DbConstants.colTaskDueTime},
        t.${DbConstants.colTaskIsRecurring}
      FROM ${DbConstants.tableTaskOccurrences} o
      INNER JOIN ${DbConstants.tableTasks} t ON o.${DbConstants.colOccTaskId} = t.${DbConstants.colTaskId}
      WHERE o.${DbConstants.colOccDate} > ? AND o.${DbConstants.colOccIsCompleted} = 0
      ORDER BY o.${DbConstants.colOccDate} ASC, t.${DbConstants.colTaskDueTime} ASC
      LIMIT ?
    ''';

    final results = await db.rawQuery(query, [fromIsoDate, limit]);
    return results.map(TaskOccurrenceModel.fromMap).toList();
  }

  @override
  Future<int> insertOccurrence(TaskOccurrenceModel occurrence) async {
    final db = await _dbHelper.database;
    return await db.insert(
      DbConstants.tableTaskOccurrences,
      occurrence.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  @override
  Future<int> updateOccurrence(TaskOccurrenceModel occurrence) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final updated = occurrence.copyWith(updatedAt: now);

    return await db.update(
      DbConstants.tableTaskOccurrences,
      updated.toMap(),
      where: '${DbConstants.colOccId} = ?',
      whereArgs: [occurrence.id],
    );
  }

  @override
  Future<int> setOccurrenceCompletion(
    int occurrenceId,
    bool isCompleted,
  ) async {
    return await _dbHelper.runInTransaction<int>((txn) async {
      final now = DateTime.now().toIso8601String();

      final updated = await txn.update(
        DbConstants.tableTaskOccurrences,
        {
          DbConstants.colOccIsCompleted: isCompleted ? 1 : 0,
          DbConstants.colOccCompletedAt: isCompleted ? now : null,
          DbConstants.colOccUpdatedAt: now,
        },
        where: '${DbConstants.colOccId} = ?',
        whereArgs: [occurrenceId],
      );

      // If this occurrence belongs to a non-recurring task, synchronize master task status
      final occResults = await txn.query(
        DbConstants.tableTaskOccurrences,
        columns: [DbConstants.colOccTaskId],
        where: '${DbConstants.colOccId} = ?',
        whereArgs: [occurrenceId],
        limit: 1,
      );

      if (occResults.isNotEmpty) {
        final taskId = occResults.first[DbConstants.colOccTaskId] as int;
        final taskResults = await txn.query(
          DbConstants.tableTasks,
          columns: [DbConstants.colTaskIsRecurring],
          where: '${DbConstants.colTaskId} = ?',
          whereArgs: [taskId],
          limit: 1,
        );

        if (taskResults.isNotEmpty) {
          final isRecurring =
              (taskResults.first[DbConstants.colTaskIsRecurring] as int? ??
                  0) ==
              1;
          if (!isRecurring) {
            await txn.update(
              DbConstants.tableTasks,
              {
                DbConstants.colTaskIsCompleted: isCompleted ? 1 : 0,
                DbConstants.colTaskUpdatedAt: now,
              },
              where: '${DbConstants.colTaskId} = ?',
              whereArgs: [taskId],
            );
          }
        }
      }

      return updated;
    });
  }

  @override
  Future<int> getCompletedCountForDate(String isoDate) async {
    final db = await _dbHelper.database;
    final result = Sqflite.firstIntValue(
      await db.rawQuery(
        '''
      SELECT COUNT(*) FROM ${DbConstants.tableTaskOccurrences}
      WHERE ${DbConstants.colOccDate} = ? AND ${DbConstants.colOccIsCompleted} = 1
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
      SELECT COUNT(*) FROM ${DbConstants.tableTaskOccurrences}
      WHERE ${DbConstants.colOccDate} = ?
      ''',
        [isoDate],
      ),
    );
    return result ?? 0;
  }

  @override
  Future<int> getOverdueCount(String todayIso) async {
    final db = await _dbHelper.database;
    final result = Sqflite.firstIntValue(
      await db.rawQuery(
        '''
      SELECT COUNT(*) FROM ${DbConstants.tableTaskOccurrences}
      WHERE ${DbConstants.colOccDate} < ? AND ${DbConstants.colOccIsCompleted} = 0
      ''',
        [todayIso],
      ),
    );
    return result ?? 0;
  }
}
