import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/repositories/settings_repository.dart';

/// ViewModel controller for application preferences and theme switching.
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
    } catch (e, stack) {
      AppLogger.error(
        'Failed to load settings in controller',
        e,
        stack,
        'SettingsController',
      );
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

  Future<void> toggleNotifications(bool enable) async {
    notificationsEnabled.value = enable;
    if (enable) {
      final granted = await NotificationService.to.requestPermissions();
      if (!granted) {
        notificationsEnabled.value = false;
        return;
      }
    }
    try {
      await _settingsRepository.setNotificationsEnabled(
        notificationsEnabled.value,
      );
      AppLogger.info(
        'Saved notification setting: ${notificationsEnabled.value}',
        'SettingsController',
      );
    } catch (e, stack) {
      AppLogger.error(
        'Failed to save notification setting',
        e,
        stack,
        'SettingsController',
      );
    }
  }
}
