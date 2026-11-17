import 'package:get/get.dart';
import '../../../data/repositories/task_repository.dart';
import '../controllers/tasks_controller.dart';

class TasksBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TasksController>(
      () => TasksController(taskRepository: Get.find<TaskRepository>()),
    );
  }
}
