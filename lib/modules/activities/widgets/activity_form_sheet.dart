import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/activity_model.dart';
import '../../calendar/controllers/calendar_controller.dart';
import '../controllers/activities_controller.dart';

/// Modal bottom sheet for creating or editing daily recurring activities with validation.
class ActivityFormSheet extends StatefulWidget {
  final ActivityModel? activityToEdit;

  const ActivityFormSheet({super.key, this.activityToEdit});

  /// Static helper to display the sheet from any context.
  static Future<bool?> show(
    BuildContext context, {
    ActivityModel? activityToEdit,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ActivityFormSheet(activityToEdit: activityToEdit),
    );
  }

  @override
  State<ActivityFormSheet> createState() => _ActivityFormSheetState();
}

class _ActivityFormSheetState extends State<ActivityFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descController;

  late String _category;
  TimeOfDay? _scheduledTime;
  late bool _isReminderEnabled;
  late String _frequency;
  late bool _isActive;
  bool _isSaving = false;

  static const List<String> _activityCategories = [
    'Food',
    'Health',
    'Fitness',
    'Meetings',
    'Medication',
    'Routine',
    'Personal',
    'Others',
  ];

  static const List<String> _presets = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Exercise',
    'Meetings',
    'Medication',
    'Drink Water',
    'Read Book',
  ];

  @override
  void initState() {
    super.initState();
    final act = widget.activityToEdit;

    _titleController = TextEditingController(text: act?.title ?? '');
    _descController = TextEditingController(text: act?.description ?? '');

    _category = act?.category ?? 'Routine';

    if (act?.scheduledTime != null && act!.scheduledTime!.isNotEmpty) {
      _scheduledTime = _parseTimeOfDay(act.scheduledTime!);
    } else {
      _scheduledTime = const TimeOfDay(hour: 8, minute: 0);
    }

    _isReminderEnabled = act?.isReminderEnabled ?? false;
    _frequency = act?.targetFrequency ?? AppConstants.frequencyDaily;
    _isActive = act?.isActive ?? true;
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    try {
      final clean = timeStr.trim();
      final isPm = clean.toUpperCase().contains('PM');
      final isAm = clean.toUpperCase().contains('AM');
      final parts = clean.replaceAll(RegExp(r'[a-zA-Z\s]'), '').split(':');
      int hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      if (isPm && hour < 12) hour += 12;
      if (isAm && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) {
      setState(() => _scheduledTime = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final title = _titleController.text.trim();
      final desc = _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim();
      final formattedTime = _scheduledTime != null
          ? _formatTimeOfDay(_scheduledTime!)
          : null;

      final controller = Get.find<ActivitiesController>();

      if (widget.activityToEdit == null) {
        // Create new
        final newActivity = ActivityModel(
          title: title,
          description: desc,
          category: _category,
          scheduledTime: formattedTime,
          isReminderEnabled: _isReminderEnabled,
          targetFrequency: _frequency,
          isActive: _isActive,
        );
        await controller.createActivity(newActivity);
        if (Get.isRegistered<CalendarController>()) {
          final cal = Get.find<CalendarController>();
          cal.loadSelectedDateDetails(cal.selectedDay.value);
          cal.loadMonthEvents(cal.focusedDay.value);
        }
        Get.back(result: true);
        Get.snackbar(
          'Activity Created',
          '"$title" has been added to your daily routines.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.completed.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 2),
        );
      } else {
        // Update existing
        final updated = widget.activityToEdit!.copyWith(
          title: title,
          description: desc,
          category: _category,
          scheduledTime: formattedTime,
          isReminderEnabled: _isReminderEnabled,
          targetFrequency: _frequency,
          isActive: _isActive,
        );
        await controller.updateActivity(updated);
        if (Get.isRegistered<CalendarController>()) {
          final cal = Get.find<CalendarController>();
          cal.loadSelectedDateDetails(cal.selectedDay.value);
          cal.loadMonthEvents(cal.focusedDay.value);
        }
        Get.back(result: true);
        Get.snackbar(
          'Activity Updated',
          '"$title" changes saved successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Save Error',
        'Could not save activity: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.activityToEdit != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      bottom: true,
      left: false,
      right: false,
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(bottom: bottomInset),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Activity' : 'New Daily Activity',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Form body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preset suggestions chips (when creating new)
                      if (!isEditing) ...[
                        Text(
                          'Quick Suggestions',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 34,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _presets.length,
                            separatorBuilder: (_, index) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final preset = _presets[index];
                              return ActionChip(
                                label: Text(preset),
                                labelStyle: const TextStyle(fontSize: 12),
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  setState(() {
                                    _titleController.text = preset;
                                    if (preset == 'Breakfast' ||
                                        preset == 'Lunch' ||
                                        preset == 'Dinner') {
                                      _category = 'Food';
                                    } else if (preset == 'Medication') {
                                      _category = 'Medication';
                                    } else if (preset == 'Exercise') {
                                      _category = 'Fitness';
                                    } else if (preset == 'Meetings') {
                                      _category = 'Meetings';
                                    } else if (preset == "Read Book") {
                                      _category = "Personal";
                                    } else if (preset == "Drink Water") {
                                      _category = "Routine";
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Title Field
                      Text(
                        'Activity Title *',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        maxLength: 60,
                        decoration: InputDecoration(
                          hintText: 'e.g., Morning Exercise, Take Vitamins',
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.fitness_center_rounded),
                          counterText: '',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Activity title is required';
                          }
                          final trimmed = value.trim();
                          if (trimmed.length < 3) {
                            return 'Title must be at least 3 characters';
                          }
                          if (trimmed.length > 60) {
                            return 'Title cannot exceed 60 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Category Selector
                      Text(
                        'Category',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _activityCategories.map((cat) {
                          final isSelected = _category == cat;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) setState(() => _category = cat);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Scheduled Time Picker
                      Text(
                        'Scheduled Time',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _scheduledTime != null
                                    ? _formatTimeOfDay(_scheduledTime!)
                                    : 'Select Time',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Change',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Frequency Selector
                      Text(
                        'Frequency',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Every Day')),
                              selected:
                                  _frequency == AppConstants.frequencyDaily,
                              onSelected: (val) {
                                if (val) {
                                  setState(
                                    () => _frequency =
                                        AppConstants.frequencyDaily,
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Weekdays Only')),
                              selected:
                                  _frequency == AppConstants.frequencyWeekdays,
                              onSelected: (val) {
                                if (val) {
                                  setState(
                                    () => _frequency =
                                        AppConstants.frequencyWeekdays,
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Reminders & Active Switches
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Daily Reminder'),
                              subtitle: const Text(
                                'Receive a notification at scheduled time',
                              ),
                              secondary: Icon(
                                Icons.notifications_active_rounded,
                                color: _isReminderEnabled
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              value: _isReminderEnabled,
                              onChanged: (val) =>
                                  setState(() => _isReminderEnabled = val),
                            ),
                            if (isEditing) ...[
                              const Divider(height: 1),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Active Status'),
                                subtitle: const Text(
                                  'Inactive activities pause occurrence generation',
                                ),
                                secondary: Icon(
                                  _isActive
                                      ? Icons.check_circle_rounded
                                      : Icons.pause_circle_outline_rounded,
                                  color: _isActive
                                      ? AppColors.completed
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                value: _isActive,
                                onChanged: (val) =>
                                    setState(() => _isActive = val),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description (Optional)
                      Text(
                        'Description (Optional)',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descController,
                        maxLines: 2,
                        maxLength: 120,
                        decoration: InputDecoration(
                          hintText: 'Additional details or notes...',
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: _isSaving ? null : _submitForm,
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  isEditing
                                      ? 'Save Changes'
                                      : 'Create Activity',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
