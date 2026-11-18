import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:daily_flow/core/constants/app_constants.dart';
import 'package:daily_flow/data/models/task_occurrence_model.dart';
import 'package:daily_flow/data/models/activity_occurrence_model.dart';
import 'package:daily_flow/data/repositories/activity_repository.dart';
import 'package:daily_flow/data/repositories/settings_repository.dart';
import 'package:daily_flow/data/repositories/task_repository.dart';
import 'package:daily_flow/modules/dashboard/bindings/dashboard_binding.dart';
import 'package:daily_flow/modules/dashboard/views/dashboard_view.dart';
import 'package:daily_flow/modules/dashboard/views/home_tab_view.dart';
import 'package:daily_flow/modules/tasks/views/tasks_view.dart';

// Test mock repositories returning empty occurrences for immediate sync test
class MockTaskRepository extends Fake implements TaskRepository {
  @override
  Future<List<TaskOccurrenceModel>> getOccurrencesForDate(
    String isoDate,
  ) async {
    return [];
  }

  @override
  Future<Map<String, int>> getDailyStats(String isoDate) async {
    return {'total': 0, 'completed': 0, 'pending': 0, 'overdue': 0};
  }

  @override
  Future<List<TaskOccurrenceModel>> getOverdueOccurrences(
    String todayIso,
  ) async {
    return [];
  }

  @override
  Future<List<TaskOccurrenceModel>> getUpcomingOccurrences(
    String fromIsoDate, {
    int limit = 10,
  }) async {
    return [];
  }

  @override
  Future<int> getOverdueCount(String todayIso) async {
    return 0;
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

class MockSettingsRepository extends Fake implements SettingsRepository {
  @override
  Future<ThemeMode> getThemeMode() async => ThemeMode.system;

  @override
  Future<bool> areNotificationsEnabled() async => true;

  @override
  Future<void> setThemeMode(ThemeMode mode) async {}

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {}
}

void main() {
  tearDown(() {
    Get.reset();
  });

  testWidgets('HomeTabView displays app name and dashboard progress', (
    WidgetTester tester,
  ) async {
    Get.put<TaskRepository>(MockTaskRepository());
    Get.put<ActivityRepository>(MockActivityRepository());
    Get.put<SettingsRepository>(MockSettingsRepository());
    DashboardBinding().dependencies();

    await tester.pumpWidget(const GetMaterialApp(home: HomeTabView()));
    await tester.pump();

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('Daily Completion'), findsOneWidget);
    expect(find.text("Today's Timeline"), findsOneWidget);
    expect(find.text('New Task'), findsOneWidget);
  });

  testWidgets('TasksView displays header, filters and search bar', (
    WidgetTester tester,
  ) async {
    Get.put<TaskRepository>(MockTaskRepository());
    Get.put<ActivityRepository>(MockActivityRepository());
    Get.put<SettingsRepository>(MockSettingsRepository());
    DashboardBinding().dependencies();

    await tester.pumpWidget(const GetMaterialApp(home: TasksView()));
    await tester.pump();

    expect(find.text('Task Management'), findsOneWidget);
    expect(find.text('Search tasks by title or note...'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('DashboardView displays bottom navigation with 5 destinations', (
    WidgetTester tester,
  ) async {
    Get.put<TaskRepository>(MockTaskRepository());
    Get.put<ActivityRepository>(MockActivityRepository());
    Get.put<SettingsRepository>(MockSettingsRepository());
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
