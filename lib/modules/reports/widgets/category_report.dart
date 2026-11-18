import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/donut_chart.dart';
import '../controllers/reports_controller.dart';

/// Category reporting view featuring category distribution chart and detailed category cards.
class CategoryReport extends StatelessWidget {
  const CategoryReport({super.key});

  static const List<Color> _categoryPalette = [
    Color(0xFF4F46E5), // Indigo
    Color(0xFF06B6D4), // Cyan
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Purple
    Color(0xFF3B82F6), // Blue
    Color(0xFF14B8A6), // Teal
  ];

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ReportsController>();
    final theme = Theme.of(context);

    return Obx(() {
      final categories = ctrl.categorySummary;

      if (categories.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Activity Categories Found',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create activities with categories to view detailed category performance.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final segments = List.generate(categories.length, (i) {
        final c = categories[i];
        final name = (c['category'] as String?) ?? 'General';
        final total = (c['total'] as num?)?.toDouble() ?? 0.0;
        final color = _categoryPalette[i % _categoryPalette.length];
        return DonutSegment(label: name, value: total, color: color);
      });

      final totalOccurrences = categories.fold<int>(
        0,
        (sum, c) => sum + ((c['total'] as num?)?.toInt() ?? 0),
      );

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Donut Chart Card
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
                    Text(
                      'Activity Volume by Category',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalOccurrences total tracked occurrences',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Divider(height: 24),
                    DonutChart(
                      height: 180,
                      centerPrimaryText: '$totalOccurrences',
                      centerSecondaryText: 'Occurrences',
                      segments: segments,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category Details List
            Text(
              'Category Performance Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(categories.length, (i) {
              final c = categories[i];
              final name = (c['category'] as String?) ?? 'General';
              final total = (c['total'] as num?)?.toInt() ?? 0;
              final completed = (c['completed'] as num?)?.toInt() ?? 0;
              final pending = (c['pending'] as num?)?.toInt() ?? 0;
              final skipped = (c['skipped'] as num?)?.toInt() ?? 0;
              final pct = (c['completionPct'] as num?)?.toInt() ?? 0;
              final color = _categoryPalette[i % _categoryPalette.length];

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'G',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '$total occurrences total',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: pct >= 80
                                  ? AppColors.completed.withOpacity(0.12)
                                  : (pct > 0
                                        ? theme.colorScheme.primaryContainer
                                        : theme
                                              .colorScheme
                                              .surfaceContainerHighest),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$pct% done',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: pct >= 80
                                    ? AppColors.completed
                                    : (pct > 0
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : completed / total,
                          minHeight: 6,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            pct >= 80 ? AppColors.completed : color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _CategoryStatBadge(
                            label: 'Completed',
                            count: completed,
                            color: AppColors.completed,
                          ),
                          _CategoryStatBadge(
                            label: 'Pending',
                            count: pending,
                            color: AppColors.pending,
                          ),
                          _CategoryStatBadge(
                            label: 'Skipped',
                            count: skipped,
                            color: theme.colorScheme.outline,
                          ),
                        ],
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

class _CategoryStatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CategoryStatBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          '$count',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
