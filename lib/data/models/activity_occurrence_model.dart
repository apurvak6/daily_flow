import '../../core/constants/db_constants.dart';

/// Represents a date-specific occurrence or daily log of a recurring activity.
class ActivityOccurrenceModel {
  final int? id;
  final int activityId;
  final String occurrenceDate; // ISO yyyy-MM-dd
  final bool isCompleted;
  final int actualValue;
  final String? completedAt;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  // Joined activity details for efficient UI presentation
  final String? activityTitle;
  final String? activityDescription;
  final String? category;
  final String? icon;
  final String? color;
  final int? targetValue;
  final String? unit;

  ActivityOccurrenceModel({
    this.id,
    required this.activityId,
    required this.occurrenceDate,
    this.isCompleted = false,
    this.actualValue = 0,
    this.completedAt,
    this.notes,
    String? createdAt,
    String? updatedAt,
    this.activityTitle,
    this.activityDescription,
    this.category,
    this.icon,
    this.color,
    this.targetValue,
    this.unit,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String(),
       updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      DbConstants.colActOccActivityId: activityId,
      DbConstants.colActOccDate: occurrenceDate,
      DbConstants.colActOccIsCompleted: isCompleted ? 1 : 0,
      DbConstants.colActOccActualValue: actualValue,
      DbConstants.colActOccCompletedAt: completedAt,
      DbConstants.colActOccNotes: notes,
      DbConstants.colActOccCreatedAt: createdAt,
      DbConstants.colActOccUpdatedAt: updatedAt,
    };
    if (id != null) {
      map[DbConstants.colActOccId] = id;
    }
    return map;
  }

  factory ActivityOccurrenceModel.fromMap(Map<String, dynamic> map) {
    return ActivityOccurrenceModel(
      id: map[DbConstants.colActOccId] as int?,
      activityId: map[DbConstants.colActOccActivityId] as int,
      occurrenceDate: map[DbConstants.colActOccDate] as String,
      isCompleted: (map[DbConstants.colActOccIsCompleted] as int? ?? 0) == 1,
      actualValue: map[DbConstants.colActOccActualValue] as int? ?? 0,
      completedAt: map[DbConstants.colActOccCompletedAt] as String?,
      notes: map[DbConstants.colActOccNotes] as String?,
      createdAt:
          map[DbConstants.colActOccCreatedAt] as String? ??
          DateTime.now().toIso8601String(),
      updatedAt:
          map[DbConstants.colActOccUpdatedAt] as String? ??
          DateTime.now().toIso8601String(),
      activityTitle:
          map['activity_title'] as String? ??
          map[DbConstants.colActTitle] as String?,
      activityDescription:
          map['activity_description'] as String? ??
          map[DbConstants.colActDescription] as String?,
      category: map[DbConstants.colActCategory] as String?,
      icon: map[DbConstants.colActIcon] as String?,
      color: map[DbConstants.colActColor] as String?,
      targetValue: map[DbConstants.colActTargetValue] as int?,
      unit: map[DbConstants.colActUnit] as String?,
    );
  }

  ActivityOccurrenceModel copyWith({
    int? id,
    int? activityId,
    String? occurrenceDate,
    bool? isCompleted,
    int? actualValue,
    String? completedAt,
    String? notes,
    String? createdAt,
    String? updatedAt,
    String? activityTitle,
    String? activityDescription,
    String? category,
    String? icon,
    String? color,
    int? targetValue,
    String? unit,
  }) {
    return ActivityOccurrenceModel(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
      isCompleted: isCompleted ?? this.isCompleted,
      actualValue: actualValue ?? this.actualValue,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      activityTitle: activityTitle ?? this.activityTitle,
      activityDescription: activityDescription ?? this.activityDescription,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
    );
  }

  @override
  String toString() =>
      'ActivityOccurrenceModel(id: $id, activityId: $activityId, date: $occurrenceDate, actual: $actualValue, completed: $isCompleted)';
}
