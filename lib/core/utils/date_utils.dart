import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Centralized Date and Time utility methods for formatting, comparing, and manipulating dates.
class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _isoFormatter = DateFormat(
    AppConstants.isoDateFormat,
  );
  static final DateFormat _displayFormatter = DateFormat(
    AppConstants.displayDateFormat,
  );
  static final DateFormat _shortFormatter = DateFormat(
    AppConstants.shortDateFormat,
  );
  static final DateFormat _monthYearFormatter = DateFormat(
    AppConstants.monthYearFormat,
  );

  /// Converts a [DateTime] to ISO date string format (yyyy-MM-dd).
  static String toIsoDate(DateTime date) {
    return _isoFormatter.format(date);
  }

  /// Parses an ISO date string (yyyy-MM-dd) to a normalized [DateTime] (00:00:00).
  static DateTime fromIsoDate(String isoString) {
    return _isoFormatter.parse(isoString);
  }

  /// Returns today's date normalized to midnight (00:00:00).
  static DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Returns today's date formatted as ISO string (yyyy-MM-dd).
  static String get todayIso => toIsoDate(today);

  /// Strips time components and returns the date at 00:00:00.
  static DateTime normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Formats date for UI display (e.g., 'Mon, Oct 12, 2026').
  static String formatDisplay(DateTime date) {
    return _displayFormatter.format(date);
  }

  /// Formats date for short display (e.g., 'Oct 12').
  static String formatShort(DateTime date) {
    return _shortFormatter.format(date);
  }

  /// Formats date for month and year header (e.g., 'October 2026').
  static String formatMonthYear(DateTime date) {
    return _monthYearFormatter.format(date);
  }

  /// Returns whether a given [isoDate] is strictly before today (overdue).
  static bool isOverdue(String isoDate) {
    try {
      final date = fromIsoDate(isoDate);
      return date.isBefore(today);
    } catch (_) {
      return false;
    }
  }

  /// Returns whether a given [isoDate] matches today.
  static bool isToday(String isoDate) {
    return isoDate == todayIso;
  }

  /// Returns start of the week (Monday) for a given date.
  static DateTime startOfWeek(DateTime date) {
    final normalized = normalize(date);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  /// Returns end of the week (Sunday) for a given date.
  static DateTime endOfWeek(DateTime date) {
    final start = startOfWeek(date);
    return start.add(const Duration(days: 6));
  }

  /// Generates a list of all 7 days for the current week starting on Monday.
  static List<DateTime> daysOfWeek(DateTime date) {
    final start = startOfWeek(date);
    return List.generate(7, (index) => start.add(Duration(days: index)));
  }
}
