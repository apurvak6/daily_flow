import 'package:get/get.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/notification_service.dart';
import '../../data/datasources/activity_local_datasource.dart';
import '../../data/datasources/task_local_datasource.dart';
import '../../data/repositories/activity_repository.dart';
import '../../data/repositories/task_repository.dart';

/// Central dependency injection binding for application startup.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Core Services & Database
    Get.put<DatabaseHelper>(DatabaseHelper.instance, permanent: true);
    Get.put<NotificationService>(NotificationService(), permanent: true);

    // 2. Data Sources
    Get.lazyPut<TaskLocalDataSource>(
      () => TaskLocalDataSourceImpl(dbHelper: Get.find<DatabaseHelper>()),
      fenix: true,
    );
    Get.lazyPut<ActivityLocalDataSource>(
      () => ActivityLocalDataSourceImpl(dbHelper: Get.find<DatabaseHelper>()),
      fenix: true,
    );

    // 3. Domain Repositories
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
  }
}
