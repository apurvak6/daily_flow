import '../../core/constants/db_constants.dart';
import '../../core/utils/date_utils.dart';

/// Represents a date-specific occurrence or daily log of a recurring activity.
class ActivityOccurrenceModel {
  final int? id;
  final int activityId;
  final String occurrenceDate; // ISO yyyy-MM-dd
  final String status; // 'pending', 'completed', 'skipped'
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
  final String? scheduledTime;
  final bool? isReminderEnabled;
  final String? icon;
  final String? color;
  final int? targetValue;
  final String? unit;

  ActivityOccurrenceModel({
    this.id,
    required this.activityId,
    required this.occurrenceDate,
    String? status,
    bool isCompleted = false,
    this.actualValue = 0,
    this.completedAt,
    this.notes,
    String? createdAt,
    String? updatedAt,
    this.activityTitle,
    this.activityDescription,
    this.category,
    this.scheduledTime,
    this.isReminderEnabled,
    this.icon,
    this.color,
    this.targetValue,
    this.unit,
  }) : isCompleted = isCompleted || status == 'completed',
       status =
           status ??
           (isCompleted
               ? 'completed'
               : (notes == 'Skipped' ? 'skipped' : 'pending')),
       createdAt = createdAt ?? DateTime.now().toIso8601String(),
       updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  bool get isCompletedStatus => status == 'completed' || isCompleted;
  bool get isSkipped => status == 'skipped' || notes == 'Skipped';
  bool get isPending => !isCompletedStatus && !isSkipped;
  bool get isMissedOrOverdue =>
      isPending && AppDateUtils.isOverdue(occurrenceDate);

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      DbConstants.colActOccActivityId: activityId,
      DbConstants.colActOccDate: occurrenceDate,
      DbConstants.colActOccStatus: status,
      DbConstants.colActOccIsCompleted: (status == 'completed' || isCompleted)
          ? 1
          : 0,
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
    final isDone = (map[DbConstants.colActOccIsCompleted] as int? ?? 0) == 1;
    final note = map[DbConstants.colActOccNotes] as String?;
    final rawStatus = map[DbConstants.colActOccStatus] as String?;

    final computedStatus =
        rawStatus ??
        (isDone ? 'completed' : (note == 'Skipped' ? 'skipped' : 'pending'));

    return ActivityOccurrenceModel(
      id: map[DbConstants.colActOccId] as int?,
      activityId: map[DbConstants.colActOccActivityId] as int,
      occurrenceDate: map[DbConstants.colActOccDate] as String,
      status: computedStatus,
      isCompleted: isDone || computedStatus == 'completed',
      actualValue: map[DbConstants.colActOccActualValue] as int? ?? 0,
      completedAt: map[DbConstants.colActOccCompletedAt] as String?,
      notes: note,
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
      scheduledTime: map[DbConstants.colActScheduledTime] as String?,
      isReminderEnabled: map[DbConstants.colActReminderEnabled] != null
          ? (map[DbConstants.colActReminderEnabled] as int? ?? 0) == 1
          : null,
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
    String? status,
    bool? isCompleted,
    int? actualValue,
    String? completedAt,
    String? notes,
    String? createdAt,
    String? updatedAt,
    String? activityTitle,
    String? activityDescription,
    String? category,
    String? scheduledTime,
    bool? isReminderEnabled,
    String? icon,
    String? color,
    int? targetValue,
    String? unit,
  }) {
    return ActivityOccurrenceModel(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
      status: status ?? this.status,
      isCompleted: isCompleted ?? this.isCompleted,
      actualValue: actualValue ?? this.actualValue,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      activityTitle: activityTitle ?? this.activityTitle,
      activityDescription: activityDescription ?? this.activityDescription,
      category: category ?? this.category,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isReminderEnabled: isReminderEnabled ?? this.isReminderEnabled,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
    );
  }

  @override
  String toString() =>
      'ActivityOccurrenceModel(id: $id, activityId: $activityId, date: $occurrenceDate, status: $status, completed: $isCompleted)';
}
