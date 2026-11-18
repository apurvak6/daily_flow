import 'package:daily_flow/core/services/reporting_service.dart';
import 'package:get/get.dart';
import '../../../data/repositories/activity_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../controllers/dashboard_controller.dart';
import '../../tasks/controllers/tasks_controller.dart';
import '../../activities/controllers/activities_controller.dart';
import '../../calendar/controllers/calendar_controller.dart';
import '../../reports/controllers/reports_controller.dart';
import '../../settings/controllers/settings_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(
      () => DashboardController(
        taskRepository: Get.find<TaskRepository>(),
        activityRepository: Get.find<ActivityRepository>(),
      ),
    );
    Get.lazyPut<TasksController>(
      () => TasksController(taskRepository: Get.find<TaskRepository>()),
    );
    Get.lazyPut<ActivitiesController>(
      () => ActivitiesController(
        activityRepository: Get.find<ActivityRepository>(),
      ),
    );
    Get.lazyPut<CalendarController>(
      () => CalendarController(
        taskRepository: Get.find<TaskRepository>(),
        activityRepository: Get.find<ActivityRepository>(),
      ),
    );
    if (!Get.isRegistered<ReportingService>()) {
      Get.lazyPut<ReportingService>(() => ReportingService());
    }
    Get.lazyPut<ReportsController>(
      () => ReportsController(
        taskRepository: Get.find<TaskRepository>(),
        activityRepository: Get.find<ActivityRepository>(),
        reportingService: Get.isRegistered<ReportingService>()
            ? Get.find<ReportingService>()
            : ReportingService(),
      ),
    );
    Get.lazyPut<SettingsController>(
      () => SettingsController(
        settingsRepository: Get.isRegistered<SettingsRepository>()
            ? Get.find<SettingsRepository>()
            : null,
      ),
    );
  }
}
