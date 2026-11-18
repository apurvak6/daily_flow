import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/task_model.dart';
import '../controllers/tasks_controller.dart';

/// Modal bottom sheet for creating or editing tasks with comprehensive inline validation.
class TaskFormSheet extends StatefulWidget {
  final TaskModel? taskToEdit;
  final String? initialDateIso;

  const TaskFormSheet({super.key, this.taskToEdit, this.initialDateIso});

  /// Static helper to display the sheet from any context.
  static Future<bool?> show(
    BuildContext context, {
    TaskModel? taskToEdit,
    String? initialDateIso,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          TaskFormSheet(taskToEdit: taskToEdit, initialDateIso: initialDateIso),
    );
  }

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descController;

  late String _category;
  late String _priority;
  late DateTime _dueDate;
  late TimeOfDay _dueTime;
  late bool _hasReminder;
  late String _recurrenceType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final task = widget.taskToEdit;

    _titleController = TextEditingController(text: task?.title ?? '');
    _descController = TextEditingController(text: task?.description ?? '');

    _category = task?.category ?? AppConstants.defaultTaskCategories.first;
    _priority = task?.priority ?? AppConstants.priorityMedium;

    if (task?.dueDate != null) {
      _dueDate = AppDateUtils.fromIsoDate(task!.dueDate!);
    } else if (widget.initialDateIso != null) {
      _dueDate = AppDateUtils.fromIsoDate(widget.initialDateIso!);
    } else {
      _dueDate = AppDateUtils.today;
    }

    if (task?.dueTime != null) {
      final parts = task!.dueTime!.split(':');
      _dueTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    } else {
      _dueTime = const TimeOfDay(hour: 9, minute: 0);
    }

    _hasReminder = task?.reminderTime != null;
    _recurrenceType = task?.recurrenceType ?? AppConstants.recurrenceNone;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime,
    );
    if (picked != null) {
      setState(() => _dueTime = picked);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDisplayTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat(AppConstants.timeFormat12).format(dt);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final isoDate = AppDateUtils.toIsoDate(_dueDate);
    final timeStr = _formatTimeOfDay(_dueTime);
    final isRecurring = _recurrenceType != AppConstants.recurrenceNone;

    final tasksController = TasksController.to;

    bool success = false;
    if (widget.taskToEdit == null) {
      // 1. Create Task
      final newTask = TaskModel(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        category: _category,
        priority: _priority,
        dueDate: isoDate,
        dueTime: timeStr,
        isRecurring: isRecurring,
        recurrenceType: _recurrenceType,
        reminderTime: _hasReminder ? timeStr : null,
      );
      success = await tasksController.createTask(newTask);
    } else {
      // 2. Edit Task
      final updatedTask = widget.taskToEdit!.copyWith(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        category: _category,
        priority: _priority,
        dueDate: isoDate,
        dueTime: timeStr,
        isRecurring: isRecurring,
        recurrenceType: _recurrenceType,
        reminderTime: _hasReminder ? timeStr : null,
      );
      success = await tasksController.updateTask(updatedTask);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.of(context).pop(true);
        Get.snackbar(
          widget.taskToEdit == null ? 'Task Created' : 'Task Updated',
          '${_titleController.text.trim()} saved successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surfaceLight,
          colorText: AppColors.textPrimaryLight,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.taskToEdit != null;

    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Task' : 'New Task',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 1. Title Input
              Text(
                'Title *',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                maxLength: 60,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'e.g. Prepare architecture slides',
                  counterText: '',
                  prefixIcon: Icon(
                    Icons.edit_note_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Task title is required';
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

              // 2. Description Input
              Text(
                'Description (optional)',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                maxLength: 250,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Add notes or details...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              // 3. Category Selector
              Text(
                'Category',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AppConstants.defaultTaskCategories.map((cat) {
                  final isSelected = _category == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _category = cat);
                    },
                    selectedColor: theme.colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 4. Priority Selector
              Text(
                'Priority',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildPriorityChip(
                    'Low',
                    AppConstants.priorityLow,
                    AppColors.priorityLow,
                  ),
                  const SizedBox(width: 8),
                  _buildPriorityChip(
                    'Medium',
                    AppConstants.priorityMedium,
                    AppColors.priorityMedium,
                  ),
                  const SizedBox(width: 8),
                  _buildPriorityChip(
                    'High',
                    AppConstants.priorityHigh,
                    AppColors.priorityHigh,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 5. Date & Time Selection
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Due Date',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: theme.colorScheme.outline.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppDateUtils.formatShort(_dueDate),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickTime,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: theme.colorScheme.outline.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _formatDisplayTime(_dueTime),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 6. Recurrence Type
              Text(
                'Recurrence',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildRecurrenceChip('One-time', AppConstants.recurrenceNone),
                  _buildRecurrenceChip('Daily', AppConstants.recurrenceDaily),
                  _buildRecurrenceChip(
                    'Weekdays',
                    AppConstants.recurrenceWeekdays,
                  ),
                  _buildRecurrenceChip('Weekly', AppConstants.recurrenceWeekly),
                ],
              ),
              const SizedBox(height: 12),

              // 7. Reminder Toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Set Local Reminder',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Get alert at ${_formatDisplayTime(_dueTime)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                value: _hasReminder,
                onChanged: (val) => setState(() => _hasReminder = val),
              ),
              const SizedBox(height: 20),

              // 8. Submit Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEditing ? 'Save Changes' : 'Create Task',
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
    );
  }

  Widget _buildPriorityChip(String label, String value, Color color) {
    final theme = Theme.of(context);
    final isSelected = _priority == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? color
                  : theme.colorScheme.outline.withValues(alpha: 0.4),
              width: isSelected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected ? color : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecurrenceChip(String label, String value) {
    final theme = Theme.of(context);
    final isSelected = _recurrenceType == value;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _recurrenceType = value);
      },
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface,
      ),
    );
  }
}
