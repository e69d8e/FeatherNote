import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 笔记 Markdown 快捷编辑工具栏
class NoteEditorToolbar extends StatelessWidget {
  final TextEditingController contentController;
  final VoidCallback onContentChanged;

  const NoteEditorToolbar({
    super.key,
    required this.contentController,
    required this.onContentChanged,
  });

  /// 在当前光标位置插入或包裹 Markdown 语法
  void _insertMarkdown({
    required String prefix,
    String suffix = '',
    String defaultText = '',
    bool blockMode = false,
  }) {
    final text = contentController.text;
    final selection = contentController.selection;

    if (!selection.isValid) {
      final newText = text + prefix + defaultText + suffix;
      contentController.text = newText;
      contentController.selection = TextSelection.collapsed(offset: newText.length);
      onContentChanged();
      return;
    }

    final start = selection.start;
    final end = selection.end;
    final selectedText = text.substring(start, end);

    final insertion = selectedText.isEmpty ? defaultText : selectedText;
    final replacement = blockMode
        ? '\n$prefix$insertion$suffix\n'
        : '$prefix$insertion$suffix';

    final newText = text.replaceRange(start, end, replacement);
    contentController.text = newText;

    final cursorPosition = start + prefix.length + (blockMode ? 1 : 0) + (selectedText.isEmpty ? defaultText.length : selectedText.length);
    contentController.selection = TextSelection.collapsed(offset: cursorPosition);
    onContentChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final items = [
      _ToolbarItem(
        icon: Icons.title_rounded,
        tooltip: '大标题 (H1)',
        onPressed: () => _insertMarkdown(prefix: '# ', defaultText: '标题', blockMode: true),
      ),
      _ToolbarItem(
        icon: Icons.format_size_rounded,
        tooltip: '中标题 (H2)',
        onPressed: () => _insertMarkdown(prefix: '## ', defaultText: '副标题', blockMode: true),
      ),
      _ToolbarItem(
        icon: Icons.format_bold_rounded,
        tooltip: '加粗',
        onPressed: () => _insertMarkdown(prefix: '**', suffix: '**', defaultText: '粗体文本'),
      ),
      _ToolbarItem(
        icon: Icons.format_italic_rounded,
        tooltip: '斜体',
        onPressed: () => _insertMarkdown(prefix: '*', suffix: '*', defaultText: '斜体文本'),
      ),
      _ToolbarItem(
        icon: Icons.strikethrough_s_rounded,
        tooltip: '删除线',
        onPressed: () => _insertMarkdown(prefix: '~~', suffix: '~~', defaultText: '删除文本'),
      ),
      _ToolbarItem(
        icon: Icons.checklist_rtl_rounded,
        tooltip: '待办清单',
        onPressed: () => _insertMarkdown(prefix: '- [ ] ', defaultText: '待办事项', blockMode: true),
      ),
      _ToolbarItem(
        icon: Icons.format_list_bulleted_rounded,
        tooltip: '无序列表',
        onPressed: () => _insertMarkdown(prefix: '- ', defaultText: '列表项', blockMode: true),
      ),
      _ToolbarItem(
        icon: Icons.format_list_numbered_rounded,
        tooltip: '有序列表',
        onPressed: () => _insertMarkdown(prefix: '1. ', defaultText: '列表项', blockMode: true),
      ),
      _ToolbarItem(
        icon: Icons.format_quote_rounded,
        tooltip: '引用',
        onPressed: () => _insertMarkdown(prefix: '> ', defaultText: '引用文本', blockMode: true),
      ),
      _ToolbarItem(
        icon: Icons.code_rounded,
        tooltip: '代码块',
        onPressed: () => _insertMarkdown(prefix: '```dart\n', suffix: '\n```', defaultText: '// Code here', blockMode: true),
      ),
      _ToolbarItem(
        icon: Icons.horizontal_rule_rounded,
        tooltip: '分割线',
        onPressed: () => _insertMarkdown(prefix: '\n---\n', defaultText: ''),
      ),
      _ToolbarItem(
        icon: Icons.access_time_rounded,
        tooltip: '插入当前时间',
        onPressed: () {
          final nowStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
          _insertMarkdown(prefix: nowStr, defaultText: '');
        },
      ),
    ];

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
            width: 0.8,
          ),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 2),
        itemBuilder: (context, index) {
          final item = items[index];
          return IconButton(
            icon: Icon(item.icon, size: 20),
            tooltip: item.tooltip,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: colorScheme.onSurfaceVariant,
            onPressed: item.onPressed,
          );
        },
      ),
    );
  }
}

class _ToolbarItem {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  _ToolbarItem({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });
}
