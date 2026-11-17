import 'package:get/get.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/activity_occurrence_model.dart';
import '../../../data/repositories/activity_repository.dart';

/// ViewModel controller for recurring activities and habit tracking.
class ActivitiesController extends GetxController {
  final ActivityRepository activityRepository;

  ActivitiesController({required this.activityRepository});

  final RxBool isLoading = false.obs;
  final RxString selectedDate = AppDateUtils.todayIso.obs;
  final RxList<ActivityOccurrenceModel> occurrences =
      <ActivityOccurrenceModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadActivitiesForSelectedDate();
  }

  Future<void> loadActivitiesForSelectedDate() async {
    try {
      isLoading.value = true;
      final results = await activityRepository.getOccurrencesForDate(
        selectedDate.value,
      );
      occurrences.assignAll(results);
    } catch (e, stack) {
      AppLogger.error(
        'Failed to load activities',
        e,
        stack,
        'ActivitiesController',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleActivity(int occurrenceId, bool currentStatus) async {
    try {
      await activityRepository.toggleOccurrenceCompletion(
        occurrenceId,
        !currentStatus,
      );
      await loadActivitiesForSelectedDate();
    } catch (e, stack) {
      AppLogger.error(
        'Failed to toggle activity',
        e,
        stack,
        'ActivitiesController',
      );
    }
  }

  Future<void> logProgress(
    int occurrenceId,
    int actualValue,
    int targetValue,
  ) async {
    try {
      await activityRepository.logOccurrenceProgress(
        occurrenceId,
        actualValue,
        targetValue,
      );
      await loadActivitiesForSelectedDate();
    } catch (e, stack) {
      AppLogger.error(
        'Failed to log activity progress',
        e,
        stack,
        'ActivitiesController',
      );
    }
  }

  void changeDate(String isoDate) {
    selectedDate.value = isoDate;
    loadActivitiesForSelectedDate();
  }
}
