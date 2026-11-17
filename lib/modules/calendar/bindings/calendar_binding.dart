import 'package:get/get.dart';
import '../../../data/repositories/activity_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../controllers/calendar_controller.dart';

class CalendarBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CalendarController>(
      () => CalendarController(
        taskRepository: Get.find<TaskRepository>(),
        activityRepository: Get.find<ActivityRepository>(),
      ),
    );
  }
}
