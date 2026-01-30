import 'package:intl/intl.dart';

class DateUtils {
  static String formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  static DateTime getPeriodStart(DateTime date, int cutDay) {
    if (date.day >= cutDay) {
      return DateTime(date.year, date.month, cutDay);
    } else {
      final prevMonth = date.month == 1 ? 12 : date.month - 1;
      final prevYear = date.month == 1 ? date.year - 1 : date.year;
      return DateTime(prevYear, prevMonth, cutDay);
    }
  }

  static DateTime getPeriodEnd(DateTime date, int cutDay) {
    if (date.day >= cutDay) {
      final nextMonth = date.month == 12 ? 1 : date.month + 1;
      final nextYear = date.month == 12 ? date.year + 1 : date.year;
      return DateTime(nextYear, nextMonth, cutDay).subtract(const Duration(days: 1));
    } else {
      return DateTime(date.year, date.month, cutDay).subtract(const Duration(days: 1));
    }
  }

  static DateTime getCalendarMonthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime getCalendarMonthEnd(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }
}
