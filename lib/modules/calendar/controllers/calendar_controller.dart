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

  // Maps date (ISO) to counts of tasks and activities.
  final RxMap<String, Map<String, int>> dailyStats = <String, Map<String, int>>{}.obs;

  void onDaySelected(DateTime selected, DateTime focused) {
    selectedDay.value = selected;
    focusedDay.value = focused;
  }

  String get selectedDateIso => AppDateUtils.toIsoDate(selectedDay.value);

  /// Load counts of tasks and activities for the month that contains `focused`.
  Future<void> loadMonthStats(DateTime focused) async {
    final first = DateTime(focused.year, focused.month, 1);
    final last = DateTime(focused.year, focused.month + 1, 0);
    final startIso = AppDateUtils.toIsoDate(first);
    final endIso = AppDateUtils.toIsoDate(last);
    // Load tasks and activities between dates.
    final taskList = await taskRepository.getOccurrencesBetween(startIso, endIso);
    final activityList = await activityRepository.getOccurrencesBetween(startIso, endIso);

    final Map<String, Map<String, int>> temp = {};
    for (var occ in taskList) {
      final date = occ.occurrenceDate;
      temp.putIfAbsent(date, () => {'tasks': 0, 'activities': 0});
      temp[date]!['tasks'] = (temp[date]!['tasks'] ?? 0) + 1;
    }
    for (var occ in activityList) {
      final date = occ.occurrenceDate;
      temp.putIfAbsent(date, () => {'tasks': 0, 'activities': 0});
      temp[date]!['activities'] = (temp[date]!['activities'] ?? 0) + 1;
    }
    dailyStats.assignAll(temp);
  }

  /// Helper for UI: returns true if a given date has any task or activity.
  bool hasEvents(String isoDate) {
    final stats = dailyStats[isoDate];
    return (stats?['tasks'] ?? 0) > 0 || (stats?['activities'] ?? 0) > 0;
  }
}

