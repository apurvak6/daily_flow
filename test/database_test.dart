import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daily_flow/core/constants/app_constants.dart';
import 'package:daily_flow/core/constants/db_constants.dart';
import 'package:daily_flow/core/database/database_helper.dart';
import 'package:daily_flow/data/datasources/activity_local_datasource.dart';
import 'package:daily_flow/data/datasources/task_local_datasource.dart';
import 'package:daily_flow/data/models/activity_model.dart';
import 'package:daily_flow/data/models/task_model.dart';
import 'package:daily_flow/data/repositories/activity_repository.dart';
import 'package:daily_flow/data/repositories/task_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late TaskRepository taskRepository;
  late ActivityRepository activityRepository;

  setUp(() async {
    // Open a fresh in-memory SQLite database for testing
    db = await openDatabase(
      inMemoryDatabasePath,
      version: DbConstants.databaseVersion,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (database, version) async {
        await DatabaseHelper.createSchema(database);
      },
    );

    DatabaseHelper.setDatabaseForTesting(db);
    final taskDs = TaskLocalDataSourceImpl(dbHelper: DatabaseHelper.instance);
    taskRepository = TaskRepositoryImpl(dataSource: taskDs);

    final actDs = ActivityLocalDataSourceImpl(
      dbHelper: DatabaseHelper.instance,
    );
    activityRepository = ActivityRepositoryImpl(dataSource: actDs);
  });

  tearDown(() async {
    await db.close();
    DatabaseHelper.setDatabaseForTesting(null);
  });

  test('Database Schema Verification: All 4 tables exist', () async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';",
    );
    final tableNames = tables.map((t) => t['name'] as String).toSet();

    expect(tableNames, contains(DbConstants.tableTasks));
    expect(tableNames, contains(DbConstants.tableTaskOccurrences));
    expect(tableNames, contains(DbConstants.tableActivities));
    expect(tableNames, contains(DbConstants.tableActivityOccurrences));
  });

  test(
    'Foreign key constraint verification: CASCADE on Task deletion',
    () async {
      final taskId = await taskRepository.createTask(
        TaskModel(title: 'Review PR', dueDate: '2026-11-16'),
      );

      final occurrencesBefore = await taskRepository.getOccurrencesForDate(
        '2026-11-16',
      );
      expect(occurrencesBefore.length, 1);

      // Delete master task
      await taskRepository.deleteTask(taskId);

      // Occurrences must be automatically deleted due to ON DELETE CASCADE
      final occurrencesAfter = await taskRepository.getOccurrencesForDate(
        '2026-11-16',
      );
      expect(occurrencesAfter.isEmpty, isTrue);
    },
  );

  test(
    'Unique constraint: cannot insert duplicate occurrence for same task and date',
    () async {
      final taskId = await taskRepository.createTask(
        TaskModel(title: 'Team Standup', dueDate: '2026-11-16'),
      );

      // Attempting raw duplicate insert must fail due to UNIQUE constraint
      expect(
        () async => await db.insert(DbConstants.tableTaskOccurrences, {
          DbConstants.colOccTaskId: taskId,
          DbConstants.colOccDate: '2026-11-16',
          DbConstants.colOccIsCompleted: 0,
          DbConstants.colOccCreatedAt: DateTime.now().toIso8601String(),
          DbConstants.colOccUpdatedAt: DateTime.now().toIso8601String(),
        }),
        throwsA(isA<DatabaseException>()),
      );
    },
  );

  test('Recurring Task occurrence generation & date isolation', () async {
    // Create a daily recurring task
    final taskId = await taskRepository.createTask(
      TaskModel(
        title: 'Daily Meditation',
        isRecurring: true,
        recurrenceType: AppConstants.recurrenceDaily,
      ),
    );

    // Query date 1
    final day1Occurrences = await taskRepository.getOccurrencesForDate(
      '2026-11-16',
    );
    expect(day1Occurrences.any((o) => o.taskId == taskId), isTrue);
    final occ1 = day1Occurrences.firstWhere((o) => o.taskId == taskId);

    // Mark completed on Day 1
    await taskRepository.toggleOccurrenceCompletion(occ1.id!, true);

    final day1Updated = await taskRepository.getOccurrencesForDate(
      '2026-11-16',
    );
    expect(
      day1Updated.firstWhere((o) => o.taskId == taskId).isCompleted,
      isTrue,
    );

    // Query date 2 (Day 2)
    final day2Occurrences = await taskRepository.getOccurrencesForDate(
      '2026-11-17',
    );
    expect(day2Occurrences.any((o) => o.taskId == taskId), isTrue);
    final occ2 = day2Occurrences.firstWhere((o) => o.taskId == taskId);

    // Day 2 must remain pending (not completed) - verifying complete date isolation
    expect(occ2.isCompleted, isFalse);

    // Day 1 must still be completed
    final day1Check = await taskRepository.getOccurrencesForDate('2026-11-16');
    expect(day1Check.firstWhere((o) => o.taskId == taskId).isCompleted, isTrue);
  });

  test('No duplicate occurrences when revisiting a date', () async {
    await taskRepository.createTask(
      TaskModel(
        title: 'Workout',
        isRecurring: true,
        recurrenceType: AppConstants.recurrenceDaily,
      ),
    );

    final firstCall = await taskRepository.getOccurrencesForDate('2026-11-16');
    final secondCall = await taskRepository.getOccurrencesForDate('2026-11-16');
    final thirdCall = await taskRepository.getOccurrencesForDate('2026-11-16');

    expect(firstCall.length, secondCall.length);
    expect(secondCall.length, thirdCall.length);
  });

  test('Activity Repository CRUD & Progress Logging', () async {
    final actId = await activityRepository.createActivity(
      ActivityModel(title: 'Drink 2L Water', targetValue: 8, unit: 'glasses'),
    );

    final occurrences = await activityRepository.getOccurrencesForDate(
      '2026-11-16',
    );
    expect(occurrences.any((o) => o.activityId == actId), isTrue);
    final occ = occurrences.firstWhere((o) => o.activityId == actId);
    expect(occ.actualValue, 0);
    expect(occ.isCompleted, isFalse);

    // Log progress: 4 glasses (below target of 8)
    await activityRepository.logOccurrenceProgress(occ.id!, 4, 8);
    final updatedOcc1 = (await activityRepository.getOccurrencesForDate(
      '2026-11-16',
    )).firstWhere((o) => o.activityId == actId);
    expect(updatedOcc1.actualValue, 4);
    expect(updatedOcc1.isCompleted, isFalse);

    // Log progress: 8 glasses (reaches target)
    await activityRepository.logOccurrenceProgress(occ.id!, 8, 8);
    final updatedOcc2 = (await activityRepository.getOccurrencesForDate(
      '2026-11-16',
    )).firstWhere((o) => o.activityId == actId);
    expect(updatedOcc2.actualValue, 8);
    expect(updatedOcc2.isCompleted, isTrue);
  });

  test(
    'Non-recurring task completion synchronizes master task record',
    () async {
      final taskId = await taskRepository.createTask(
        TaskModel(
          title: 'Single Assignment',
          dueDate: '2026-11-16',
          isRecurring: false,
        ),
      );

      final occurrences = await taskRepository.getOccurrencesForDate(
        '2026-11-16',
      );
      final occ = occurrences.firstWhere((o) => o.taskId == taskId);

      // Complete the occurrence
      await taskRepository.toggleOccurrenceCompletion(occ.id!, true);

      // Check that master task record is updated
      final masterTask = await taskRepository.getTaskById(taskId);
      expect(masterTask, isNotNull);
      expect(masterTask!.isCompleted, isTrue);
    },
  );

  test(
    'Non-recurring task completion synchronizes master task record',
    () async {
      final taskId = await taskRepository.createTask(
        TaskModel(
          title: 'Single Assignment',
          dueDate: '2026-11-16',
          isRecurring: false,
        ),
      );

      final occurrences = await taskRepository.getOccurrencesForDate(
        '2026-11-16',
      );
      final occ = occurrences.firstWhere((o) => o.taskId == taskId);

      // Complete the occurrence
      await taskRepository.toggleOccurrenceCompletion(occ.id!, true);

      // Check that master task record is updated
      final masterTask = await taskRepository.getTaskById(taskId);
      expect(masterTask, isNotNull);
      expect(masterTask!.isCompleted, isTrue);
    },
  );
}
