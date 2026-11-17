import 'package:get/get.dart';
import '../../../data/repositories/activity_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../controllers/reports_controller.dart';

class ReportsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReportsController>(
      () => ReportsController(
        taskRepository: Get.find<TaskRepository>(),
        activityRepository: Get.find<ActivityRepository>(),
      ),
    );
  }
}
