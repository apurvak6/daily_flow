/// Application-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'DailyFlow';
  static const String appTagline = 'Master Your Day, Every Day';

  // Date Formats (ISO standard for persistence)
  static const String isoDateFormat = 'yyyy-MM-dd';
  static const String displayDateFormat = 'EEE, MMM d, yyyy';
  static const String shortDateFormat = 'MMM d';
  static const String timeFormat24 = 'HH:mm';
  static const String timeFormat12 = 'hh:mm a';
  static const String monthYearFormat = 'MMMM yyyy';

  // Task Priority Keys
  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';

  // Recurrence Types
  static const String recurrenceNone = 'none';
  static const String recurrenceDaily = 'daily';
  static const String recurrenceWeekly = 'weekly';
  static const String recurrenceWeekdays = 'weekdays';

  // Activity Frequencies
  static const String frequencyDaily = 'daily';
  static const String frequencyWeekdays = 'weekdays';
  static const String frequencyCustom = 'custom';

  // Default Categories
  static const List<String> defaultTaskCategories = [
    'Work',
    'Personal',
    'Health',
    'Learning',
    'Finance',
  ];

  static const List<String> defaultActivityCategories = [
    'Fitness',
    'Mindfulness',
    'Reading',
    'Hydration',
    'Skill',
  ];
}
