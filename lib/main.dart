import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/database/database_helper.dart';
import 'core/services/notification_service.dart';
import 'core/utils/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite database
  try {
    await DatabaseHelper.instance.database;
    AppLogger.info('SQLite Database initialized successfully', 'main');
  } catch (e, stack) {
    AppLogger.error(
      'Failed to initialize database during startup',
      e,
      stack,
      'main',
    );
  }

  // Initialize Local Notifications
  try {
    final notificationService = NotificationService();
    await notificationService.init();
  } catch (e, stack) {
    AppLogger.error('Failed to initialize notifications', e, stack, 'main');
  }

  runApp(const DailyFlowApp());
}

/// Root widget configuring GetMaterialApp with routing, bindings, and Material 3 theming.
class DailyFlowApp extends StatelessWidget {
  const DailyFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialBinding: InitialBinding(),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      defaultTransition: Transition.fadeIn,
    );
  }
}
