import 'package:intl/intl.dart';

/// 日期与相对时间格式化工具
class DateFormatter {
  DateFormatter._();

  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _monthDayFormat = DateFormat('M月d日 HH:mm');
  static final DateFormat _fullFormat = DateFormat('yyyy年M月d日 HH:mm');
  static final DateFormat _shortDateFormat = DateFormat('yyyy-MM-dd');

  /// 转换为优雅的相对时间展示
  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative || difference.inSeconds < 60) {
      return '刚刚';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    }

    final isSameDay = now.year == dateTime.year &&
        now.month == dateTime.month &&
        now.day == dateTime.day;
    if (isSameDay) {
      return '今天 ${_timeFormat.format(dateTime)}';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = yesterday.year == dateTime.year &&
        yesterday.month == dateTime.month &&
        yesterday.day == dateTime.day;
    if (isYesterday) {
      return '昨天 ${_timeFormat.format(dateTime)}';
    }

    if (now.year == dateTime.year) {
      return _monthDayFormat.format(dateTime);
    }

    return _fullFormat.format(dateTime);
  }

  /// 完整日期时间
  static String formatFull(DateTime dateTime) {
    return _fullFormat.format(dateTime);
  }

  /// 简短日期 yyyy-MM-dd
  static String formatShort(DateTime dateTime) {
    return _shortDateFormat.format(dateTime);
  }
}
