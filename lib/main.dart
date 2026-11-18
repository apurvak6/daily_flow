import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/database/database_helper.dart';
import 'core/services/notification_service.dart';
import 'core/utils/app_logger.dart';
import 'data/datasources/settings_local_datasource.dart';

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

  // Load saved theme preference
  ThemeMode initialThemeMode = ThemeMode.system;
  try {
    final settingsDataSource = SettingsLocalDataSourceImpl(
      dbHelper: DatabaseHelper.instance,
    );
    initialThemeMode = await settingsDataSource.getThemeMode();
    AppLogger.info('Loaded saved theme mode: ${initialThemeMode.name}', 'main');
  } catch (e, stack) {
    AppLogger.error('Failed to load theme preference', e, stack, 'main');
  }

  // Initialize Local Notifications
  try {
    final notificationService = NotificationService();
    await notificationService.init(runReconciliation: true);
    Get.put<NotificationService>(notificationService, permanent: true);
    // Request runtime notification permission on startup
    await notificationService.requestPermissions();
  } catch (e, stack) {
    AppLogger.error('Failed to initialize notifications', e, stack, 'main');
  }

  runApp(DailyFlowApp(initialThemeMode: initialThemeMode));
}

/// Root widget configuring GetMaterialApp with routing, bindings, and Material 3 theming.
class DailyFlowApp extends StatelessWidget {
  final ThemeMode initialThemeMode;

  const DailyFlowApp({super.key, this.initialThemeMode = ThemeMode.system});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: initialThemeMode,
      // Execute the dependency registration logic defined inside
      // InitialBinding when the application starts.
      initialBinding: InitialBinding(),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      defaultTransition: Transition.fadeIn,
    );
  }
}
