import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/reports_controller.dart';

/// Weekly reporting view featuring week navigation, weekly bar chart, and daily comparison.
class WeeklyReport extends StatelessWidget {
  const WeeklyReport({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ReportsController>();
    final theme = Theme.of(context);

    return Obx(() {
      final week = ctrl.weeklyStats;
      final daily = (week['daily'] as List<dynamic>?) ?? [];

      final weekTaskCompleted = week['weekTaskCompleted'] ?? 0;
      final weekTaskTotal = week['weekTaskTotal'] ?? 0;
      final weekTaskPending = week['weekTaskPending'] ?? 0;
      final weekTaskOverdue = week['weekTaskOverdue'] ?? 0;
      final weekTaskPct = week['weekTaskCompletionPct'] ?? 0;

      final weekActCompleted = week['weekActivityCompleted'] ?? 0;
      final weekActTotal = week['weekActivityTotal'] ?? 0;
      final weekActPct = week['weekActivityCompletionPct'] ?? 0;

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Week Navigator Bar
            _WeekNavigatorBar(controller: ctrl),
            const SizedBox(height: 16),

            // Weekly Summary Metric Cards
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Tasks Done',
                    value: '$weekTaskCompleted / $weekTaskTotal',
                    subtitle: '$weekTaskPct% completed',
                    color: AppColors.completed,
                    icon: Icons.check_circle_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricCard(
                    title: 'Pending',
                    value: '$weekTaskPending',
                    subtitle: 'Tasks in week',
                    color: AppColors.pending,
                    icon: Icons.hourglass_empty_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricCard(
                    title: 'Overdue',
                    value: '$weekTaskOverdue',
                    subtitle: 'Tasks flagged',
                    color: AppColors.overdue,
                    icon: Icons.error_outline_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Activities Completed',
                    value: '$weekActCompleted / $weekActTotal',
                    subtitle: '$weekActPct% occurrence rate',
                    color: theme.colorScheme.primary,
                    icon: Icons.local_fire_department_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bar Chart Section
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daily Task Completion (%)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Mon – Sun',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 200,
                      child: daily.isEmpty
                          ? Center(
                              child: Text(
                                'No data for this week',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : BarChart(
                              BarChartData(
                                maxY: 100,
                                minY: 0,
                                alignment: BarChartAlignment.spaceAround,
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 25,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: theme.colorScheme.outlineVariant
                                        .withOpacity(0.5),
                                    strokeWidth: 1,
                                    dashArray: [4, 4],
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 32,
                                      interval: 25,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          '${value.toInt()}%',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                fontSize: 10,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        );
                                      },
                                    ),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 28,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index >= 0 &&
                                            index < daily.length) {
                                          final dayName =
                                              daily[index]['dayName'] ?? '';
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 6,
                                            ),
                                            child: Text(
                                              dayName,
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ),
                                ),
                                barGroups: List.generate(daily.length, (index) {
                                  final d = daily[index];
                                  final pct =
                                      (d['completionPct'] as num?)
                                          ?.toDouble() ??
                                      0.0;
                                  return BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: pct,
                                        color: pct >= 80
                                            ? AppColors.completed
                                            : (pct > 0
                                                  ? theme.colorScheme.primary
                                                  : theme
                                                        .colorScheme
                                                        .outlineVariant),
                                        width: 18,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(6),
                                          topRight: Radius.circular(6),
                                        ),
                                        backDrawRodData:
                                            BackgroundBarChartRodData(
                                              show: true,
                                              toY: 100,
                                              color: theme
                                                  .colorScheme
                                                  .surfaceContainerHighest
                                                  .withOpacity(0.4),
                                            ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Daily Comparison Breakdown
            Text(
              'Daily Progress Comparison',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...daily.map((d) {
              final dayName = d['dayName'] ?? '';
              final dateStr = d['date'] ?? '';
              final tDone = d['taskCompleted'] ?? 0;
              final tTot = d['taskTotal'] ?? 0;
              final tPct = d['completionPct'] ?? 0;
              final aDone = d['activityCompleted'] ?? 0;
              final aTot = d['activityTotal'] ?? 0;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  dayName,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dateStr,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Tasks: $tDone/$tTot  •  Activities: $aDone/$aTot',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            '$tPct%',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: tPct >= 80
                                  ? AppColors.completed
                                  : (tPct > 0
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: tTot == 0 ? 0 : tDone / tTot,
                          minHeight: 6,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            tPct >= 80
                                ? AppColors.completed
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      );
    });
  }
}

class _WeekNavigatorBar extends StatelessWidget {
  final ReportsController controller;

  const _WeekNavigatorBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Previous week',
            onPressed: controller.goToPreviousWeek,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.date_range_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  controller.weekRangeLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: controller.goToCurrentWeek,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(50, 36),
            ),
            child: const Text('This Week'),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Next week',
            onPressed: controller.goToNextWeek,
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      color: color.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
