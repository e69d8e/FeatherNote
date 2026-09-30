import 'package:flutter_test/flutter_test.dart';
import 'package:feathernote/core/utils/text_utils.dart';

void main() {
  group('TextUtils - countWords', () {
    test('空文本与纯空白字符处理', () {
      expect(TextUtils.countWords(''), equals(0));
      expect(TextUtils.countWords('   \n\t  \r\n '), equals(0));
    });

    test('纯中文字符统计 (每个汉字单独计为1字)', () {
      expect(TextUtils.countWords('羽记轻笔记'), equals(5));
      expect(TextUtils.countWords('落樱粉，初晴绿，微风紫。'), equals(9));
    });

    test('纯英文单词统计 (按词边界划分)', () {
      expect(TextUtils.countWords('Hello world'), equals(2));
      expect(TextUtils.countWords('Flutter Riverpod Drift SQLite'), equals(4));
    });

    test('中英文与数字混合统计', () {
      const text = '使用 Flutter 3.13 和 Dart 开发了 1 款离线 App。';
      // 汉字: 使(1) 用(2) 和(3) 开(4) 发(5) 了(6) 款(7) 离(8) 线(9) (共9字)
      // 英文与数字词: Flutter(1) 3.13(2) Dart(3) 1(4) App(5) (共5词)
      // 总计: 14
      expect(TextUtils.countWords(text), equals(14));
    });

    test('剔除 Markdown 标记符号 (标题、加粗、斜体、代码、引用等)', () {
      const md = '''
# 一级标题
## 二级标题
这是**加粗文字**和*斜体文字*以及`代码`。
> 这里是一段引用说明。
''';
      // 一级标题 (4) + 二级标题 (4) + 这是(2) + 加粗文字(4) + 和(1) + 斜体文字(4) + 以及(2) + 代码(2) + 这里是一段引用说明(9) = 32
      final count = TextUtils.countWords(md);
      expect(count, equals(32));
    });

    test('剔除待办复选框标记', () {
      const todos = '''
- [ ] 未完成待办
- [x] 已完成待办
* [ ] 星号待办
+ [X] 加号待办
''';
      // 未完成待办(5) + 已完成待办(5) + 星号待办(4) + 加号待办(4) = 18
      expect(TextUtils.countWords(todos), equals(18));
    });

    test('超长文本高性能线性扫描 (10万字符基准测试)', () {
      final buffer = StringBuffer();
      for (int i = 0; i < 1000; i++) {
        buffer.writeln('# 标题 $i\n这是一段测试内容，包含 English words 和数字 $i。');
      }
      final largeText = buffer.toString();
      final stopwatch = Stopwatch()..start();
      final words = TextUtils.countWords(largeText);
      stopwatch.stop();

      expect(words, greaterThan(10000));
      // 10万字符应在极短时间内完成（通常 < 50ms）
      expect(stopwatch.elapsedMilliseconds, lessThan(300));
    });
  });

  group('TextUtils - getSnippet', () {
    test('空内容处理', () {
      expect(TextUtils.getSnippet(''), equals(''));
      expect(TextUtils.getSnippet('   \n\n  '), equals(''));
    });

    test('短内容不带省略号', () {
      const content = '轻盈如羽，行云流水';
      expect(TextUtils.getSnippet(content, maxLength: 50), equals('轻盈如羽，行云流水'));
    });

    test('超长内容正确截断并追加省略号', () {
      const content = '这是一篇很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长的笔记。';
      final snippet = TextUtils.getSnippet(content, maxLength: 20);
      expect(snippet.endsWith('...'), isTrue);
      expect(snippet.length, equals(23)); // 20 + 3
    });

    test('清洗 Markdown 标题、符号与换行', () {
      const content = '# 标题\n这是**重要**内容\n- [ ] 待办列表\n代码：`var x = 1;`';
      final snippet = TextUtils.getSnippet(content, maxLength: 100);
      expect(snippet.contains('#'), isFalse);
      expect(snippet.contains('**'), isFalse);
      expect(snippet.contains('`'), isFalse);
      expect(snippet.contains('\n'), isFalse);
      expect(snippet.contains('待办列表'), isTrue);
    });

    test('超大内容窗口前置优化性能', () {
      final buffer = StringBuffer('前置关键内容摘要。');
      for (int i = 0; i < 5000; i++) {
        buffer.write('后续大量冗余内容不需要在生成卡片摘要时全部解析。');
      }
      final massiveText = buffer.toString();

      final stopwatch = Stopwatch()..start();
      final snippet = TextUtils.getSnippet(massiveText, maxLength: 50);
      stopwatch.stop();

      expect(snippet.startsWith('前置关键内容摘要。'), isTrue);
      expect(snippet.endsWith('...'), isTrue);
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });
  });

  group('TextUtils - toggleCheckboxAt', () {
    test('未完成切换为已完成', () {
      const text = '- [ ] 买牛奶';
      final toggled = TextUtils.toggleCheckboxAt(text, 0);
      expect(toggled, equals('- [x] 买牛奶'));
    });

    test('已完成切换为未完成', () {
      const text = '- [x] 读书一小时';
      final toggled = TextUtils.toggleCheckboxAt(text, 0);
      expect(toggled, equals('- [ ] 读书一小时'));
    });

    test('大写 X 切换为未完成', () {
      const text = '- [X] 完成报告';
      final toggled = TextUtils.toggleCheckboxAt(text, 0);
      expect(toggled, equals('- [ ] 完成报告'));
    });

    test('精准切换第 N 个待办，保持其它项完好', () {
      const text = '- [ ] 事项1\n- [x] 事项2\n- [ ] 事项3';
      final toggled = TextUtils.toggleCheckboxAt(text, 1);
      expect(toggled, equals('- [ ] 事项1\n- [ ] 事项2\n- [ ] 事项3'));

      final toggled2 = TextUtils.toggleCheckboxAt(text, 2);
      expect(toggled2, equals('- [ ] 事项1\n- [x] 事项2\n- [x] 事项3'));
    });

    test('支持多层级缩进与多种无序列表前缀', () {
      const text = '  * [ ] 缩进星号待办\n    + [x] 深层加号待办';
      final toggled0 = TextUtils.toggleCheckboxAt(text, 0);
      expect(toggled0, equals('  * [x] 缩进星号待办\n    + [x] 深层加号待办'));

      final toggled1 = TextUtils.toggleCheckboxAt(text, 1);
      expect(toggled1, equals('  * [ ] 缩进星号待办\n    + [ ] 深层加号待办'));
    });
  });

  group('TextUtils - estimateReadingTime', () {
    test('零字数阅读时间为 0 分钟', () {
      expect(TextUtils.estimateReadingTime(''), equals('0 分钟'));
    });

    test('低于 350 字估算为 1 分钟', () {
      expect(TextUtils.estimateReadingTime('短文速读'), equals('1 分钟'));
    });

    test('超过 350 字按每分钟 350 字向上取整', () {
      final longText = List.filled(400, '字').join();
      expect(TextUtils.estimateReadingTime(longText), equals('2 分钟'));

      final veryLongText = List.filled(750, '字').join();
      expect(TextUtils.estimateReadingTime(veryLongText), equals('3 分钟'));
    });
  });
}
