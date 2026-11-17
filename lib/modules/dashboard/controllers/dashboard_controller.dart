import 'package:get/get.dart';
import '../../../data/repositories/activity_repository.dart';
import '../../../data/repositories/task_repository.dart';

/// Controller managing bottom navigation state and top-level dashboard coordination.
class DashboardController extends GetxController {
  final TaskRepository taskRepository;
  final ActivityRepository activityRepository;

  DashboardController({
    required this.taskRepository,
    required this.activityRepository,
  });

  final RxInt currentIndex = 0.obs;

  void changeTabIndex(int index) {
    currentIndex.value = index;
  }
}
