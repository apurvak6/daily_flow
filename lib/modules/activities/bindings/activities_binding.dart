import 'package:get/get.dart';
import '../../../data/repositories/activity_repository.dart';
import '../controllers/activities_controller.dart';

class ActivitiesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ActivitiesController>(
      () => ActivitiesController(
        activityRepository: Get.find<ActivityRepository>(),
      ),
    );
  }
}
