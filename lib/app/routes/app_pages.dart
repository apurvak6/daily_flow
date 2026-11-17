import 'package:get/get.dart';
import '../../modules/activities/bindings/activities_binding.dart';
import '../../modules/activities/views/activities_view.dart';
import '../../modules/calendar/bindings/calendar_binding.dart';
import '../../modules/calendar/views/calendar_view.dart';
import '../../modules/dashboard/bindings/dashboard_binding.dart';
import '../../modules/dashboard/views/dashboard_view.dart';
import '../../modules/reports/bindings/reports_binding.dart';
import '../../modules/reports/views/reports_view.dart';
import '../../modules/settings/bindings/settings_binding.dart';
import '../../modules/settings/views/settings_view.dart';
import '../../modules/tasks/bindings/tasks_binding.dart';
import '../../modules/tasks/views/tasks_view.dart';
import 'app_routes.dart';

/// Centralized route definitions and page bindings for GetX navigation.
class AppPages {
  AppPages._();

  static const initial = Routes.dashboard;

  static final List<GetPage> routes = [
    GetPage(
      name: Routes.dashboard,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: Routes.tasks,
      page: () => const TasksView(),
      binding: TasksBinding(),
    ),
    GetPage(
      name: Routes.activities,
      page: () => const ActivitiesView(),
      binding: ActivitiesBinding(),
    ),
    GetPage(
      name: Routes.calendar,
      page: () => const CalendarView(),
      binding: CalendarBinding(),
    ),
    GetPage(
      name: Routes.reports,
      page: () => const ReportsView(),
      binding: ReportsBinding(),
    ),
    GetPage(
      name: Routes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
  ];
}
