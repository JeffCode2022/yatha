import 'package:intl/intl.dart';

class DateUtils {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  static DateTime parseDate(String dateString) {
    return _dateFormat.parse(dateString);
  }

  static DateTime parseDateTime(String dateString) {
    return _dateTimeFormat.parse(dateString);
  }

  static String getCurrentDate() {
    return formatDate(DateTime.now());
  }

  static String getCurrentDateTime() {
    return formatDateTime(DateTime.now());
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
