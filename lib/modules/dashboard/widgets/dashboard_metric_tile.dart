import 'package:flutter/material.dart';
import '../../../core/widgets/custom_card.dart';

/// Reusable metric counter card for Dashboard statistics.
class DashboardMetricTile extends StatelessWidget {
  final String label;
  final int count;
  // final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const DashboardMetricTile({
    super.key,
    required this.label,
    required this.count,
    // required this.icon,
    required this.color,
    required this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: CustomCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        borderRadius: 14,
        color: backgroundColor,
        customBorder: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon(icon, size: 18, color: color),
                Text(
                  '$count',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
