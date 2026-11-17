import 'package:flutter/material.dart';

/// Semantic and palette colors for DailyFlow adhering to Material 3 design specs.
class AppColors {
  AppColors._();

  // --- Brand / Primary Palette (Indigo & Blue) ---
  static const Color primaryLight = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryDark = Color(0xFF818CF8); // Indigo 400
  static const Color primaryContainerLight = Color(0xFFEEF2FF);
  static const Color primaryContainerDark = Color(0xFF312E81);

  static const Color secondaryLight = Color(0xFF2563EB); // Blue 600
  static const Color secondaryDark = Color(0xFF60A5FA); // Blue 400

  // --- Status Semantics ---
  // Completed (Green / Emerald)
  static const Color completed = Color(0xFF10B981); // Emerald 500
  static const Color completedLight = Color(0xFF10B981);
  static const Color completedDark = Color(0xFF34D399);
  static const Color completedContainerLight = Color(0xFFD1FAE5);
  static const Color completedContainerDark = Color(0xFF064E3B);

  // Pending (Orange / Amber)
  static const Color pending = Color(0xFFF59E0B); // Amber 500
  static const Color pendingLight = Color(0xFFF59E0B);
  static const Color pendingDark = Color(0xFFFBBF24);
  static const Color pendingContainerLight = Color(0xFFFEF3C7);
  static const Color pendingContainerDark = Color(0xFF78350F);

  // Overdue / Danger (Red / Rose)
  static const Color overdue = Color(0xFFEF4444); // Rose 500
  static const Color overdueLight = Color(0xFFEF4444);
  static const Color overdueDark = Color(0xFFF87171);
  static const Color overdueContainerLight = Color(0xFFFEE2E2);
  static const Color overdueContainerDark = Color(0xFF7F1D1D);

  // --- Light Theme Neutrals ---
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9); // Slate 100
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500
  static const Color textMutedLight = Color(0xFF94A3B8); // Slate 400

  // --- Dark Theme Neutrals ---
  static const Color backgroundDark = Color(0xFF0B0F19); // Deep Slate
  static const Color surfaceDark = Color(0xFF111827); // Gray 900
  static const Color surfaceVariantDark = Color(0xFF1F2937); // Gray 800
  static const Color borderDark = Color(0xFF374151); // Gray 700
  static const Color textPrimaryDark = Color(0xFFF9FAFB); // Slate 50
  static const Color textSecondaryDark = Color(0xFF9CA3AF); // Gray 400
  static const Color textMutedDark = Color(0xFF6B7280); // Gray 500

  // --- Priorities ---
  static const Color priorityLow = Color(0xFF3B82F6); // Blue
  static const Color priorityMedium = Color(0xFFF59E0B); // Amber
  static const Color priorityHigh = Color(0xFFEF4444); // Rose
}
