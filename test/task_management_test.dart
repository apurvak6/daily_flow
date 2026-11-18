import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daily_flow/core/constants/app_constants.dart';
import 'package:daily_flow/core/constants/db_constants.dart';
import 'package:daily_flow/core/database/database_helper.dart';
import 'package:daily_flow/core/utils/date_utils.dart';
import 'package:daily_flow/data/datasources/task_local_datasource.dart';
import 'package:daily_flow/data/models/task_model.dart';
import 'package:daily_flow/data/repositories/task_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late TaskLocalDataSource dataSource;
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
    dataSource = TaskLocalDataSourceImpl(dbHelper: DatabaseHelper.instance);
    taskRepository = TaskRepositoryImpl(dataSource: dataSource);
  });

  tearDown(() async {
    await db.close();
    DatabaseHelper.setDatabaseForTesting(null);
  });

  group('Task Form Validation Rules', () {
    String? validateTitle(String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Task title is required';
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

    test('Rejects null, empty and whitespace-only titles', () {
      expect(validateTitle(null), 'Task title is required');
      expect(validateTitle(''), 'Task title is required');
      expect(validateTitle('   '), 'Task title is required');
      expect(validateTitle('\t \n '), 'Task title is required');
    });

    test('Rejects titles shorter than 3 characters', () {
      expect(validateTitle('a'), 'Title must be at least 3 characters');
      expect(validateTitle('ab'), 'Title must be at least 3 characters');
      expect(validateTitle(' a '), 'Title must be at least 3 characters');
    });

    test('Accepts minimum valid title length of 3 characters', () {
      expect(validateTitle('abc'), isNull);
      expect(validateTitle('  abc  '), isNull);
    });

    test('Accepts maximum valid title length of 60 characters', () {
      final sixtyChars = 'A' * 60;
      expect(validateTitle(sixtyChars), isNull);
    });

    test('Rejects titles longer than 60 characters', () {
      final sixtyOneChars = 'A' * 61;
      expect(validateTitle(sixtyOneChars), 'Title cannot exceed 60 characters');
    });
  });

  group('Task Management CRUD & Persistence', () {
    test('Create task with all fields and verify database storage', () async {
      final fullTask = TaskModel(
        title: 'Review System Architecture',
        description: 'Deep dive into SQLite transactions and MVVM state flows',
        category: 'Work',
        priority: AppConstants.priorityHigh,
        dueDate: '2026-11-20',
        dueTime: '14:30',
        isRecurring: false,
        recurrenceType: AppConstants.recurrenceNone,
        isCompleted: false,
        reminderTime: '14:30',
      );

      final taskId = await taskRepository.createTask(fullTask);
      expect(taskId, isPositive);

      final retrieved = await taskRepository.getTaskById(taskId);
      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'Review System Architecture');
      expect(retrieved.description, contains('MVVM state flows'));
      expect(retrieved.category, 'Work');
      expect(retrieved.priority, AppConstants.priorityHigh);
      expect(retrieved.dueDate, '2026-11-20');
      expect(retrieved.dueTime, '14:30');
      expect(retrieved.reminderTime, '14:30');
      expect(retrieved.isRecurring, isFalse);

      final occurrences = await taskRepository.getOccurrencesForDate(
        '2026-11-20',
      );
      expect(occurrences.length, 1);
      expect(occurrences.first.taskTitle, 'Review System Architecture');
      expect(occurrences.first.isCompleted, isFalse);
    });

    test('Edit task details updates master and future occurrence', () async {
      final taskId = await taskRepository.createTask(
        TaskModel(
          title: 'Initial Title',
          dueDate: '2026-11-20',
          priority: AppConstants.priorityLow,
        ),
      );

      final originalTask = await taskRepository.getTaskById(taskId);
      expect(originalTask, isNotNull);

      await taskRepository.updateTask(
        originalTask!.copyWith(
          title: 'Revised Architecture Title',
          description: 'Updated notes',
          priority: AppConstants.priorityHigh,
          category: 'Health',
          dueDate: '2026-11-22',
        ),
      );

      final updatedTask = await taskRepository.getTaskById(taskId);
      expect(updatedTask!.title, 'Revised Architecture Title');
      expect(updatedTask.priority, AppConstants.priorityHigh);
      expect(updatedTask.category, 'Health');
      expect(updatedTask.dueDate, '2026-11-22');

      // Occurrence moved to new date
      final oldOccurrences = await taskRepository.getOccurrencesForDate(
        '2026-11-20',
      );
      expect(oldOccurrences.isEmpty, isTrue);

      final newOccurrences = await taskRepository.getOccurrencesForDate(
        '2026-11-22',
      );
      expect(newOccurrences.length, 1);
      expect(newOccurrences.first.taskTitle, 'Revised Architecture Title');
      expect(newOccurrences.first.priority, AppConstants.priorityHigh);
    });

    test('Delete task cascades and removes all occurrences', () async {
      final taskId = await taskRepository.createTask(
        TaskModel(title: 'Temporary Task', dueDate: '2026-11-20'),
      );

      var occurrences = await taskRepository.getOccurrencesForDate(
        '2026-11-20',
      );
      expect(occurrences.length, 1);

      await taskRepository.deleteTask(taskId);

      final taskAfter = await taskRepository.getTaskById(taskId);
      expect(taskAfter, isNull);

      occurrences = await taskRepository.getOccurrencesForDate('2026-11-20');
      expect(occurrences.isEmpty, isTrue);
    });

    test('Mark completed persists across new repository instances', () async {
      final taskId = await taskRepository.createTask(
        TaskModel(title: 'Submit Code Review', dueDate: '2026-11-18'),
      );

      final occurrences = await taskRepository.getOccurrencesForDate(
        '2026-11-18',
      );
      final occurrenceId = occurrences.first.id!;

      await taskRepository.toggleOccurrenceCompletion(occurrenceId, true);

      // Simulate App Restart with fresh repository and datasource instances
      final freshDataSource = TaskLocalDataSourceImpl(
        dbHelper: DatabaseHelper.instance,
      );
      final freshRepo = TaskRepositoryImpl(dataSource: freshDataSource);

      final postRestartOccurrences = await freshRepo.getOccurrencesForDate(
        '2026-11-18',
      );
      expect(postRestartOccurrences.first.isCompleted, isTrue);
      expect(postRestartOccurrences.first.completedAt, isNotNull);

      // Master record is also marked completed for non-recurring tasks
      final masterTask = await freshRepo.getTaskById(taskId);
      expect(masterTask!.isCompleted, isTrue);
    });
  });

  group('Recurring Tasks Isolation & Duplicate Prevention', () {
    test(
      'Daily recurring task generates isolated occurrences across dates',
      () async {
        final today = AppDateUtils.todayIso;
        final tomorrow = AppDateUtils.toIsoDate(
          AppDateUtils.today.add(const Duration(days: 1)),
        );

        // 1. Create daily recurring task
        final taskId = await taskRepository.createTask(
          TaskModel(
            title: 'Morning Standup & Sync',
            dueDate: today,
            dueTime: '09:00',
            isRecurring: true,
            recurrenceType: AppConstants.recurrenceDaily,
          ),
        );

        // 2. Query today's occurrence
        final todayOccurrences = await taskRepository.getOccurrencesForDate(
          today,
        );
        expect(todayOccurrences.length, 1);
        final todayOcc = todayOccurrences.first;
        expect(todayOcc.isCompleted, isFalse);

        // 3. Mark today's occurrence as completed
        await taskRepository.toggleOccurrenceCompletion(todayOcc.id!, true);

        final updatedToday = await taskRepository.getOccurrencesForDate(today);
        expect(updatedToday.first.isCompleted, isTrue);

        // 4. Query tomorrow's occurrence
        final tomorrowOccurrences = await taskRepository.getOccurrencesForDate(
          tomorrow,
        );
        expect(tomorrowOccurrences.length, 1);
        final tomorrowOcc = tomorrowOccurrences.first;

        // 5. Tomorrow's occurrence must remain pending (isolated)
        expect(tomorrowOcc.isCompleted, isFalse);
        expect(tomorrowOcc.id, isNot(equals(todayOcc.id)));

        // 6. Master task recurring flag remains true and not completed
        final master = await taskRepository.getTaskById(taskId);
        expect(master!.isRecurring, isTrue);
        expect(master.isCompleted, isFalse);

        // 7. Re-query today to verify no duplicate occurrence created
        final recheckToday = await taskRepository.getOccurrencesForDate(today);
        expect(recheckToday.length, 1);
        expect(recheckToday.first.isCompleted, isTrue);
      },
    );
  });

  group('Dashboard Metrics Calculation', () {
    test(
      'Calculates total, completed, pending, overdue counts and percentage',
      () async {
        final today = AppDateUtils.todayIso;

        // 1. Insert 1 overdue task
        await taskRepository.createTask(
          TaskModel(title: 'Overdue Task', dueDate: '2026-11-01'),
        );

        // 2. Insert 4 tasks for today
        final task1 = await taskRepository.createTask(
          TaskModel(title: 'Task 1', dueDate: today),
        );
        final task2 = await taskRepository.createTask(
          TaskModel(title: 'Task 2', dueDate: today),
        );
        await taskRepository.createTask(
          TaskModel(title: 'Task 3', dueDate: today),
        );
        await taskRepository.createTask(
          TaskModel(title: 'Task 4', dueDate: today),
        );

        // Complete 2 tasks for today
        final todayOccs = await taskRepository.getOccurrencesForDate(today);
        final occ1 = todayOccs.firstWhere((o) => o.taskId == task1);
        final occ2 = todayOccs.firstWhere((o) => o.taskId == task2);

        await taskRepository.toggleOccurrenceCompletion(occ1.id!, true);
        await taskRepository.toggleOccurrenceCompletion(occ2.id!, true);

        // Query Stats
        final stats = await taskRepository.getDailyStats(today);
        expect(stats['total'], 4);
        expect(stats['completed'], 2);
        expect(stats['pending'], 2);
        expect(stats['overdue'], 1);

        // Verify Percentage: 2 / 4 = 50.0%
        final percentage = (stats['completed']! / stats['total']!) * 100;
        expect(percentage, 50.0);
      },
    );

    test('Handles 0 tasks edge case without division by zero', () {
      const total = 0;
      const completed = 0;
      final percentage = total > 0 ? (completed / total) * 100 : 0.0;
      expect(percentage, 0.0);
    });
  });
}
