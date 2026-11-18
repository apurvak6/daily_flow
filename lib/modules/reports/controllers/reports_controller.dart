import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/services/reporting_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/activity_occurrence_model.dart';
import '../../../data/models/task_occurrence_model.dart';
import '../../../data/repositories/activity_repository.dart';
import '../../../data/repositories/task_repository.dart';

/// ViewModel controller for analytics, completion rates, and reports.
class ReportsController extends GetxController {
  final TaskRepository taskRepository;
  final ActivityRepository activityRepository;
  final ReportingService reportingService;

  ReportsController({
    required this.taskRepository,
    required this.activityRepository,
    ReportingService? reportingService,
  }) : reportingService =
           reportingService ??
           (Get.isRegistered<ReportingService>()
               ? Get.find<ReportingService>()
               : ReportingService());

  // UI state
  final RxBool isLoading = false.obs;
  final RxInt selectedTab =
      0.obs; // 0: Daily, 1: Weekly, 2: Categories, 3: History

  // Daily & History selected date
  final RxString selectedDate = AppDateUtils.todayIso.obs;

  // Weekly selected week (Monday)
  late final Rx<DateTime> currentWeekMonday;

  // Stats data
  final RxMap<String, int> dailyStats = <String, int>{}.obs;
  final RxMap<String, dynamic> weeklyStats = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> categorySummary =
      <Map<String, dynamic>>[].obs;

  // History data
  final RxList<TaskOccurrenceModel> historyTasks = <TaskOccurrenceModel>[].obs;
  final RxList<ActivityOccurrenceModel> historyActivities =
      <ActivityOccurrenceModel>[].obs;
  final RxString historyFilter = 'All'.obs; // All, Tasks, Activities

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    currentWeekMonday = DateTime(monday.year, monday.month, monday.day).obs;
    loadAll();
  }

  void changeTab(int index) {
    selectedTab.value = index;
    switch (index) {
      case 0:
        loadDailyStats();
        break;
      case 1:
        loadWeeklyStats();
        break;
      case 2:
        loadCategoryStats();
        break;
      case 3:
        loadHistory();
        break;
    }
  }

  // --- Daily Navigation ---
  void changeDate(String isoDate) {
    selectedDate.value = isoDate;
    if (selectedTab.value == 0) {
      loadDailyStats();
    } else if (selectedTab.value == 3) {
      loadHistory();
    }
  }

  void goToPreviousDay() {
    final current = DateTime.parse(selectedDate.value);
    final prev = current.subtract(const Duration(days: 1));
    changeDate(prev.toIso8601String().substring(0, 10));
  }

  void goToNextDay() {
    final current = DateTime.parse(selectedDate.value);
    final next = current.add(const Duration(days: 1));
    changeDate(next.toIso8601String().substring(0, 10));
  }

  void goToToday() {
    changeDate(AppDateUtils.todayIso);
  }

  // --- Weekly Navigation ---
  String get weekRangeLabel {
    final start = currentWeekMonday.value;
    final end = start.add(const Duration(days: 6));
    final startFmt = DateFormat('MMM d').format(start);
    final endFmt = DateFormat('MMM d, yyyy').format(end);
    return '$startFmt – $endFmt';
  }

  void goToPreviousWeek() {
    currentWeekMonday.value = currentWeekMonday.value.subtract(
      const Duration(days: 7),
    );
    loadWeeklyStats();
  }

  void goToNextWeek() {
    currentWeekMonday.value = currentWeekMonday.value.add(
      const Duration(days: 7),
    );
    loadWeeklyStats();
  }

  void goToCurrentWeek() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    currentWeekMonday.value = DateTime(monday.year, monday.month, monday.day);
    loadWeeklyStats();
  }

  // --- History Filter ---
  void setHistoryFilter(String filter) {
    historyFilter.value = filter;
  }

  // --- Data Fetching ---
  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      await Future.wait([
        loadDailyStats(refreshState: false),
        loadWeeklyStats(refreshState: false),
        loadCategoryStats(refreshState: false),
        loadHistory(refreshState: false),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadDailyStats({bool refreshState = true}) async {
    if (refreshState) isLoading.value = true;
    try {
      final stats = await reportingService.getDailyStats(selectedDate.value);
      dailyStats.assignAll(stats);
    } finally {
      if (refreshState) isLoading.value = false;
    }
  }

  Future<void> loadWeeklyStats({bool refreshState = true}) async {
    if (refreshState) isLoading.value = true;
    try {
      final isoStart = currentWeekMonday.value.toIso8601String().substring(
        0,
        10,
      );
      final week = await reportingService.getWeeklyStats(isoStart);
      weeklyStats.assignAll(week);
    } finally {
      if (refreshState) isLoading.value = false;
    }
  }

  Future<void> loadCategoryStats({bool refreshState = true}) async {
    if (refreshState) isLoading.value = true;
    try {
      final cat = await reportingService.getCategoryActivitySummary();
      categorySummary.assignAll(cat);
    } finally {
      if (refreshState) isLoading.value = false;
    }
  }

  Future<void> loadHistory({bool refreshState = true}) async {
    if (refreshState) isLoading.value = true;
    try {
      final history = await reportingService.getHistoryForDate(
        selectedDate.value,
      );
      final tasks =
          (history['tasks'] as List<dynamic>?)?.cast<TaskOccurrenceModel>() ??
          [];
      final activities =
          (history['activities'] as List<dynamic>?)
              ?.cast<ActivityOccurrenceModel>() ??
          [];
      historyTasks.assignAll(tasks);
      historyActivities.assignAll(activities);
    } finally {
      if (refreshState) isLoading.value = false;
    }
  }
}
