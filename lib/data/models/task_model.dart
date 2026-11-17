import '../../core/constants/app_constants.dart';
import '../../core/constants/db_constants.dart';

/// Represents a master task entity in DailyFlow.
class TaskModel {
  final int? id;
  final String title;
  final String? description;
  final String priority;
  final String category;
  final String? dueDate; // ISO yyyy-MM-dd
  final String? dueTime; // HH:mm
  final bool isRecurring;
  final String recurrenceType; // none, daily, weekly, weekdays
  final bool isCompleted;
  final String? reminderTime;
  final String createdAt;
  final String updatedAt;

  TaskModel({
    this.id,
    required this.title,
    this.description,
    this.priority = AppConstants.priorityMedium,
    this.category = 'Personal',
    this.dueDate,
    this.dueTime,
    this.isRecurring = false,
    this.recurrenceType = AppConstants.recurrenceNone,
    this.isCompleted = false,
    this.reminderTime,
    String? createdAt,
    String? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String(),
       updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      DbConstants.colTaskTitle: title,
      DbConstants.colTaskDescription: description,
      DbConstants.colTaskPriority: priority,
      DbConstants.colTaskCategory: category,
      DbConstants.colTaskDueDate: dueDate,
      DbConstants.colTaskDueTime: dueTime,
      DbConstants.colTaskIsRecurring: isRecurring ? 1 : 0,
      DbConstants.colTaskRecurrenceType: recurrenceType,
      DbConstants.colTaskIsCompleted: isCompleted ? 1 : 0,
      DbConstants.colTaskReminderTime: reminderTime,
      DbConstants.colTaskCreatedAt: createdAt,
      DbConstants.colTaskUpdatedAt: updatedAt,
    };
    if (id != null) {
      map[DbConstants.colTaskId] = id;
    }
    return map;
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map[DbConstants.colTaskId] as int?,
      title: map[DbConstants.colTaskTitle] as String? ?? '',
      description: map[DbConstants.colTaskDescription] as String?,
      priority:
          map[DbConstants.colTaskPriority] as String? ??
          AppConstants.priorityMedium,
      category: map[DbConstants.colTaskCategory] as String? ?? 'Personal',
      dueDate: map[DbConstants.colTaskDueDate] as String?,
      dueTime: map[DbConstants.colTaskDueTime] as String?,
      isRecurring: (map[DbConstants.colTaskIsRecurring] as int? ?? 0) == 1,
      recurrenceType:
          map[DbConstants.colTaskRecurrenceType] as String? ??
          AppConstants.recurrenceNone,
      isCompleted: (map[DbConstants.colTaskIsCompleted] as int? ?? 0) == 1,
      reminderTime: map[DbConstants.colTaskReminderTime] as String?,
      createdAt:
          map[DbConstants.colTaskCreatedAt] as String? ??
          DateTime.now().toIso8601String(),
      updatedAt:
          map[DbConstants.colTaskUpdatedAt] as String? ??
          DateTime.now().toIso8601String(),
    );
  }

  TaskModel copyWith({
    int? id,
    String? title,
    String? description,
    String? priority,
    String? category,
    String? dueDate,
    String? dueTime,
    bool? isRecurring,
    String? recurrenceType,
    bool? isCompleted,
    String? reminderTime,
    String? createdAt,
    String? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      isCompleted: isCompleted ?? this.isCompleted,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'TaskModel(id: $id, title: $title, isCompleted: $isCompleted, recurring: $isRecurring)';
}
