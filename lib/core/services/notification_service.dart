import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';
import '../../data/models/task_model.dart';
import '../../data/models/activity_model.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/activity_repository.dart';
import '../../data/repositories/settings_repository.dart';

/// Notification service wrapping flutter_local_notifications for reminders,
/// scheduling logic, permission handling, and startup/resume reconciliation.
class NotificationService extends GetxService with WidgetsBindingObserver {
  static NotificationService get to => Get.find<NotificationService>();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isInitialized) {
      AppLogger.info('App resumed: reconciling notifications', 'NotificationService');
      reconcileNotifications();
    }
  }

  /// Initializes the local notification plugin across platforms, creates channels,
  /// configures timezones, and runs initial reconciliation.
  Future<NotificationService> init({bool runReconciliation = true}) async {
    try {
      // 1. Initialize timezone database and detect local timezone
      _configureLocalTimeZone();

      // 2. Android Initialization Settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // 3. Apple Platforms Initialization Settings
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // 4. Create Android Notification Channel
      final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
      >();
      await androidImpl?.createNotificationChannel(
        const AndroidNotificationChannel(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          description: AppConstants.notificationChannelDesc,
          importance: Importance.high,
        ),
      );

      _isInitialized = true;
      AppLogger.info(
        'NotificationService initialized successfully',
        'NotificationService',
      );

      // 5. Reconcile active tasks & activities if requested
      if (runReconciliation) {
        await reconcileNotifications();
      }
    } catch (e, stack) {
      AppLogger.error(
        'Failed to initialize NotificationService',
        e,
        stack,
        'NotificationService',
      );
    }
    return this;
  }

  /// Detects and configures local timezone from device offset.
  void _configureLocalTimeZone() {
    try {
      tz.initializeTimeZones();
      final offset = DateTime.now().timeZoneOffset;
      tz.Location? matched;
      for (final entry in tz.timeZoneDatabase.locations.entries) {
        final nowTz = tz.TZDateTime.now(entry.value);
        if (nowTz.timeZoneOffset == offset) {
          matched = entry.value;
          break;
        }
      }
      if (matched != null) {
        tz.setLocalLocation(matched);
        AppLogger.info(
          'Configured local time zone: ${matched.name} (offset: $offset)',
          'NotificationService',
        );
      } else {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    } catch (e, stack) {
      AppLogger.error('Failed to configure local time zone', e, stack, 'NotificationService');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    AppLogger.info(
      'Notification tapped: ${response.payload}',
      'NotificationService',
    );
  }

  /// Robust parser for time string supporting 12-hour (hh:mm a) and 24-hour (HH:mm) formats.
  static (int hour, int minute)? parseTimeString(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;
    try {
      final clean = timeStr.trim();
      final isPm = clean.toUpperCase().contains('PM');
      final isAm = clean.toUpperCase().contains('AM');
      final parts = clean.replaceAll(RegExp(r'[a-zA-Z\s]'), '').split(':');
      int hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      if (isPm && hour < 12) hour += 12;
      if (isAm && hour == 12) hour = 0;

      return (hour, minute);
    } catch (_) {
      return null;
    }
  }

  /// Resolves the Android schedule mode based on exact alarm permission.
  Future<AndroidScheduleMode> _resolveScheduleMode() async {
    try {
      final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
      >();
      if (androidImpl != null) {
        final canExact = await androidImpl.canScheduleExactNotifications();
        if (canExact == true) {
          return AndroidScheduleMode.exactAllowWhileIdle;
        }
      }
    } catch (e) {
      AppLogger.warning('Could not verify exact alarm permission: $e', 'NotificationService');
    }
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// Schedules a local notification for a task.
  /// Handles both one-time tasks and daily recurring tasks.
  Future<bool> scheduleTaskNotification(TaskModel task) async {
    if (!_isInitialized || task.id == null) return false;

    final notifId = AppConstants.notificationTaskBaseId + task.id!;

    // Cancel if task is completed or reminder is disabled
    if (task.isCompleted || task.reminderTime == null) {
      await cancelNotification(notifId);
      return false;
    }

    final timeParts = parseTimeString(task.reminderTime ?? task.dueTime);
    if (timeParts == null) {
      await cancelNotification(notifId);
      return false;
    }

    try {
      final nowTz = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate;
      DateTimeComponents? matchComponents;

      if (task.isRecurring) {
        // Daily recurring task
        scheduledDate = tz.TZDateTime(
          tz.local,
          nowTz.year,
          nowTz.month,
          nowTz.day,
          timeParts.$1,
          timeParts.$2,
        );
        if (scheduledDate.isBefore(nowTz)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
        matchComponents = DateTimeComponents.time;
      } else {
        // One-time task
        DateTime dueDate;
        if (task.dueDate != null && task.dueDate!.isNotEmpty) {
          dueDate = DateTime.parse(task.dueDate!);
        } else {
          dueDate = DateTime.now();
        }
        scheduledDate = tz.TZDateTime(
          tz.local,
          dueDate.year,
          dueDate.month,
          dueDate.day,
          timeParts.$1,
          timeParts.$2,
        );
        if (scheduledDate.isBefore(nowTz)) {
          AppLogger.info(
            'One-time task reminder is in the past ($scheduledDate). Skipping.',
            'NotificationService',
          );
          await cancelNotification(notifId);
          return false;
        }
        matchComponents = null;
      }

      final scheduleMode = await _resolveScheduleMode();

      const androidDetails = AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final reminderTimeDisplay = task.reminderTime ?? task.dueTime ?? '';
      final body = task.description != null && task.description!.trim().isNotEmpty
          ? '${task.description} (Due at $reminderTimeDisplay)'
          : 'Task reminder: Due at $reminderTimeDisplay';

      await _notificationsPlugin.zonedSchedule(
        id: notifId,
        title: task.title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: androidDetails,
          iOS: darwinDetails,
          macOS: darwinDetails,
        ),
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: matchComponents,
        payload: '{"type":"task","id":${task.id}}',
      );

      AppLogger.info(
        'Scheduled task reminder #${task.id} at $scheduledDate (recurring: ${task.isRecurring})',
        'NotificationService',
      );
      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to schedule task notification #${task.id}', e, stack, 'NotificationService');
      return false;
    }
  }

  /// Schedules a daily recurring notification for an activity template.
  Future<bool> scheduleActivityNotification(ActivityModel activity) async {
    if (!_isInitialized || activity.id == null) return false;

    final notifId = AppConstants.notificationActivityBaseId + activity.id!;

    if (!activity.isActive || !activity.isReminderEnabled || activity.scheduledTime == null) {
      await cancelNotification(notifId);
      return false;
    }

    final timeParts = parseTimeString(activity.scheduledTime);
    if (timeParts == null) {
      await cancelNotification(notifId);
      return false;
    }

    try {
      final nowTz = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        nowTz.year,
        nowTz.month,
        nowTz.day,
        timeParts.$1,
        timeParts.$2,
      );
      if (scheduledDate.isBefore(nowTz)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final scheduleMode = await _resolveScheduleMode();

      const androidDetails = AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final body = 'Daily routine reminder for ${activity.title} at ${activity.scheduledTime}';

      await _notificationsPlugin.zonedSchedule(
        id: notifId,
        title: activity.title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: androidDetails,
          iOS: darwinDetails,
          macOS: darwinDetails,
        ),
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: '{"type":"activity","id":${activity.id}}',
      );

      AppLogger.info(
        'Scheduled activity reminder #${activity.id} at $scheduledDate',
        'NotificationService',
      );
      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to schedule activity notification #${activity.id}', e, stack, 'NotificationService');
      return false;
    }
  }

  /// Cancels a scheduled task notification.
  Future<void> cancelTaskNotification(int taskId) async {
    await cancelNotification(AppConstants.notificationTaskBaseId + taskId);
  }

  /// Cancels a scheduled activity notification.
  Future<void> cancelActivityNotification(int activityId) async {
    await cancelNotification(AppConstants.notificationActivityBaseId + activityId);
  }

  /// Cancels a notification by integer ID.
  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (e) {
      AppLogger.error('Failed to cancel notification #$id', e, null, 'NotificationService');
    }
  }

  /// Cancels all scheduled notifications.
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      AppLogger.info('All notifications cancelled', 'NotificationService');
    } catch (e) {
      AppLogger.error('Failed to cancel all notifications', e, null, 'NotificationService');
    }
  }

  /// Returns all currently pending notifications from the OS scheduler.
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      AppLogger.error('Failed to fetch pending notifications', e, null, 'NotificationService');
      return [];
    }
  }

  /// Reconciles pending notifications with database state:
  /// 1. Reads global setting (cancels all if notifications are globally disabled).
  /// 2. Reads active tasks and activities from SQLite.
  /// 3. Identifies reminders that should be scheduled.
  /// 4. Checks pending OS notifications.
  /// 5. Cancels obsolete notifications.
  /// 6. Schedules missing/updated notifications.
  Future<void> reconcileNotifications() async {
    if (!_isInitialized) return;

    try {
      final settingsRepo = Get.isRegistered<SettingsRepository>()
          ? Get.find<SettingsRepository>()
          : SettingsRepositoryImpl();

      final bool globalEnabled = await settingsRepo.areNotificationsEnabled();
      if (!globalEnabled) {
        AppLogger.info(
          'Global notifications disabled; canceling all pending notifications',
          'NotificationService',
        );
        await cancelAllNotifications();
        return;
      }

      final taskRepo = Get.isRegistered<TaskRepository>()
          ? Get.find<TaskRepository>()
          : TaskRepositoryImpl();
      final activityRepo = Get.isRegistered<ActivityRepository>()
          ? Get.find<ActivityRepository>()
          : ActivityRepositoryImpl();

      final allTasks = await taskRepo.getAllTasks();
      final allActivities = await activityRepo.getAllActivities(onlyActive: true);

      final Set<int> expectedNotificationIds = {};
      final List<TaskModel> tasksToSchedule = [];
      final List<ActivityModel> activitiesToSchedule = [];

      final now = DateTime.now();

      for (final task in allTasks) {
        if (task.id == null || task.isCompleted || task.reminderTime == null) {
          continue;
        }

        if (task.isRecurring) {
          expectedNotificationIds.add(
            AppConstants.notificationTaskBaseId + task.id!,
          );
          tasksToSchedule.add(task);
        } else {
          final timeParts = parseTimeString(task.reminderTime ?? task.dueTime);
          if (timeParts != null) {
            DateTime dueDate;
            if (task.dueDate != null && task.dueDate!.isNotEmpty) {
              dueDate = DateTime.parse(task.dueDate!);
            } else {
              dueDate = DateTime.now();
            }
            final scheduled = DateTime(
              dueDate.year,
              dueDate.month,
              dueDate.day,
              timeParts.$1,
              timeParts.$2,
            );
            if (scheduled.isAfter(now)) {
              expectedNotificationIds.add(
                AppConstants.notificationTaskBaseId + task.id!,
              );
              tasksToSchedule.add(task);
            }
          }
        }
      }

      for (final act in allActivities) {
        if (act.id == null) continue;
        if (act.isActive &&
            act.isReminderEnabled &&
            act.scheduledTime != null &&
            act.scheduledTime!.isNotEmpty) {
          expectedNotificationIds.add(
            AppConstants.notificationActivityBaseId + act.id!,
          );
          activitiesToSchedule.add(act);
        }
      }

      // Check pending notifications from OS
      final pendingRequests = await _notificationsPlugin.pendingNotificationRequests();
      final pendingIds = pendingRequests.map((r) => r.id).toSet();

      // Cancel obsolete notifications
      for (final id in pendingIds) {
        if (!expectedNotificationIds.contains(id)) {
          AppLogger.info('Canceling obsolete pending notification #$id', 'NotificationService');
          await cancelNotification(id);
        }
      }

      // Schedule all expected active notifications
      for (final task in tasksToSchedule) {
        await scheduleTaskNotification(task);
      }

      for (final act in activitiesToSchedule) {
        await scheduleActivityNotification(act);
      }

      AppLogger.info(
        'Reconciliation complete. Expected: ${expectedNotificationIds.length}, Previously pending: ${pendingIds.length}',
        'NotificationService',
      );
    } catch (e, stack) {
      AppLogger.error('Reconciliation failed', e, stack, 'NotificationService');
    }
  }

  /// Request runtime permissions (Android 13+ and iOS)
  Future<bool> requestPermissions() async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final grantedAndroid = await androidImplementation
          ?.requestNotificationsPermission();

      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final grantedIos = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      return (grantedAndroid ?? false) || (grantedIos ?? false);
    } catch (e) {
      AppLogger.error(
        'Error requesting notification permissions',
        e,
        null,
        'NotificationService',
      );
      return false;
    }
  }

  /// Checks if notifications are permitted on the OS level.
  Future<bool> areNotificationsEnabled() async {
    try {
      final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
      >();
      if (androidImpl != null) {
        return (await androidImpl.areNotificationsEnabled()) ?? true;
      }

      final iosImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
      >();
      if (iosImpl != null) {
        final status = await iosImpl.checkPermissions();
        return status?.isEnabled ?? true;
      }
      return true;
    } catch (e) {
      return true;
    }
  }

  /// Checks if exact alarms are allowed on Android 12+.
  Future<bool> canScheduleExactAlarms() async {
    try {
      final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
      >();
      if (androidImpl != null) {
        return (await androidImpl.canScheduleExactNotifications()) ?? true;
      }
      return true;
    } catch (e) {
      return true;
    }
  }

  /// Requests exact alarms permission on Android 13+.
  Future<bool> requestExactAlarmsPermission() async {
    try {
      final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
      >();
      if (androidImpl != null) {
        return (await androidImpl.requestExactAlarmsPermission()) ?? false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Opens the device's native application settings screen for notifications.
  Future<void> openNotificationSettings() async {
    try {
      final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
      >();
      if (androidImpl != null) {
        await androidImpl.openAppNotificationSettings();
        return;
      }
      final iosImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
      >();
      if (iosImpl != null) {
        await iosImpl.openAppNotificationSettings();
        return;
      }
      final macosImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
      >();
      if (macosImpl != null) {
        await macosImpl.openAppNotificationSettings();
        return;
      }
    } catch (e) {
      AppLogger.error('Could not open app notification settings', e, null, 'NotificationService');
    }
  }

  /// Shows an instant notification (e.g. for testing).
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          channelDescription: AppConstants.notificationChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }
}
