/// 文本与 Markdown 分析工具
class TextUtils {
  TextUtils._();

  // 预编译高频正则表达式
  static final RegExp _markdownHeadingsRegex = RegExp(r'#+\s*');
  static final RegExp _markdownFormattingRegex = RegExp(r'[*_~`>\[\]\(\)]');
  static final RegExp _markdownCheckboxesRegex = RegExp(r'[-*+]\s+\[[ xX]\]');
  static final RegExp _newlinesRegex = RegExp(r'\n+');

  /// 待办项单行匹配正则 (支持 -、*、+ 以及不同层级缩进与尾部文本)
  static final RegExp todoItemRegex = RegExp(r'^(\s*[-*+]\s+\[)([ xX])(\]\s*(.*))$', multiLine: true);

  /// 已完成待办匹配正则 (用于一键清理已完成待办)
  static final RegExp completedTodoLineRegex = RegExp(r'^\s*[-*+]\s+\[[xX]\]\s*.*$', multiLine: true);

  /// 统计中文字数与英文单词数 (高性能单趟线性扫描，零大对象分配)
  static int countWords(String text) {
    if (text.isEmpty) return 0;

    int count = 0;
    bool inNonChineseWord = false;
    final len = text.length;

    for (int i = 0; i < len; i++) {
      final code = text.codeUnitAt(i);

      // CJK 汉字区间 (每个汉字单独计为1字)
      if (code >= 0x4E00 && code <= 0x9FA5) {
        count++;
        inNonChineseWord = false;
        continue;
      }

      // 忽略复选框勾选标记: [x] 或 [X]
      if ((code == 120 || code == 88) && i > 0 && i < len - 1) {
        if (text.codeUnitAt(i - 1) == 91 && text.codeUnitAt(i + 1) == 93) {
          inNonChineseWord = false;
          continue;
        }
      }

      // 忽略 Markdown 标志及空白符
      // 空白符: <= 32
      // # (35), * (42), + (43), - (45), ` (96), > (62), [ (91), ] (93), ( (40), ) (41), _ (95), ~ (126)
      if (code <= 32 ||
          code == 35 ||
          code == 42 ||
          code == 43 ||
          code == 45 ||
          code == 96 ||
          code == 62 ||
          code == 91 ||
          code == 93 ||
          code == 40 ||
          code == 41 ||
          code == 95 ||
          code == 126) {
        inNonChineseWord = false;
        continue;
      }

      // 单词内部连接符与小数点 (如 don't, 3.14): 若在单词内部且前后紧随字母/数字，保持在当前词内
      if ((code == 46 || code == 39) && inNonChineseWord && i < len - 1) {
        final next = text.codeUnitAt(i + 1);
        if ((next >= 0x30 && next <= 0x39) ||
            (next >= 0x41 && next <= 0x5A) ||
            (next >= 0x61 && next <= 0x7A)) {
          continue;
        }
      }

      // 中文常用标点 (。，！？：；“”‘’、) 与英文标点
      if (code == 0x3002 ||
          code == 0xFF0C ||
          code == 0xFF01 ||
          code == 0xFF1F ||
          code == 0xFF1A ||
          code == 0xFF1B ||
          code == 0x3001 ||
          code == 0x201C ||
          code == 0x201D ||
          code == 0x2018 ||
          code == 0x2019 ||
          code == 44 || // ,
          code == 46 || // .
          code == 58 || // :
          code == 59 || // ;
          code == 33 || // !
          code == 63) { // ?
        inNonChineseWord = false;
        continue;
      }

      // 其它普通字符 (英文单词、数字等)
      if (!inNonChineseWord) {
        inNonChineseWord = true;
        count++;
      }
    }

    return count;
  }

  /// 估算阅读所需时间 (以每分钟 350 字估算)
  static String estimateReadingTime(String text) {
    final words = countWords(text);
    if (words == 0) return '0 分钟';
    final minutes = (words / 350).ceil();
    return '$minutes 分钟';
  }

  /// 获取内容摘要 (单行，去除空行和 Markdown 标记，前置窗口优化)
  static String getSnippet(String content, {int maxLength = 100}) {
    if (content.trim().isEmpty) return '';

    // 若文本较长，仅截取前置窗口进行摘要提取，避免大文本全量正则与多重拷贝
    final scanWindow = content.length > maxLength * 4
        ? content.substring(0, maxLength * 4)
        : content;

    final plain = scanWindow
        .replaceAll(_markdownHeadingsRegex, '')
        .replaceAll(_markdownFormattingRegex, '')
        .replaceAll(_markdownCheckboxesRegex, '')
        .replaceAll(_newlinesRegex, ' ')
        .trim();

    if (plain.length <= maxLength) {
      if (content.length <= maxLength * 4) {
        return plain;
      }
    }
    final cutLength = plain.length < maxLength ? plain.length : maxLength;
    return '${plain.substring(0, cutLength)}...';
  }

  /// 切换 Markdown 文本中第 targetIndex 个待办事项 (checkbox) 的勾选状态
  static String toggleCheckboxAt(String content, int targetIndex) {
    int currentIndex = 0;

    return content.replaceAllMapped(todoItemRegex, (match) {
      if (currentIndex == targetIndex) {
        currentIndex++;
        final isCurrentlyChecked = match.group(2)?.toLowerCase() == 'x';
        final newChar = isCurrentlyChecked ? ' ' : 'x';
        return '${match.group(1)}$newChar${match.group(3)}';
      }
      currentIndex++;
      return match.group(0)!;
    });
  }
}
