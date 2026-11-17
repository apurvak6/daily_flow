import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/notification_service.dart';

/// ViewModel controller for application preferences and theme switching.
class SettingsController extends GetxController {
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;
  final RxBool notificationsEnabled = true.obs;

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    Get.changeThemeMode(mode);
  }

  Future<void> toggleNotifications(bool enable) async {
    notificationsEnabled.value = enable;
    if (enable) {
      final granted = await NotificationService.to.requestPermissions();
      if (!granted) {
        notificationsEnabled.value = false;
      }
    }
  }
}
