import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daily_flow/core/constants/app_constants.dart';
import 'package:daily_flow/core/constants/db_constants.dart';
import 'package:daily_flow/core/database/database_helper.dart';
import 'package:daily_flow/data/datasources/activity_local_datasource.dart';
import 'package:daily_flow/data/datasources/settings_local_datasource.dart';
import 'package:daily_flow/data/datasources/task_local_datasource.dart';
import 'package:daily_flow/data/models/activity_model.dart';
import 'package:daily_flow/data/models/task_model.dart';
import 'package:daily_flow/data/repositories/activity_repository.dart';
import 'package:daily_flow/data/repositories/settings_repository.dart';
import 'package:daily_flow/data/repositories/task_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late TaskRepository taskRepository;
  late ActivityRepository activityRepository;
  late SettingsRepository settingsRepository;

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

    final settingsDs = SettingsLocalDataSourceImpl(
      dbHelper: DatabaseHelper.instance,
    );
    settingsRepository = SettingsRepositoryImpl(dataSource: settingsDs);
  });

  tearDown(() async {
    await db.close();
    DatabaseHelper.setDatabaseForTesting(null);
  });

  test('Database Schema Verification: All 5 tables exist', () async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';",
    );
    final tableNames = tables.map((t) => t['name'] as String).toSet();

    expect(tableNames, contains(DbConstants.tableTasks));
    expect(tableNames, contains(DbConstants.tableTaskOccurrences));
    expect(tableNames, contains(DbConstants.tableActivities));
    expect(tableNames, contains(DbConstants.tableActivityOccurrences));
    expect(tableNames, contains(DbConstants.tableAppSettings));
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

  test('Overdue and upcoming tasks are accurately queried', () async {
    // 1. Task in past (overdue)
    await taskRepository.createTask(
      TaskModel(
        title: 'Past Overdue Task',
        dueDate: '2026-11-10',
        isRecurring: false,
      ),
    );

    // 2. Task in future (upcoming)
    await taskRepository.createTask(
      TaskModel(
        title: 'Future Upcoming Task',
        dueDate: '2026-11-25',
        isRecurring: false,
      ),
    );

    final overdueTasks = await taskRepository.getOverdueOccurrences(
      '2026-11-18',
    );
    expect(overdueTasks.any((t) => t.taskTitle == 'Past Overdue Task'), isTrue);

    final upcomingTasks = await taskRepository.getUpcomingOccurrences(
      '2026-11-18',
    );
    expect(
      upcomingTasks.any((t) => t.taskTitle == 'Future Upcoming Task'),
      isTrue,
    );

    final overdueCount = await taskRepository.getOverdueCount('2026-11-18');
    expect(overdueCount >= 1, isTrue);
  });

  test(
    'updateTask modifies master task and shifts pending occurrence date',
    () async {
      final taskId = await taskRepository.createTask(
        TaskModel(
          title: 'Initial Title',
          dueDate: '2026-11-18',
          priority: AppConstants.priorityLow,
          isRecurring: false,
        ),
      );

      final initialOccurrences = await taskRepository.getOccurrencesForDate(
        '2026-11-18',
      );
      expect(initialOccurrences.any((o) => o.taskId == taskId), isTrue);

      // Update task to new title and new date
      final existingTask = await taskRepository.getTaskById(taskId);
      expect(existingTask, isNotNull);

      await taskRepository.updateTask(
        existingTask!.copyWith(
          title: 'Updated Title',
          dueDate: '2026-11-20',
          priority: AppConstants.priorityHigh,
        ),
      );

      // Should no longer be on old date
      final oldDateOccurrences = await taskRepository.getOccurrencesForDate(
        '2026-11-18',
      );
      expect(oldDateOccurrences.any((o) => o.taskId == taskId), isFalse);

      // Should be on new date with updated title and priority
      final newDateOccurrences = await taskRepository.getOccurrencesForDate(
        '2026-11-20',
      );
      expect(newDateOccurrences.any((o) => o.taskId == taskId), isTrue);
      final updatedOcc = newDateOccurrences.firstWhere(
        (o) => o.taskId == taskId,
      );
      expect(updatedOcc.taskTitle, 'Updated Title');
      expect(updatedOcc.priority, AppConstants.priorityHigh);
    },
  );

  test(
    'Settings persistence: ThemeMode defaults to system and persists updates',
    () async {
      // 1. Defaults to system
      final initialTheme = await settingsRepository.getThemeMode();
      expect(initialTheme, ThemeMode.system);

      // 2. Set to Dark and verify retrieval
      await settingsRepository.setThemeMode(ThemeMode.dark);
      final darkTheme = await settingsRepository.getThemeMode();
      expect(darkTheme, ThemeMode.dark);

      // 3. Set to Light and verify retrieval
      await settingsRepository.setThemeMode(ThemeMode.light);
      final lightTheme = await settingsRepository.getThemeMode();
      expect(lightTheme, ThemeMode.light);

      // 4. Set back to System and verify retrieval
      await settingsRepository.setThemeMode(ThemeMode.system);
      final systemTheme = await settingsRepository.getThemeMode();
      expect(systemTheme, ThemeMode.system);
    },
  );

  test('Settings persistence: Notification toggle persists state', () async {
    // 1. Defaults to true
    final initial = await settingsRepository.areNotificationsEnabled();
    expect(initial, isTrue);

    // 2. Disable notifications
    await settingsRepository.setNotificationsEnabled(false);
    final disabled = await settingsRepository.areNotificationsEnabled();
    expect(disabled, isFalse);

    // 3. Re-enable notifications
    await settingsRepository.setNotificationsEnabled(true);
    final enabled = await settingsRepository.areNotificationsEnabled();
    expect(enabled, isTrue);
  });

  test(
    'Database migration v1 -> v2 creates app_settings table seamlessly',
    () async {
      final dbFolder = await getDatabasesPath();
      final tempPath = join(dbFolder, 'test_v1_v2_migration.db');

      // Ensure clean state before test
      if (await databaseFactory.databaseExists(tempPath)) {
        await databaseFactory.deleteDatabase(tempPath);
      }

      // Open a database at version 1 with only the v1 tables
      final v1Db = await openDatabase(
        tempPath,
        version: 1,
        onCreate: (database, version) async {
          // v1 schema without app_settings
          await database.execute('''
          CREATE TABLE ${DbConstants.tableTasks} (
            ${DbConstants.colTaskId} INTEGER PRIMARY KEY AUTOINCREMENT,
            ${DbConstants.colTaskTitle} TEXT NOT NULL,
            ${DbConstants.colTaskDescription} TEXT,
            ${DbConstants.colTaskPriority} TEXT NOT NULL DEFAULT 'medium',
            ${DbConstants.colTaskCategory} TEXT DEFAULT 'Personal',
            ${DbConstants.colTaskDueDate} TEXT,
            ${DbConstants.colTaskDueTime} TEXT,
            ${DbConstants.colTaskIsRecurring} INTEGER NOT NULL DEFAULT 0,
            ${DbConstants.colTaskRecurrenceType} TEXT DEFAULT 'none',
            ${DbConstants.colTaskIsCompleted} INTEGER NOT NULL DEFAULT 0,
            ${DbConstants.colTaskReminderTime} TEXT,
            ${DbConstants.colTaskCreatedAt} TEXT NOT NULL,
            ${DbConstants.colTaskUpdatedAt} TEXT NOT NULL
          );
        ''');
        },
      );

      // Verify app_settings does not exist in v1
      var tables = await v1Db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='${DbConstants.tableAppSettings}';",
      );
      expect(tables.isEmpty, isTrue);
      await v1Db.close();

      // Reopen with version 2 triggering upgrade
      final v2Db = await openDatabase(
        tempPath,
        version: 2,
        onUpgrade: (database, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await database.execute('''
            CREATE TABLE IF NOT EXISTS ${DbConstants.tableAppSettings} (
              ${DbConstants.colSettingKey} TEXT PRIMARY KEY,
              ${DbConstants.colSettingValue} TEXT NOT NULL
            );
          ''');
          }
        },
      );

      // Verify app_settings now exists and works
      tables = await v2Db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='${DbConstants.tableAppSettings}';",
      );
      expect(tables.isNotEmpty, isTrue);

      // Verify write and read in newly migrated table
      await v2Db.insert(DbConstants.tableAppSettings, {
        DbConstants.colSettingKey: DbConstants.prefThemeMode,
        DbConstants.colSettingValue: 'dark',
      });

      final records = await v2Db.query(
        DbConstants.tableAppSettings,
        where: '${DbConstants.colSettingKey} = ?',
        whereArgs: [DbConstants.prefThemeMode],
      );
      expect(records.first[DbConstants.colSettingValue], 'dark');

      await v2Db.close();
      await databaseFactory.deleteDatabase(tempPath);
    },
  );
}
