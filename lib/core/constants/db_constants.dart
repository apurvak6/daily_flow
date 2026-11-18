/// SQLite Database Constants: Database name, version, table and column definitions.
class DbConstants {
  DbConstants._();

  static const String databaseName = 'daily_flow.db';
  static const int databaseVersion = 2;

  // --- Table: tasks ---
  static const String tableTasks = 'tasks';
  static const String colTaskId = 'id';
  static const String colTaskTitle = 'title';
  static const String colTaskDescription = 'description';
  static const String colTaskPriority = 'priority';
  static const String colTaskCategory = 'category';
  static const String colTaskDueDate = 'due_date';
  static const String colTaskDueTime = 'due_time';
  static const String colTaskIsRecurring = 'is_recurring';
  static const String colTaskRecurrenceType = 'recurrence_type';
  static const String colTaskIsCompleted = 'is_completed';
  static const String colTaskReminderTime = 'reminder_time';
  static const String colTaskCreatedAt = 'created_at';
  static const String colTaskUpdatedAt = 'updated_at';

  // --- Table: task_occurrences ---
  static const String tableTaskOccurrences = 'task_occurrences';
  static const String colOccId = 'id';
  static const String colOccTaskId = 'task_id';
  static const String colOccDate = 'occurrence_date';
  static const String colOccIsCompleted = 'is_completed';
  static const String colOccCompletedAt = 'completed_at';
  static const String colOccNotes = 'notes';
  static const String colOccCreatedAt = 'created_at';
  static const String colOccUpdatedAt = 'updated_at';

  // --- Table: activities ---
  static const String tableActivities = 'activities';
  static const String colActId = 'id';
  static const String colActTitle = 'title';
  static const String colActDescription = 'description';
  static const String colActCategory = 'category';
  static const String colActIcon = 'icon';
  static const String colActColor = 'color';
  static const String colActTargetFrequency = 'target_frequency';
  static const String colActTargetValue = 'target_value';
  static const String colActUnit = 'unit';
  static const String colActIsActive = 'is_active';
  static const String colActCreatedAt = 'created_at';
  static const String colActUpdatedAt = 'updated_at';

  // --- Table: activity_occurrences ---
  static const String tableActivityOccurrences = 'activity_occurrences';
  static const String colActOccId = 'id';
  static const String colActOccActivityId = 'activity_id';
  static const String colActOccDate = 'occurrence_date';
  static const String colActOccIsCompleted = 'is_completed';
  static const String colActOccActualValue = 'actual_value';
  static const String colActOccCompletedAt = 'completed_at';
  static const String colActOccNotes = 'notes';
  static const String colActOccCreatedAt = 'created_at';
  static const String colActOccUpdatedAt = 'updated_at';

  // --- Table: app_settings ---
  static const String tableAppSettings = 'app_settings';
  static const String colSettingKey = 'key';
  static const String colSettingValue = 'value';

  // --- Preference Keys ---
  static const String prefThemeMode = 'theme_mode';
  static const String prefNotifications = 'notifications_enabled';

  // --- Index Names ---
  static const String idxTaskOccDate = 'idx_task_occurrences_date';
  static const String idxTaskOccTaskId = 'idx_task_occurrences_task_id';
  static const String idxTasksDueDate = 'idx_tasks_due_date';
  static const String idxActOccDate = 'idx_activity_occurrences_date';
  static const String idxActOccActId = 'idx_activity_occurrences_act_id';
}
