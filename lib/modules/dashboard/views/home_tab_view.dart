import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../controllers/dashboard_controller.dart';

/// Initial Home Tab View for the Dashboard shell.
class HomeTabView extends GetView<DashboardController> {
  const HomeTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.appName,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              AppConstants.appTagline,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CustomCard(
              color: theme.colorScheme.primaryContainer,
              child: Row(
                children: [
                  Icon(Icons.bolt, size: 32, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ready for Setup & Development',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SQLite, GetX, Repositories, and Theme configured cleanly.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            EmptyStateWidget(
              icon: Icons.dashboard_outlined,
              title: 'Welcome to DailyFlow',
              description:
                  'Project architecture and database setup initialized. Ready for Phase 2 UI implementation.',
              actionLabel: 'Go to Tasks',
              onAction: () => controller.changeTabIndex(1),
            ),
          ],
        ),
      ),
    );
  }
}
