import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daily_flow/core/database/database_helper.dart';
import 'package:daily_flow/core/services/reporting_service.dart';
import 'package:daily_flow/data/datasources/activity_local_datasource.dart';
import 'package:daily_flow/data/datasources/task_local_datasource.dart';
import 'package:daily_flow/data/models/activity_model.dart';
import 'package:daily_flow/data/models/task_model.dart';
import 'package:daily_flow/data/models/activity_occurrence_model.dart';
import 'package:daily_flow/data/models/task_occurrence_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late ReportingService reportingService;
  late Database testDb;

  setUp(() async {
    // Create an in‑memory SQLite database for isolated testing.
    testDb = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async => await DatabaseHelper.createSchema(db),
    );
    DatabaseHelper.setDatabaseForTesting(testDb);
    reportingService = ReportingService(
      taskDataSource: TaskLocalDataSourceImpl(),
      activityDataSource: ActivityLocalDataSourceImpl(),
    );
  });

  tearDown(() async {
    await testDb.close();
  });

  test('Daily stats reflect inserted data', () async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // Insert a task and its occurrence.
    final task = TaskModel(
      title: 'Test Task',
      description: 'desc',
      dueDate: today,
      isCompleted: false,
      reminderTime: null,
    );
    final taskId = await reportingService.taskDataSource.insertTask(task);
    final occ = TaskOccurrenceModel(
      taskId: taskId,
      occurrenceDate: today,
      isCompleted: false,
    );
    await reportingService.taskDataSource.insertOccurrence(occ);

    // Insert an activity and a completed occurrence.
    final activity = ActivityModel(
      title: 'Test Activity',
      description: '',
      category: 'Health',
      scheduledTime: '08:00',
      isActive: true,
      isReminderEnabled: false,
    );
    final actId = await reportingService.activityDataSource.insertActivity(
      activity,
    );
    final occurrences = await reportingService.activityDataSource
        .getOccurrencesForDate(today);
    final todayOcc = occurrences.firstWhere((o) => o.activityId == actId);
    await reportingService.activityDataSource.setOccurrenceStatus(
      todayOcc.id!,
      'completed',
    );

    final stats = await reportingService.getDailyStats(today);
    expect(stats['taskCompleted'], 0);
    expect(stats['taskTotal'], 1);
    expect(stats['taskPending'], 1);
    expect(stats['activityCompleted'], 1);
    expect(stats['activityTotal'], 1);
    expect(stats['activityPending'], 0);
  });

  test('Weekly stats aggregate correctly', () async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1)); // Monday
    final isoStart = start.toIso8601String().substring(0, 10);
    final week = await reportingService.getWeeklyStats(isoStart);

    expect(week['daily'], isA<List>());
    expect((week['daily'] as List).length, 7);
    expect(week['weekTaskTotal'], isA<int>());
    expect(week['weekTaskCompleted'], isA<int>());
    expect(week['weekActivityTotal'], isA<int>());
    expect(week['weekActivityCompleted'], isA<int>());
  });

  test('Category activity summary returns grouped list', () async {
    final summary = await reportingService.getCategoryActivitySummary();
    expect(summary, isA<List>());
    if (summary.isNotEmpty) {
      final Map<String, dynamic> firstItem = summary.first;
      expect(firstItem.containsKey('category'), isTrue);
      expect(firstItem.containsKey('total'), isTrue);
      expect(firstItem.containsKey('completed'), isTrue);
      expect(firstItem.containsKey('pending'), isTrue);
      expect(firstItem.containsKey('skipped'), isTrue);
    }
  });

  test('History for date returns tasks and activities', () async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final history = await reportingService.getHistoryForDate(today);

    expect(history['date'], today);
    expect(history['tasks'], isA<List<TaskOccurrenceModel>>());
    expect(history['activities'], isA<List<ActivityOccurrenceModel>>());
    expect(history['stats'], isA<Map<String, int>>());
  });
}
