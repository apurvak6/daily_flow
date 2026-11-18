import 'package:get/get.dart';
import '../../../data/repositories/settings_repository.dart';
import '../controllers/settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(
      () => SettingsController(
        settingsRepository: Get.isRegistered<SettingsRepository>()
            ? Get.find<SettingsRepository>()
            : null,
      ),
    );
  }
}
