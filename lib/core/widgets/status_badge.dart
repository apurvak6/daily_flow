import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

enum BadgeStatus {
  completed,
  pending,
  overdue,
  priorityLow,
  priorityMedium,
  priorityHigh,
}

/// Reusable status badge chip adhering to design specs:
/// Green for completed, Orange for pending, Red for overdue.
class StatusBadge extends StatelessWidget {
  final BadgeStatus status;
  final String? customLabel;

  const StatusBadge({super.key, required this.status, this.customLabel});

  @override
  Widget build(BuildContext context) {
    final (label, textColor, bgColor) = _resolveStyle();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        customLabel ?? label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  (String label, Color text, Color bg) _resolveStyle() {
    switch (status) {
      case BadgeStatus.completed:
        return (
          'Completed',
          AppColors.completed,
          AppColors.completedContainerLight,
        );
      case BadgeStatus.pending:
        return ('Pending', AppColors.pending, AppColors.pendingContainerLight);
      case BadgeStatus.overdue:
        return ('Overdue', AppColors.overdue, AppColors.overdueContainerLight);
      case BadgeStatus.priorityLow:
        return ('Low', AppColors.priorityLow, AppColors.primaryContainerLight);
      case BadgeStatus.priorityMedium:
        return (
          'Medium',
          AppColors.priorityMedium,
          AppColors.pendingContainerLight,
        );
      case BadgeStatus.priorityHigh:
        return (
          'High',
          AppColors.priorityHigh,
          AppColors.overdueContainerLight,
        );
    }
  }
}
