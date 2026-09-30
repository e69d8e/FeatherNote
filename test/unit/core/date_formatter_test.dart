import 'package:flutter_test/flutter_test.dart';
import 'package:feathernote/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter', () {
    test('刚刚 (< 60秒或未来微弱时钟漂移)', () {
      final now = DateTime.now();
      expect(DateFormatter.formatRelative(now), equals('刚刚'));

      final thirtySecAgo = now.subtract(const Duration(seconds: 30));
      expect(DateFormatter.formatRelative(thirtySecAgo), equals('刚刚'));

      final slightFuture = now.add(const Duration(seconds: 2));
      expect(DateFormatter.formatRelative(slightFuture), equals('刚刚'));
    });

    test('X分钟前 (< 60分钟)', () {
      final now = DateTime.now();
      final fiveMinAgo = now.subtract(const Duration(minutes: 5));
      expect(DateFormatter.formatRelative(fiveMinAgo), equals('5分钟前'));

      final fiftyNineMinAgo = now.subtract(const Duration(minutes: 59));
      expect(DateFormatter.formatRelative(fiftyNineMinAgo), equals('59分钟前'));
    });

    test('formatShort 输出标准 yyyy-MM-dd', () {
      final date = DateTime(2026, 9, 4, 15, 30);
      expect(DateFormatter.formatShort(date), equals('2026-09-04'));

      final janDate = DateTime(2026, 1, 5, 8, 9);
      expect(DateFormatter.formatShort(janDate), equals('2026-01-05'));
    });

    test('formatFull 输出标准 yyyy年M月d日 HH:mm', () {
      final date = DateTime(2026, 9, 4, 15, 30);
      expect(DateFormatter.formatFull(date), equals('2026年9月4日 15:30'));
    });

    test('跨年日期相对展示包含年份', () {
      final lastYear = DateTime(2020, 5, 20, 13, 14);
      final formatted = DateFormatter.formatRelative(lastYear);
      expect(formatted, contains('2020年'));
      expect(formatted, contains('5月20日'));
    });
  });
}
