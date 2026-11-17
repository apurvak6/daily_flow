import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:daily_flow/core/constants/app_constants.dart';
import 'package:daily_flow/data/models/task_occurrence_model.dart';
import 'package:daily_flow/data/models/activity_occurrence_model.dart';
import 'package:daily_flow/data/repositories/activity_repository.dart';
import 'package:daily_flow/data/repositories/task_repository.dart';
import 'package:daily_flow/modules/dashboard/bindings/dashboard_binding.dart';
import 'package:daily_flow/modules/dashboard/views/dashboard_view.dart';
import 'package:daily_flow/modules/dashboard/views/home_tab_view.dart';

// Test mock repositories returning empty occurrences for immediate sync test
class MockTaskRepository extends Fake implements TaskRepository {
  @override
  Future<List<TaskOccurrenceModel>> getOccurrencesForDate(
    String isoDate,
  ) async {
    return [];
  }
}

class MockActivityRepository extends Fake implements ActivityRepository {
  @override
  Future<List<ActivityOccurrenceModel>> getOccurrencesForDate(
    String isoDate,
  ) async {
    return [];
  }
}

void main() {
  tearDown(() {
    Get.reset();
  });

  testWidgets('HomeTabView displays app name and welcome card', (
    WidgetTester tester,
  ) async {
    Get.put<TaskRepository>(MockTaskRepository());
    Get.put<ActivityRepository>(MockActivityRepository());
    DashboardBinding().dependencies();

    await tester.pumpWidget(const GetMaterialApp(home: HomeTabView()));
    await tester.pump();

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('Welcome to DailyFlow'), findsOneWidget);
    expect(find.text('Go to Tasks'), findsOneWidget);
  });

  testWidgets('DashboardView displays bottom navigation with 5 destinations', (
    WidgetTester tester,
  ) async {
    Get.put<TaskRepository>(MockTaskRepository());
    Get.put<ActivityRepository>(MockActivityRepository());
    DashboardBinding().dependencies();

    await tester.pumpWidget(const GetMaterialApp(home: DashboardView()));
    await tester.pump();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
