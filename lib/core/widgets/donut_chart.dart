import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Data class representing an entry in a DonutChart with a legend.
class DonutSegment {
  final String label;
  final double value;
  final Color color;

  const DonutSegment({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Responsive Donut Chart with center value, tooltips, and optional legend.
class DonutChart extends StatelessWidget {
  final List<DonutSegment> segments;
  final String? centerPrimaryText;
  final String? centerSecondaryText;
  final double height;
  final double donutWidth;
  final bool showLegend;

  const DonutChart({
    super.key,
    required this.segments,
    this.centerPrimaryText,
    this.centerSecondaryText,
    this.height = 180,
    this.donutWidth = 24,
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = segments.fold<double>(0, (sum, s) => sum + s.value);

    if (total == 0) {
      return SizedBox(
        height: height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart_outline_rounded,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
              ),
              const SizedBox(height: 8),
              Text(
                'No data recorded for this period',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final pieSections = segments
        .where((s) => s.value > 0)
        .map(
          (s) => PieChartSectionData(
            value: s.value,
            color: s.color,
            radius: donutWidth,
            showTitle: false,
          ),
        )
        .toList();

    return Column(
      children: [
        SizedBox(
          height: height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: pieSections,
                  centerSpaceRadius: 52,
                  sectionsSpace: 3,
                  startDegreeOffset: -90,
                ),
              ),
              if (centerPrimaryText != null)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      centerPrimaryText!,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (centerSecondaryText != null)
                      Text(
                        centerSecondaryText!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        if (showLegend) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: segments.map((s) {
              final pct = total == 0 ? 0 : (s.value * 100 ~/ total);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: s.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${s.label}: ${s.value.toInt()} ($pct%)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
