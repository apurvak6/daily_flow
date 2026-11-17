import 'package:get/get.dart';
import '../../../data/repositories/activity_repository.dart';
import '../../../data/repositories/task_repository.dart';

/// ViewModel controller for analytics, completion rates, and reports.
class ReportsController extends GetxController {
  final TaskRepository taskRepository;
  final ActivityRepository activityRepository;

  ReportsController({
    required this.taskRepository,
    required this.activityRepository,
  });

  final RxInt selectedTimeframeIndex = 0.obs; // 0: Daily, 1: Weekly
  final RxBool isLoading = false.obs;

  void changeTimeframe(int index) {
    selectedTimeframeIndex.value = index;
  }
}
