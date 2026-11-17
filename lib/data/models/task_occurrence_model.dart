import '../../core/constants/db_constants.dart';

/// Represents a specific date occurrence of a task (either one-off or recurring instance).
class TaskOccurrenceModel {
  final int? id;
  final int taskId;
  final String occurrenceDate; // ISO yyyy-MM-dd
  final bool isCompleted;
  final String? completedAt;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  // Joined task details for efficient UI binding
  final String? taskTitle;
  final String? taskDescription;
  final String? priority;
  final String? category;
  final String? dueTime;
  final bool? isRecurring;

  TaskOccurrenceModel({
    this.id,
    required this.taskId,
    required this.occurrenceDate,
    this.isCompleted = false,
    this.completedAt,
    this.notes,
    String? createdAt,
    String? updatedAt,
    this.taskTitle,
    this.taskDescription,
    this.priority,
    this.category,
    this.dueTime,
    this.isRecurring,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String(),
       updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      DbConstants.colOccTaskId: taskId,
      DbConstants.colOccDate: occurrenceDate,
      DbConstants.colOccIsCompleted: isCompleted ? 1 : 0,
      DbConstants.colOccCompletedAt: completedAt,
      DbConstants.colOccNotes: notes,
      DbConstants.colOccCreatedAt: createdAt,
      DbConstants.colOccUpdatedAt: updatedAt,
    };
    if (id != null) {
      map[DbConstants.colOccId] = id;
    }
    return map;
  }

  factory TaskOccurrenceModel.fromMap(Map<String, dynamic> map) {
    return TaskOccurrenceModel(
      id: map[DbConstants.colOccId] as int?,
      taskId: map[DbConstants.colOccTaskId] as int,
      occurrenceDate: map[DbConstants.colOccDate] as String,
      isCompleted: (map[DbConstants.colOccIsCompleted] as int? ?? 0) == 1,
      completedAt: map[DbConstants.colOccCompletedAt] as String?,
      notes: map[DbConstants.colOccNotes] as String?,
      createdAt:
          map[DbConstants.colOccCreatedAt] as String? ??
          DateTime.now().toIso8601String(),
      updatedAt:
          map[DbConstants.colOccUpdatedAt] as String? ??
          DateTime.now().toIso8601String(),
      taskTitle:
          map['task_title'] as String? ??
          map[DbConstants.colTaskTitle] as String?,
      taskDescription:
          map['task_description'] as String? ??
          map[DbConstants.colTaskDescription] as String?,
      priority: map[DbConstants.colTaskPriority] as String?,
      category: map[DbConstants.colTaskCategory] as String?,
      dueTime: map[DbConstants.colTaskDueTime] as String?,
      isRecurring: map[DbConstants.colTaskIsRecurring] != null
          ? (map[DbConstants.colTaskIsRecurring] as int? ?? 0) == 1
          : null,
    );
  }

  TaskOccurrenceModel copyWith({
    int? id,
    int? taskId,
    String? occurrenceDate,
    bool? isCompleted,
    String? completedAt,
    String? notes,
    String? createdAt,
    String? updatedAt,
    String? taskTitle,
    String? taskDescription,
    String? priority,
    String? category,
    String? dueTime,
    bool? isRecurring,
  }) {
    return TaskOccurrenceModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      taskTitle: taskTitle ?? this.taskTitle,
      taskDescription: taskDescription ?? this.taskDescription,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueTime: dueTime ?? this.dueTime,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }

  @override
  String toString() =>
      'TaskOccurrenceModel(id: $id, taskId: $taskId, date: $occurrenceDate, completed: $isCompleted)';
}
