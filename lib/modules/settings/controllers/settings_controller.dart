import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/repositories/settings_repository.dart';

/// ViewModel controller for application preferences, theme switching,
/// and local notification settings/permissions.
class SettingsController extends GetxController {
  final SettingsRepository _settingsRepository;

  SettingsController({SettingsRepository? settingsRepository})
    : _settingsRepository =
          settingsRepository ??
          (Get.isRegistered<SettingsRepository>()
              ? Get.find<SettingsRepository>()
              : SettingsRepositoryImpl());

  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;
  final RxBool notificationsEnabled = true.obs;
  final RxBool osPermissionGranted = true.obs;
  final RxBool exactAlarmsGranted = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final mode = await _settingsRepository.getThemeMode();
      final notifications = await _settingsRepository.areNotificationsEnabled();
      themeMode.value = mode;
      notificationsEnabled.value = notifications;

      await refreshPermissionStatus();
    } catch (e, stack) {
      AppLogger.error(
        'Failed to load settings in controller',
        e,
        stack,
        'SettingsController',
      );
    }
  }

  /// Refreshes the OS-level permission status.
  Future<void> refreshPermissionStatus() async {
    if (Get.isRegistered<NotificationService>()) {
      final notif = NotificationService.to;
      osPermissionGranted.value = await notif.areNotificationsEnabled();
      exactAlarmsGranted.value = await notif.canScheduleExactAlarms();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    Get.changeThemeMode(mode);
    try {
      await _settingsRepository.setThemeMode(mode);
      AppLogger.info('Saved theme mode: ${mode.name}', 'SettingsController');
    } catch (e, stack) {
      AppLogger.error(
        'Failed to save theme mode',
        e,
        stack,
        'SettingsController',
      );
    }
  }

  /// Toggles local notifications globally.
  /// When disabled, all pending OS notifications are cancelled while keeping SQLite records intact.
  /// When enabled, requests permissions and reconciles active reminders from SQLite.
  Future<void> toggleNotifications(bool enable) async {
    if (enable) {
      if (Get.isRegistered<NotificationService>()) {
        final notif = NotificationService.to;
        final granted = await notif.requestPermissions();
        osPermissionGranted.value = await notif.areNotificationsEnabled();

        if (!granted && !osPermissionGranted.value) {
          notificationsEnabled.value = false;
          await _settingsRepository.setNotificationsEnabled(false);
          if (Get.context != null) {
            Get.snackbar(
              'Permission Required',
              'Notifications are disabled in system settings. Tap below to enable them.',
              mainButton: TextButton(
                onPressed: () => openNotificationSettings(),
                child: const Text('Settings'),
              ),
              duration: const Duration(seconds: 4),
            );
          }
          return;
        }
      }

      notificationsEnabled.value = true;
      try {
        await _settingsRepository.setNotificationsEnabled(true);
        if (Get.isRegistered<NotificationService>()) {
          await NotificationService.to.reconcileNotifications();
        }
        AppLogger.info('Enabled notifications globally', 'SettingsController');
      } catch (e, stack) {
        AppLogger.error(
          'Failed to enable notifications',
          e,
          stack,
          'SettingsController',
        );
      }
    } else {
      notificationsEnabled.value = false;
      try {
        await _settingsRepository.setNotificationsEnabled(false);
        if (Get.isRegistered<NotificationService>()) {
          await NotificationService.to.cancelAllNotifications();
        }
        AppLogger.info('Disabled notifications globally', 'SettingsController');
      } catch (e, stack) {
        AppLogger.error(
          'Failed to disable notifications',
          e,
          stack,
          'SettingsController',
        );
      }
    }
  }

  /// Opens the device's native app notification settings page.
  Future<void> openNotificationSettings() async {
    if (Get.isRegistered<NotificationService>()) {
      await NotificationService.to.openNotificationSettings();
      // Allow user to return and refresh status
      Future.delayed(const Duration(seconds: 1), refreshPermissionStatus);
    }
  }

  /// Requests exact alarms permission on Android 12+.
  Future<void> requestExactAlarmsPermission() async {
    if (Get.isRegistered<NotificationService>()) {
      final granted = await NotificationService.to
          .requestExactAlarmsPermission();
      exactAlarmsGranted.value = granted;
    }
  }
}
