import 'package:get/get.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/repositories/activity_repository.dart';
import '../../../data/repositories/task_repository.dart';

/// ViewModel controller for calendar view and event mapping.
class CalendarController extends GetxController {
  final TaskRepository taskRepository;
  final ActivityRepository activityRepository;

  CalendarController({
    required this.taskRepository,
    required this.activityRepository,
  });

  final Rx<DateTime> focusedDay = DateTime.now().obs;
  final Rx<DateTime> selectedDay = DateTime.now().obs;

  void onDaySelected(DateTime selected, DateTime focused) {
    selectedDay.value = selected;
    focusedDay.value = focused;
  }

  String get selectedDateIso => AppDateUtils.toIsoDate(selectedDay.value);
}
