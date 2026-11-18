import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/reports_controller.dart';
import '../widgets/category_report.dart';
import '../widgets/daily_report.dart';
import '../widgets/history_report.dart';
import '../widgets/weekly_report.dart';

/// Main Reports and Statistics screen featuring 4 tabs:
/// Daily, Weekly, Categories, and History.
class ReportsView extends GetView<ReportsController> {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Statistics & Reports',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Reports',
            onPressed: controller.loadAll,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Segmented Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Obx(
                () => Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.6),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      _TabButton(
                        label: 'Daily',
                        icon: Icons.today_rounded,
                        isSelected: controller.selectedTab.value == 0,
                        onTap: () => controller.changeTab(0),
                      ),
                      _TabButton(
                        label: 'Weekly',
                        icon: Icons.date_range_rounded,
                        isSelected: controller.selectedTab.value == 1,
                        onTap: () => controller.changeTab(1),
                      ),
                      _TabButton(
                        label: 'Categories',
                        icon: Icons.pie_chart_rounded,
                        isSelected: controller.selectedTab.value == 2,
                        onTap: () => controller.changeTab(2),
                      ),
                      _TabButton(
                        label: 'History',
                        icon: Icons.history_rounded,
                        isSelected: controller.selectedTab.value == 3,
                        onTap: () => controller.changeTab(3),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Tab Content
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                switch (controller.selectedTab.value) {
                  case 0:
                    return const DailyReport();
                  case 1:
                    return const WeeklyReport();
                  case 2:
                    return const CategoryReport();
                  case 3:
                    return const HistoryReport();
                  default:
                    return const DailyReport();
                }
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
