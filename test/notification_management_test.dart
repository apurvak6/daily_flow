import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:daily_flow/core/constants/app_constants.dart';
import 'package:daily_flow/core/database/database_helper.dart';
import 'package:daily_flow/core/services/notification_service.dart';
import 'package:daily_flow/data/datasources/activity_local_datasource.dart';
import 'package:daily_flow/data/datasources/settings_local_datasource.dart';
import 'package:daily_flow/data/datasources/task_local_datasource.dart';
import 'package:daily_flow/data/models/activity_model.dart';
import 'package:daily_flow/data/models/task_model.dart';
import 'package:daily_flow/data/repositories/activity_repository.dart';
import 'package:daily_flow/data/repositories/settings_repository.dart';
import 'package:daily_flow/data/repositories/task_repository.dart';
import 'package:daily_flow/modules/settings/controllers/settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final List<MethodCall> methodCalls = [];
  final List<Map<String, dynamic>> mockPendingNotifications = [];
  bool mockPermissionGranted = true;
  bool mockExactAlarmsGranted = true;

  late Database db;
  late NotificationService notificationService;
  late TaskRepository taskRepository;
  late ActivityRepository activityRepository;
  late SettingsRepository settingsRepository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
  });

  setUp(() async {
    methodCalls.clear();
    mockPendingNotifications.clear();
    mockPermissionGranted = true;
    mockExactAlarmsGranted = true;
    Get.reset();

    // Mock native MethodChannel for flutter_local_notifications
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          methodCalls.add(call);
          switch (call.method) {
            case 'initialize':
              return true;
            case 'createNotificationChannel':
              return null;
            case 'zonedSchedule':
              final args = Map<String, dynamic>.from(call.arguments as Map);
              mockPendingNotifications.removeWhere(
                (n) => n['id'] == args['id'],
              );
              mockPendingNotifications.add({
                'id': args['id'],
                'title': args['title'],
                'body': args['body'],
                'payload': args['payload'],
              });
              return null;
            case 'cancel':
              final id = call.arguments is Map
                  ? (call.arguments['id'] as int)
                  : (call.arguments as int);
              mockPendingNotifications.removeWhere((n) => n['id'] == id);
              return null;
            case 'cancelAll':
              mockPendingNotifications.clear();
              return null;
            case 'pendingNotificationRequests':
              return mockPendingNotifications;
            case 'requestNotificationsPermission':
              return mockPermissionGranted;
            case 'areNotificationsEnabled':
              return mockPermissionGranted;
            case 'canScheduleExactNotifications':
              return mockExactAlarmsGranted;
            case 'requestExactAlarmsPermission':
              return mockExactAlarmsGranted;
            case 'openAppNotificationSettings':
              return true;
            default:
              return null;
          }
        });

    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (database, version) async {
          await DatabaseHelper.createSchema(database);
        },
      ),
    );
    DatabaseHelper.setDatabaseForTesting(db);

    notificationService = NotificationService();
    await notificationService.init(runReconciliation: false);
    Get.put<NotificationService>(notificationService, permanent: true);

    final taskDs = TaskLocalDataSourceImpl(dbHelper: DatabaseHelper.instance);
    final actDs = ActivityLocalDataSourceImpl(
      dbHelper: DatabaseHelper.instance,
    );
    final setDs = SettingsLocalDataSourceImpl(
      dbHelper: DatabaseHelper.instance,
    );

    taskRepository = TaskRepositoryImpl(
      dataSource: taskDs,
      notificationService: notificationService,
    );
    activityRepository = ActivityRepositoryImpl(
      dataSource: actDs,
      notificationService: notificationService,
    );
    settingsRepository = SettingsRepositoryImpl(dataSource: setDs);

    Get.put<TaskRepository>(taskRepository, permanent: true);
    Get.put<ActivityRepository>(activityRepository, permanent: true);
    Get.put<SettingsRepository>(settingsRepository, permanent: true);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await db.close();
    DatabaseHelper.setDatabaseForTesting(null);
  });

  group('Phase 4: Time Parsing & ID Generation Logic', () {
    test(
      'parseTimeString correctly parses 12-hour AM/PM and 24-hour formats',
      () {
        expect(NotificationService.parseTimeString('08:00 AM'), (8, 0));
        expect(NotificationService.parseTimeString('8:30 PM'), (20, 30));
        expect(NotificationService.parseTimeString('12:00 PM'), (12, 0));
        expect(NotificationService.parseTimeString('12:00 AM'), (0, 0));
        expect(NotificationService.parseTimeString('14:45'), (14, 45));
        expect(NotificationService.parseTimeString(''), isNull);
        expect(NotificationService.parseTimeString(null), isNull);
      },
    );

    test(
      'Task and Activity notification IDs are unique and non-overlapping',
      () {
        const taskId = 42;
        const actId = 42;
        final taskNotifId = AppConstants.notificationTaskBaseId + taskId;
        final actNotifId = AppConstants.notificationActivityBaseId + actId;

        expect(taskNotifId, 1000042);
        expect(actNotifId, 2000042);
        expect(taskNotifId != actNotifId, isTrue);
      },
    );
  });

  group('Phase 4: Scheduling Tasks & Activities', () {
    test('Scenario 1: Schedule a one-time task reminder in the future', () async {
      final futureDate = DateTime.now().add(const Duration(days: 3));
      final dateStr =
          "${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}";

      final task = TaskModel(
        title: 'Project Deadline',
        dueDate: dateStr,
        dueTime: '10:00 AM',
        reminderTime: '10:00 AM',
        isRecurring: false,
      );

      final taskId = await taskRepository.createTask(task);
      expect(taskId, greaterThan(0));

      final scheduled = methodCalls.where((c) => c.method == 'zonedSchedule');
      expect(scheduled, isNotEmpty);
      final lastCall = scheduled.last;
      expect(
        lastCall.arguments['id'],
        AppConstants.notificationTaskBaseId + taskId,
      );
      expect(lastCall.arguments['title'], 'Project Deadline');
      expect(
        lastCall.arguments['matchDateTimeComponents'],
        isNull,
      ); // One-time task
    });

    test('Scenario 2: Schedule a daily recurring task reminder', () async {
      final task = TaskModel(
        title: 'Daily Standup Call',
        dueTime: '09:30 AM',
        reminderTime: '09:30 AM',
        isRecurring: true,
        recurrenceType: AppConstants.recurrenceDaily,
      );

      final taskId = await taskRepository.createTask(task);
      expect(taskId, greaterThan(0));

      final scheduled = methodCalls.where((c) => c.method == 'zonedSchedule');
      expect(scheduled, isNotEmpty);
      final lastCall = scheduled.last;
      expect(
        lastCall.arguments['id'],
        AppConstants.notificationTaskBaseId + taskId,
      );
      expect(lastCall.arguments['title'], 'Daily Standup Call');
      // DateTimeComponents.time index
      expect(lastCall.arguments['matchDateTimeComponents'], 0);
    });

    test('Scenario 3: Schedule a daily activity routine reminder', () async {
      final activity = ActivityModel(
        title: 'Morning Yoga',
        scheduledTime: '07:00 AM',
        isReminderEnabled: true,
        isActive: true,
      );

      final actId = await activityRepository.createActivity(activity);
      expect(actId, greaterThan(0));

      final scheduled = methodCalls.where((c) => c.method == 'zonedSchedule');
      expect(scheduled, isNotEmpty);
      final lastCall = scheduled.last;
      expect(
        lastCall.arguments['id'],
        AppConstants.notificationActivityBaseId + actId,
      );
      expect(lastCall.arguments['title'], 'Morning Yoga');
      expect(lastCall.arguments['matchDateTimeComponents'], 0);
    });
  });

  group('Phase 4: Edit, Deactivate, & Delete Scenarios', () {
    test(
      'Scenario 4: Edit scheduled task time reschedules notification with updated time',
      () async {
        final futureDate = DateTime.now().add(const Duration(days: 2));
        final dateStr =
            "${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}";

        final task = TaskModel(
          title: 'Doctor Appointment',
          dueDate: dateStr,
          dueTime: '10:00 AM',
          reminderTime: '10:00 AM',
        );
        final taskId = await taskRepository.createTask(task);

        // Edit task to 02:00 PM
        final updatedTask = task.copyWith(
          id: taskId,
          dueTime: '02:00 PM',
          reminderTime: '02:00 PM',
        );
        await taskRepository.updateTask(updatedTask);

        final scheduled = methodCalls
            .where((c) => c.method == 'zonedSchedule')
            .toList();
        expect(scheduled.length, 2);
        expect(
          scheduled.last.arguments['id'],
          AppConstants.notificationTaskBaseId + taskId,
        );
        expect(scheduled.last.arguments['body'], contains('02:00 PM'));
      },
    );

    test('Scenario 5: Delete task cancels its pending notification', () async {
      final task = TaskModel(
        title: 'Temporary Task',
        dueDate: '2030-01-01',
        dueTime: '11:00 AM',
        reminderTime: '11:00 AM',
      );
      final taskId = await taskRepository.createTask(task);

      expect(
        mockPendingNotifications.any(
          (n) => n['id'] == AppConstants.notificationTaskBaseId + taskId,
        ),
        isTrue,
      );

      await taskRepository.deleteTask(taskId);

      final cancelCalls = methodCalls
          .where((c) => c.method == 'cancel')
          .toList();
      expect(cancelCalls, isNotEmpty);
      expect(
        cancelCalls.last.arguments['id'],
        AppConstants.notificationTaskBaseId + taskId,
      );
      expect(
        mockPendingNotifications.any(
          (n) => n['id'] == AppConstants.notificationTaskBaseId + taskId,
        ),
        isFalse,
      );
    });

    test('Scenario 6: Disabling reminder cancels the notification', () async {
      final activity = ActivityModel(
        title: 'Meditation',
        scheduledTime: '06:00 PM',
        isReminderEnabled: true,
        isActive: true,
      );
      final actId = await activityRepository.createActivity(activity);

      // Update with reminder disabled
      final updatedAct = activity.copyWith(id: actId, isReminderEnabled: false);
      await activityRepository.updateActivity(updatedAct);

      final cancelCalls = methodCalls
          .where((c) => c.method == 'cancel')
          .toList();
      expect(cancelCalls, isNotEmpty);
      expect(
        cancelCalls.last.arguments['id'],
        AppConstants.notificationActivityBaseId + actId,
      );
    });
  });

  group('Phase 4: Permission Handling & Reconciliation', () {
    test('Scenario 7: Permission denied flow handled gracefully', () async {
      mockPermissionGranted = false;

      final controller = SettingsController(
        settingsRepository: settingsRepository,
      );
      await controller.toggleNotifications(true);

      expect(controller.notificationsEnabled.value, isFalse);
      expect(await settingsRepository.areNotificationsEnabled(), isFalse);
    });

    test(
      'Scenario 8 & 9: Reconciliation cancels obsolete and schedules missing notifications',
      () async {
        // 1. Insert an active task with reminder
        final futureDate = DateTime.now().add(const Duration(days: 4));
        final dateStr =
            "${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}";

        final activeTask = TaskModel(
          title: 'Active Future Task',
          dueDate: dateStr,
          dueTime: '08:00 AM',
          reminderTime: '08:00 AM',
        );
        final taskId = await taskRepository.createTask(activeTask);

        // 2. Put an obsolete ghost notification in mock OS pending list
        const obsoleteNotifId = 9999999;
        mockPendingNotifications.add({
          'id': obsoleteNotifId,
          'title': 'Deleted Ghost Task',
          'body': 'Old',
          'payload': null,
        });

        // 3. Clear the active task from mock pending list to simulate missing schedule
        mockPendingNotifications.removeWhere(
          (n) => n['id'] == AppConstants.notificationTaskBaseId + taskId,
        );

        // 4. Run reconciliation
        await notificationService.reconcileNotifications();

        // Obsolete notification should be cancelled
        final cancelCalls = methodCalls.where(
          (c) =>
              c.method == 'cancel' &&
              (c.arguments is Map
                  ? c.arguments['id'] == obsoleteNotifId
                  : c.arguments == obsoleteNotifId),
        );
        expect(cancelCalls, isNotEmpty);

        // Active task should be scheduled
        final scheduledActive = mockPendingNotifications.where(
          (n) => n['id'] == AppConstants.notificationTaskBaseId + taskId,
        );
        expect(scheduledActive, isNotEmpty);
      },
    );

    test(
      'Scenario 10: Duplicate notifications are prevented via deterministic ID mapping',
      () async {
        final activity = ActivityModel(
          title: 'Drink Water',
          scheduledTime: '10:00 AM',
          isReminderEnabled: true,
          isActive: true,
        );
        final actId = await activityRepository.createActivity(activity);

        // Run reconciliation twice
        await notificationService.reconcileNotifications();
        await notificationService.reconcileNotifications();

        final matches = mockPendingNotifications.where(
          (n) => n['id'] == AppConstants.notificationActivityBaseId + actId,
        );
        expect(matches.length, 1);
      },
    );

    test(
      'Scenario 11: Global notification toggle clears pending alarms without altering SQLite data',
      () async {
        final task = TaskModel(
          title: 'Preserved Task',
          dueDate: '2032-05-01',
          dueTime: '09:00 AM',
          reminderTime: '09:00 AM',
        );
        final taskId = await taskRepository.createTask(task);

        final controller = SettingsController(
          settingsRepository: settingsRepository,
        );
        expect(controller.notificationsEnabled.value, isTrue);

        // Toggle off globally
        await controller.toggleNotifications(false);
        expect(controller.notificationsEnabled.value, isFalse);
        expect(mockPendingNotifications, isEmpty);

        // Verify task still exists in SQLite!
        final fetchedTask = await taskRepository.getTaskById(taskId);
        expect(fetchedTask, isNotNull);
        expect(fetchedTask!.title, 'Preserved Task');
        expect(fetchedTask.reminderTime, '09:00 AM');
      },
    );
  });
}
