import '../../core/constants/app_constants.dart';
import '../../core/constants/db_constants.dart';

/// Represents a recurring habit or activity template in DailyFlow.
class ActivityModel {
  final int? id;
  final String title;
  final String? description;
  final String category;
  final String? scheduledTime; // e.g. "08:00 AM" or "08:00"
  final bool isReminderEnabled;
  final String? icon;
  final String? color;
  final String targetFrequency; // daily, weekdays, etc.
  final int targetValue;
  final String unit;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  ActivityModel({
    this.id,
    required this.title,
    this.description,
    this.category = 'Personal',
    this.scheduledTime,
    this.isReminderEnabled = false,
    this.icon,
    this.color,
    this.targetFrequency = AppConstants.frequencyDaily,
    this.targetValue = 1,
    this.unit = 'times',
    this.isActive = true,
    String? createdAt,
    String? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String(),
       updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      DbConstants.colActTitle: title,
      DbConstants.colActDescription: description,
      DbConstants.colActCategory: category,
      DbConstants.colActScheduledTime: scheduledTime,
      DbConstants.colActReminderEnabled: isReminderEnabled ? 1 : 0,
      DbConstants.colActIcon: icon,
      DbConstants.colActColor: color,
      DbConstants.colActTargetFrequency: targetFrequency,
      DbConstants.colActTargetValue: targetValue,
      DbConstants.colActUnit: unit,
      DbConstants.colActIsActive: isActive ? 1 : 0,
      DbConstants.colActCreatedAt: createdAt,
      DbConstants.colActUpdatedAt: updatedAt,
    };
    if (id != null) {
      map[DbConstants.colActId] = id;
    }
    return map;
  }

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      id: map[DbConstants.colActId] as int?,
      title: map[DbConstants.colActTitle] as String? ?? '',
      description: map[DbConstants.colActDescription] as String?,
      category: map[DbConstants.colActCategory] as String? ?? 'Personal',
      scheduledTime: map[DbConstants.colActScheduledTime] as String?,
      isReminderEnabled:
          (map[DbConstants.colActReminderEnabled] as int? ?? 0) == 1,
      icon: map[DbConstants.colActIcon] as String?,
      color: map[DbConstants.colActColor] as String?,
      targetFrequency:
          map[DbConstants.colActTargetFrequency] as String? ??
          AppConstants.frequencyDaily,
      targetValue: map[DbConstants.colActTargetValue] as int? ?? 1,
      unit: map[DbConstants.colActUnit] as String? ?? 'times',
      isActive: (map[DbConstants.colActIsActive] as int? ?? 1) == 1,
      createdAt:
          map[DbConstants.colActCreatedAt] as String? ??
          DateTime.now().toIso8601String(),
      updatedAt:
          map[DbConstants.colActUpdatedAt] as String? ??
          DateTime.now().toIso8601String(),
    );
  }

  ActivityModel copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    String? scheduledTime,
    bool? isReminderEnabled,
    String? icon,
    String? color,
    String? targetFrequency,
    int? targetValue,
    String? unit,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isReminderEnabled: isReminderEnabled ?? this.isReminderEnabled,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      targetFrequency: targetFrequency ?? this.targetFrequency,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'ActivityModel(id: $id, title: $title, time: $scheduledTime, reminder: $isReminderEnabled, active: $isActive)';
}
