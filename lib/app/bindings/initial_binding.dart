import 'package:get/get.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/reporting_service.dart';
import '../../data/datasources/activity_local_datasource.dart';
import '../../data/datasources/settings_local_datasource.dart';
import '../../data/datasources/task_local_datasource.dart';
import '../../data/repositories/activity_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/task_repository.dart';

/// Central dependency injection binding for application startup.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Core Services & Database
    Get.put<DatabaseHelper>(DatabaseHelper.instance, permanent: true);
    if (!Get.isRegistered<NotificationService>()) {
      Get.put<NotificationService>(NotificationService(), permanent: true);
    }

    // 2. Data Sources
    Get.lazyPut<TaskLocalDataSource>(
      () => TaskLocalDataSourceImpl(dbHelper: Get.find<DatabaseHelper>()),
      // Allows a lazy dependency to be recreated after removal
      fenix: true,
    );
    Get.lazyPut<ActivityLocalDataSource>(
      () => ActivityLocalDataSourceImpl(dbHelper: Get.find<DatabaseHelper>()),
      fenix: true,
    );
    Get.lazyPut<SettingsLocalDataSource>(
      () => SettingsLocalDataSourceImpl(dbHelper: Get.find<DatabaseHelper>()),
      fenix: true,
    );

    // 3. Domain Repositories: acts as a bridge between the data layer and the domain layer.
    Get.lazyPut<TaskRepository>(
      () => TaskRepositoryImpl(dataSource: Get.find<TaskLocalDataSource>()),
      fenix: true,
    );
    Get.lazyPut<ActivityRepository>(
      () => ActivityRepositoryImpl(
        dataSource: Get.find<ActivityLocalDataSource>(),
      ),
      fenix: true,
    );
    // 4. Reporting Service
    Get.lazyPut<ReportingService>(
      () => ReportingService(
        taskDataSource: Get.find<TaskLocalDataSource>(),
        activityDataSource: Get.find<ActivityLocalDataSource>(),
      ),
      fenix: true,
    );
    Get.lazyPut<SettingsRepository>(
      () => SettingsRepositoryImpl(
        dataSource: Get.find<SettingsLocalDataSource>(),
      ),
      fenix: true,
    );
  }
}
