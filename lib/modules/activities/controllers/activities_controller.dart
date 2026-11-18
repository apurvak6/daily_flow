import 'package:get/get.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/models/activity_occurrence_model.dart';
import '../../../data/repositories/activity_repository.dart';

/// ViewModel controller for recurring activities and habit tracking.
class ActivitiesController extends GetxController {
  final ActivityRepository activityRepository;

  ActivitiesController({required this.activityRepository});

  final RxBool isLoading = false.obs;
  final RxString selectedDate = AppDateUtils.todayIso.obs;
  final RxList<ActivityOccurrenceModel> occurrences = <ActivityOccurrenceModel>[].obs;
  final RxList<ActivityModel> allActivities = <ActivityModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAllActivities();
    loadActivitiesForSelectedDate();
  }

  // Load activity definitions (for dropdowns, creation UI, etc.)
  Future<void> loadAllActivities() async {
    try {
      final list = await activityRepository.getAllActivities();
      allActivities.assignAll(list);
    } catch (e, stack) {
      AppLogger.error('Failed to load activity definitions', e, stack, 'ActivitiesController');
    }
  }

  // Load occurrences for the currently selected date.
  Future<void> loadActivitiesForSelectedDate() async {
    try {
      isLoading.value = true;
      final results = await activityRepository.getOccurrencesForDate(selectedDate.value);
      occurrences.assignAll(results);
    } catch (e, stack) {
      AppLogger.error('Failed to load activities', e, stack, 'ActivitiesController');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleActivity(int occurrenceId, bool currentStatus) async {
    try {
      await activityRepository.toggleOccurrenceCompletion(occurrenceId, !currentStatus);
      await loadActivitiesForSelectedDate();
    } catch (e, stack) {
      AppLogger.error('Failed to toggle activity', e, stack, 'ActivitiesController');
    }
  }

  Future<void> skipActivity(int occurrenceId) async {
    try {
      await activityRepository.skipOccurrence(occurrenceId);
      await loadActivitiesForSelectedDate();
    } catch (e, stack) {
      AppLogger.error('Failed to skip activity', e, stack, 'ActivitiesController');
    }
  }

  Future<void> logProgress(int occurrenceId, int actualValue, int targetValue) async {
    try {
      await activityRepository.logOccurrenceProgress(occurrenceId, actualValue, targetValue);
      await loadActivitiesForSelectedDate();
    } catch (e, stack) {
      AppLogger.error('Failed to log activity progress', e, stack, 'ActivitiesController');
    }
  }

  Future<void> createActivity(ActivityModel activity) async {
    try {
      await activityRepository.createActivity(activity);
      await loadAllActivities();
      await loadActivitiesForSelectedDate();
    } catch (e, stack) {
      AppLogger.error('Failed to create activity', e, stack, 'ActivitiesController');
    }
  }

  Future<void> updateActivity(ActivityModel activity) async {
    try {
      await activityRepository.updateActivity(activity);
      await loadAllActivities();
      await loadActivitiesForSelectedDate();
    } catch (e, stack) {
      AppLogger.error('Failed to update activity', e, stack, 'ActivitiesController');
    }
  }

  Future<void> deleteActivity(int activityId) async {
    try {
      await activityRepository.deleteActivity(activityId);
      await loadAllActivities();
      await loadActivitiesForSelectedDate();
    } catch (e, stack) {
      AppLogger.error('Failed to delete activity', e, stack, 'ActivitiesController');
    }
  }

  void changeDate(String isoDate) {
    selectedDate.value = isoDate;
    loadActivitiesForSelectedDate();
  }
}
