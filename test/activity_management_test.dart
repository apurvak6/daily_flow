import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' hide equals;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daily_flow/core/constants/app_constants.dart';
import 'package:daily_flow/core/constants/db_constants.dart';
import 'package:daily_flow/core/database/database_helper.dart';
import 'package:daily_flow/core/utils/date_utils.dart';
import 'package:daily_flow/data/datasources/activity_local_datasource.dart';
import 'package:daily_flow/data/datasources/task_local_datasource.dart';
import 'package:daily_flow/data/models/activity_model.dart';
import 'package:daily_flow/data/models/task_model.dart';
import 'package:daily_flow/data/repositories/activity_repository.dart';
import 'package:daily_flow/data/repositories/task_repository.dart';
import 'package:daily_flow/modules/calendar/controllers/calendar_controller.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late ActivityLocalDataSource activityDataSource;
  late ActivityRepository activityRepository;
  late TaskLocalDataSource taskDataSource;
  late TaskRepository taskRepository;

  setUp(() async {
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
    activityDataSource = ActivityLocalDataSourceImpl(
      dbHelper: DatabaseHelper.instance,
    );
    activityRepository = ActivityRepositoryImpl(dataSource: activityDataSource);

    taskDataSource = TaskLocalDataSourceImpl(dbHelper: DatabaseHelper.instance);
    taskRepository = TaskRepositoryImpl(dataSource: taskDataSource);
  });

  tearDown(() async {
    await db.close();
    DatabaseHelper.setDatabaseForTesting(null);
  });

  group('Activity Form Validation Rules', () {
    String? validateTitle(String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Activity title is required';
      }
      final trimmed = value.trim();
      if (trimmed.length < 3) {
        return 'Title must be at least 3 characters';
      }
      if (trimmed.length > 60) {
        return 'Title cannot exceed 60 characters';
      }
      return null;
    }

    test('Rejects null, empty, and whitespace-only titles', () {
      expect(validateTitle(null), equals('Activity title is required'));
      expect(validateTitle(''), equals('Activity title is required'));
      expect(validateTitle('   '), equals('Activity title is required'));
      expect(validateTitle('\t \n '), equals('Activity title is required'));
    });

    test('Rejects titles shorter than 3 characters', () {
      expect(validateTitle('a'), equals('Title must be at least 3 characters'));
      expect(
        validateTitle('ab'),
        equals('Title must be at least 3 characters'),
      );
      expect(
        validateTitle('  ab  '),
        equals('Title must be at least 3 characters'),
      );
    });

    test('Accepts valid title lengths (3 to 60 characters)', () {
      expect(validateTitle('Gym'), isNull);
      expect(validateTitle('Morning Medication'), isNull);
      expect(validateTitle('A' * 60), isNull);
    });

    test('Rejects titles longer than 60 characters', () {
      expect(
        validateTitle('A' * 61),
        equals('Title cannot exceed 60 characters'),
      );
    });
  });

  group('Activity CRUD & Persistence', () {
    test(
      'Create activity with all fields and verify database storage',
      () async {
        final activity = ActivityModel(
          title: 'Morning Breakfast',
          description: 'Healthy breakfast with oatmeal and fruit',
          category: 'Food',
          scheduledTime: '08:30 AM',
          isReminderEnabled: true,
          targetFrequency: AppConstants.frequencyDaily,
          isActive: true,
        );

        final actId = await activityRepository.createActivity(activity);
        expect(actId, greaterThan(0));

        final retrieved = await activityRepository.getActivityById(actId);
        expect(retrieved, isNotNull);
        expect(retrieved!.title, 'Morning Breakfast');
        expect(
          retrieved.description,
          'Healthy breakfast with oatmeal and fruit',
        );
        expect(retrieved.category, 'Food');
        expect(retrieved.scheduledTime, '08:30 AM');
        expect(retrieved.isReminderEnabled, isTrue);
        expect(retrieved.targetFrequency, AppConstants.frequencyDaily);
        expect(retrieved.isActive, isTrue);

        // Verify today occurrence was automatically created
        final todayOccurrences = await activityRepository.getOccurrencesForDate(
          AppDateUtils.todayIso,
        );
        expect(todayOccurrences.any((o) => o.activityId == actId), isTrue);
        final occ = todayOccurrences.firstWhere((o) => o.activityId == actId);
        expect(occ.status, 'pending');
        expect(occ.isCompleted, isFalse);
        expect(occ.scheduledTime, '08:30 AM');
        expect(occ.isReminderEnabled, isTrue);
      },
    );

    test('Edit activity details updates master definition', () async {
      final actId = await activityRepository.createActivity(
        ActivityModel(
          title: 'Morning Run',
          category: 'Fitness',
          scheduledTime: '06:00 AM',
        ),
      );

      final original = await activityRepository.getActivityById(actId);
      expect(original, isNotNull);

      final updated = original!.copyWith(
        title: 'Morning Jog & Stretch',
        scheduledTime: '06:30 AM',
        description: '3km light jog',
      );
      await activityRepository.updateActivity(updated);

      final reloaded = await activityRepository.getActivityById(actId);
      expect(reloaded!.title, 'Morning Jog & Stretch');
      expect(reloaded.scheduledTime, '06:30 AM');
      expect(reloaded.description, '3km light jog');
    });

    test(
      'Deactivating activity preserves history and stops new occurrences',
      () async {
        final actId = await activityRepository.createActivity(
          ActivityModel(
            title: 'Evening Meditation',
            category: 'Mindfulness',
            isActive: true,
          ),
        );

        // Verify today occurrence exists
        final todayOccurrences = await activityRepository.getOccurrencesForDate(
          AppDateUtils.todayIso,
        );
        expect(todayOccurrences.any((o) => o.activityId == actId), isTrue);

        // Deactivate activity
        final act = await activityRepository.getActivityById(actId);
        await activityRepository.updateActivity(act!.copyWith(isActive: false));

        final allActive = await activityRepository.getAllActivities(
          onlyActive: true,
        );
        expect(allActive.any((a) => a.id == actId), isFalse);

        final allTotal = await activityRepository.getAllActivities(
          onlyActive: false,
        );
        expect(allTotal.any((a) => a.id == actId), isTrue);
        expect(allTotal.firstWhere((a) => a.id == actId).isActive, isFalse);
      },
    );

    test('Delete activity cascades and removes occurrences', () async {
      final actId = await activityRepository.createActivity(
        ActivityModel(title: 'Short Habit'),
      );

      final occurrencesBefore = await activityRepository.getOccurrencesForDate(
        AppDateUtils.todayIso,
      );
      expect(occurrencesBefore.any((o) => o.activityId == actId), isTrue);

      await activityRepository.deleteActivity(actId);

      final actAfter = await activityRepository.getActivityById(actId);
      expect(actAfter, isNull);

      final occurrencesAfter = await activityRepository.getOccurrencesForDate(
        AppDateUtils.todayIso,
      );
      expect(occurrencesAfter.any((o) => o.activityId == actId), isFalse);
    });

    test('Activity persistence across simulated repository restart', () async {
      final actId = await activityRepository.createActivity(
        ActivityModel(
          title: 'Daily Water Intake',
          category: 'Health',
          scheduledTime: '09:00 AM',
        ),
      );

      final todayOccurrences = await activityRepository.getOccurrencesForDate(
        AppDateUtils.todayIso,
      );
      final occ = todayOccurrences.firstWhere((o) => o.activityId == actId);
      await activityRepository.setOccurrenceStatus(occ.id!, 'completed');

      // Create new repository instance pointing to the same SQLite DB
      final newDataSource = ActivityLocalDataSourceImpl(
        dbHelper: DatabaseHelper.instance,
      );
      final newRepository = ActivityRepositoryImpl(dataSource: newDataSource);

      final reloadedMaster = await newRepository.getActivityById(actId);
      expect(reloadedMaster, isNotNull);
      expect(reloadedMaster!.title, 'Daily Water Intake');

      final reloadedOccurrences = await newRepository.getOccurrencesForDate(
        AppDateUtils.todayIso,
      );
      final reloadedOcc = reloadedOccurrences.firstWhere(
        (o) => o.activityId == actId,
      );
      expect(reloadedOcc.isCompleted, isTrue);
      expect(reloadedOcc.status, 'completed');
    });
  });

  group('Date-wise Occurrence History & Status Isolation', () {
    test(
      'Completing today does not complete tomorrow (strict date isolation)',
      () async {
        final actId = await activityRepository.createActivity(
          ActivityModel(
            title: 'Take Blood Pressure Medication',
            category: 'Medication',
          ),
        );

        const today = '2026-11-18';
        const tomorrow = '2026-11-19';

        // 1. Get occurrences for today and mark Completed
        final todayList = await activityRepository.getOccurrencesForDate(today);
        final todayOcc = todayList.firstWhere((o) => o.activityId == actId);
        expect(todayOcc.status, 'pending');

        await activityRepository.setOccurrenceStatus(todayOcc.id!, 'completed');

        // 2. Query tomorrow
        final tomorrowList = await activityRepository.getOccurrencesForDate(
          tomorrow,
        );
        final tomorrowOcc = tomorrowList.firstWhere(
          (o) => o.activityId == actId,
        );

        // Verify tomorrow remains pending
        expect(tomorrowOcc.status, 'pending');
        expect(tomorrowOcc.isCompleted, isFalse);

        // Verify today remains completed
        final todayRecheck = await activityRepository.getOccurrencesForDate(
          today,
        );
        expect(
          todayRecheck.firstWhere((o) => o.activityId == actId).status,
          'completed',
        );
        expect(
          todayRecheck.firstWhere((o) => o.activityId == actId).isCompleted,
          isTrue,
        );
      },
    );

    test(
      'Skipping today saves status as skipped and does not affect tomorrow',
      () async {
        final actId = await activityRepository.createActivity(
          ActivityModel(title: 'Lunch Meeting', category: 'Meetings'),
        );

        const today = '2026-11-18';
        const tomorrow = '2026-11-19';

        final todayList = await activityRepository.getOccurrencesForDate(today);
        final todayOcc = todayList.firstWhere((o) => o.activityId == actId);

        // Mark as skipped
        await activityRepository.skipOccurrence(todayOcc.id!);

        final todayUpdated = (await activityRepository.getOccurrencesForDate(
          today,
        )).firstWhere((o) => o.activityId == actId);
        expect(todayUpdated.status, 'skipped');
        expect(todayUpdated.isSkipped, isTrue);
        expect(todayUpdated.isCompleted, isFalse);

        // Tomorrow should still be pending
        final tomorrowList = await activityRepository.getOccurrencesForDate(
          tomorrow,
        );
        final tomorrowOcc = tomorrowList.firstWhere(
          (o) => o.activityId == actId,
        );
        expect(tomorrowOcc.status, 'pending');
        expect(tomorrowOcc.isSkipped, isFalse);
      },
    );

    test('Resetting completed/skipped occurrence back to pending', () async {
      final actId = await activityRepository.createActivity(
        ActivityModel(title: 'Read 20 Pages', category: 'Routine'),
      );

      final list = await activityRepository.getOccurrencesForDate('2026-11-18');
      final occ = list.firstWhere((o) => o.activityId == actId);

      await activityRepository.setOccurrenceStatus(occ.id!, 'completed');
      var check = (await activityRepository.getOccurrencesForDate(
        '2026-11-18',
      )).firstWhere((o) => o.activityId == actId);
      expect(check.status, 'completed');

      // Reset to pending
      await activityRepository.setOccurrenceStatus(occ.id!, 'pending');
      check = (await activityRepository.getOccurrencesForDate(
        '2026-11-18',
      )).firstWhere((o) => o.activityId == actId);
      expect(check.status, 'pending');
      expect(check.isCompleted, isFalse);
      expect(check.isSkipped, isFalse);
    });

    test(
      'Duplicate prevention: revisiting same date never creates duplicates',
      () async {
        final actId = await activityRepository.createActivity(
          ActivityModel(title: 'Daily Vitamin C'),
        );

        const testDate = '2026-11-18';

        final firstCall = await activityRepository.getOccurrencesForDate(
          testDate,
        );
        final secondCall = await activityRepository.getOccurrencesForDate(
          testDate,
        );
        final thirdCall = await activityRepository.getOccurrencesForDate(
          testDate,
        );

        expect(firstCall.where((o) => o.activityId == actId).length, 1);
        expect(secondCall.where((o) => o.activityId == actId).length, 1);
        expect(thirdCall.where((o) => o.activityId == actId).length, 1);
      },
    );

    test('Missed & overdue activity identification on past dates', () async {
      final actId = await activityRepository.createActivity(
        ActivityModel(title: 'Morning Walk'),
      );

      // Date in the past (e.g. 2026-11-10)
      const pastDate = '2026-11-10';
      final pastOccurrences = await activityRepository.getOccurrencesForDate(
        pastDate,
      );
      final pastOcc = pastOccurrences.firstWhere((o) => o.activityId == actId);

      // Pending on a past date must be identified as missed/overdue
      expect(pastOcc.isPending, isTrue);
      expect(pastOcc.isMissedOrOverdue, isTrue);

      // If marked completed, it is no longer missed
      await activityRepository.setOccurrenceStatus(pastOcc.id!, 'completed');
      final updatedPast = (await activityRepository.getOccurrencesForDate(
        pastDate,
      )).firstWhere((o) => o.activityId == actId);
      expect(updatedPast.isCompleted, isTrue);
      expect(updatedPast.isMissedOrOverdue, isFalse);
    });

    test(
      'Daily stats calculations reflect completed, skipped, and pending',
      () async {
        final a1 = await activityRepository.createActivity(
          ActivityModel(title: 'Act 1'),
        );
        final a2 = await activityRepository.createActivity(
          ActivityModel(title: 'Act 2'),
        );
        await activityRepository.createActivity(ActivityModel(title: 'Act 3'));

        const testDate = '2026-11-18';
        final occs = await activityRepository.getOccurrencesForDate(testDate);

        final o1 = occs.firstWhere((o) => o.activityId == a1);
        final o2 = occs.firstWhere((o) => o.activityId == a2);

        await activityRepository.setOccurrenceStatus(o1.id!, 'completed');
        await activityRepository.setOccurrenceStatus(o2.id!, 'skipped');

        final stats = await activityRepository.getDailyStats(testDate);
        expect(stats['total'], greaterThanOrEqualTo(3));
        expect(stats['completed'], 1);
        expect(stats['skipped'], 1);
        expect(stats['pending'], greaterThanOrEqualTo(1));
      },
    );
  });

  group('Calendar Event Aggregation & Details Navigation', () {
    test('Calendar queries tasks and activities across month range', () async {
      // Create a task on 2026-11-15
      await taskRepository.createTask(
        TaskModel(title: 'Team Presentation', dueDate: '2026-11-15'),
      );

      // Create an activity on 2026-11-20
      final actId = await activityRepository.createActivity(
        ActivityModel(title: 'Gym Workout'),
      );
      await activityRepository.getOccurrencesForDate('2026-11-20');

      final calendarController = CalendarController(
        taskRepository: taskRepository,
        activityRepository: activityRepository,
      );

      // Load month events for November 2026
      await calendarController.loadMonthEvents(DateTime(2026, 11, 15));

      final events15 = calendarController.getEventsForDay(
        DateTime(2026, 11, 15),
      );
      expect(events15.contains('task'), isTrue);

      final events20 = calendarController.getEventsForDay(
        DateTime(2026, 11, 20),
      );
      expect(events20.contains('activity'), isTrue);

      // Load date details for 2026-11-15
      await calendarController.loadSelectedDateDetails(DateTime(2026, 11, 15));
      expect(calendarController.tasksTotal.value, 1);
      expect(
        calendarController.selectedTasks.first.taskTitle,
        'Team Presentation',
      );

      // Load date details for 2026-11-20
      await calendarController.loadSelectedDateDetails(DateTime(2026, 11, 20));
      expect(calendarController.activitiesTotal.value, greaterThanOrEqualTo(1));
      expect(
        calendarController.selectedActivities.any((a) => a.activityId == actId),
        isTrue,
      );
    });
  });

  group('Database Migration v2 -> v3', () {
    test(
      'Migration v2 -> v3 adds scheduled_time, reminder_enabled and status',
      () async {
        final dbFolder = await getDatabasesPath();
        final tempPath = join(dbFolder, 'test_v2_v3_migration.db');

        if (await databaseFactory.databaseExists(tempPath)) {
          await databaseFactory.deleteDatabase(tempPath);
        }

        // 1. Create database at Version 2 (schema without v3 columns)
        final v2Db = await openDatabase(
          tempPath,
          version: 2,
          onCreate: (database, version) async {
            // v2 schema
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

            await database.execute('''
            CREATE TABLE ${DbConstants.tableActivities} (
              ${DbConstants.colActId} INTEGER PRIMARY KEY AUTOINCREMENT,
              ${DbConstants.colActTitle} TEXT NOT NULL,
              ${DbConstants.colActDescription} TEXT,
              ${DbConstants.colActCategory} TEXT DEFAULT 'Personal',
              ${DbConstants.colActIcon} TEXT,
              ${DbConstants.colActColor} TEXT,
              ${DbConstants.colActTargetFrequency} TEXT NOT NULL DEFAULT 'daily',
              ${DbConstants.colActTargetValue} INTEGER NOT NULL DEFAULT 1,
              ${DbConstants.colActUnit} TEXT DEFAULT 'times',
              ${DbConstants.colActIsActive} INTEGER NOT NULL DEFAULT 1,
              ${DbConstants.colActCreatedAt} TEXT NOT NULL,
              ${DbConstants.colActUpdatedAt} TEXT NOT NULL
            );
          ''');

            await database.execute('''
            CREATE TABLE ${DbConstants.tableActivityOccurrences} (
              ${DbConstants.colActOccId} INTEGER PRIMARY KEY AUTOINCREMENT,
              ${DbConstants.colActOccActivityId} INTEGER NOT NULL,
              ${DbConstants.colActOccDate} TEXT NOT NULL,
              ${DbConstants.colActOccIsCompleted} INTEGER NOT NULL DEFAULT 0,
              ${DbConstants.colActOccActualValue} INTEGER NOT NULL DEFAULT 0,
              ${DbConstants.colActOccCompletedAt} TEXT,
              ${DbConstants.colActOccNotes} TEXT,
              ${DbConstants.colActOccCreatedAt} TEXT NOT NULL,
              ${DbConstants.colActOccUpdatedAt} TEXT NOT NULL
            );
          ''');

            await database.execute('''
            CREATE TABLE ${DbConstants.tableAppSettings} (
              ${DbConstants.colSettingKey} TEXT PRIMARY KEY,
              ${DbConstants.colSettingValue} TEXT NOT NULL
            );
          ''');
          },
        );

        // Insert an activity and an occurrence in v2
        await v2Db.insert(DbConstants.tableActivities, {
          DbConstants.colActTitle: 'Pre-migration activity',
          DbConstants.colActCategory: 'Routine',
          DbConstants.colActTargetFrequency: 'daily',
          DbConstants.colActTargetValue: 1,
          DbConstants.colActUnit: 'times',
          DbConstants.colActIsActive: 1,
          DbConstants.colActCreatedAt: '2026-11-18T00:00:00.000',
          DbConstants.colActUpdatedAt: '2026-11-18T00:00:00.000',
        });

        await v2Db.insert(DbConstants.tableActivityOccurrences, {
          DbConstants.colActOccActivityId: 1,
          DbConstants.colActOccDate: '2026-11-18',
          DbConstants.colActOccIsCompleted: 1,
          DbConstants.colActOccActualValue: 1,
          DbConstants.colActOccCreatedAt: '2026-11-18T00:00:00.000',
          DbConstants.colActOccUpdatedAt: '2026-11-18T00:00:00.000',
        });

        await v2Db.close();

        // 2. Open at Version 3 triggering migration
        final v3Db = await openDatabase(
          tempPath,
          version: 3,
          onUpgrade: (database, oldVersion, newVersion) async {
            if (oldVersion < 3) {
              await database.execute('''
              ALTER TABLE ${DbConstants.tableActivities} 
              ADD COLUMN ${DbConstants.colActScheduledTime} TEXT;
            ''');
              await database.execute('''
              ALTER TABLE ${DbConstants.tableActivities} 
              ADD COLUMN ${DbConstants.colActReminderEnabled} INTEGER NOT NULL DEFAULT 0;
            ''');
              await database.execute('''
              ALTER TABLE ${DbConstants.tableActivityOccurrences} 
              ADD COLUMN ${DbConstants.colActOccStatus} TEXT NOT NULL DEFAULT 'pending';
            ''');
              await database.execute('''
              UPDATE ${DbConstants.tableActivityOccurrences} 
              SET ${DbConstants.colActOccStatus} = 'completed' 
              WHERE ${DbConstants.colActOccIsCompleted} = 1;
            ''');
            }
          },
        );

        // Verify new columns exist and work
        final activities = await v3Db.query(DbConstants.tableActivities);
        expect(
          activities.first.containsKey(DbConstants.colActScheduledTime),
          isTrue,
        );
        expect(
          activities.first.containsKey(DbConstants.colActReminderEnabled),
          isTrue,
        );

        final occurrences = await v3Db.query(
          DbConstants.tableActivityOccurrences,
        );
        expect(
          occurrences.first.containsKey(DbConstants.colActOccStatus),
          isTrue,
        );
        expect(occurrences.first[DbConstants.colActOccStatus], 'completed');

        await v3Db.close();
        await databaseFactory.deleteDatabase(tempPath);
      },
    );
  });
}
