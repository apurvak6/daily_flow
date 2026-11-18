import 'package:get/get.dart';
import '../../../core/services/reporting_service.dart';
import '../../../data/datasources/activity_local_datasource.dart';
import '../../../data/datasources/task_local_datasource.dart';
import '../../../data/repositories/activity_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../reports/controllers/reports_controller.dart';

class ReportsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ReportingService>()) {
      Get.lazyPut<ReportingService>(
        () => ReportingService(
          taskDataSource: Get.find<TaskLocalDataSource>(),
          activityDataSource: Get.find<ActivityLocalDataSource>(),
        ),
      );
    }

    Get.lazyPut<ReportsController>(
      () => ReportsController(
        taskRepository: Get.find<TaskRepository>(),
        activityRepository: Get.find<ActivityRepository>(),
        reportingService: Get.find<ReportingService>(),
      ),
    );
  }
}
