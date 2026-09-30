import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/widgets/feather_color_picker.dart';
import '../../../../core/widgets/feather_dialog_text_field.dart';
import '../../../../core/widgets/feather_tag_chip.dart';
import '../../domain/models/note.dart';
import '../controllers/note_edit_controller.dart';
import '../widgets/note_card_share_dialog.dart';
import '../widgets/note_editor_toolbar.dart';

/// 笔记编辑与沉浸式阅读页面
class NoteEditScreen extends ConsumerStatefulWidget {
  final String? noteId;

  const NoteEditScreen({super.key, this.noteId});

  @override
  ConsumerState<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends ConsumerState<NoteEditScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();
  final Debouncer _editSyncDebouncer = Debouncer(delay: const Duration(milliseconds: 300));
  late final AppLifecycleListener _lifecycleListener;
  MarkdownStyleSheet? _cachedStyleSheet;
  Brightness? _cachedStyleSheetBrightness;
  String? _syncedNoteId;
  bool _hasUnsyncedText = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    // 应用退到后台时立即落盘，避免进程被回收丢失最后几百毫秒的输入
    _lifecycleListener = AppLifecycleListener(onPause: _flushAndSave);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _editSyncDebouncer.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  /// 输入防抖同步：文本由 TextEditingController 持有，停止输入 300ms 后
  /// 才推入全局状态，避免每个按键都触发整页重建与笔记列表流刷新
  void _onTextChanged() {
    _hasUnsyncedText = true;
    _editSyncDebouncer.run(_flushPendingEdits);
  }

  /// 立即把输入框中的最新文本同步到控制器状态 (切换预览/分享/退出前调用)
  void _flushPendingEdits() {
    _editSyncDebouncer.cancel();
    if (!_hasUnsyncedText) return;
    _hasUnsyncedText = false;
    final notifier = ref.read(noteEditProvider(widget.noteId).notifier);
    notifier.setTitle(_titleController.text);
    notifier.setContent(_contentController.text);
  }

  void _flushAndSave() {
    _flushPendingEdits();
    ref.read(noteEditProvider(widget.noteId).notifier).saveImmediate();
  }

  void _syncControllers(NoteEditState state) {
    if (state.isLoading) return;
    if (_syncedNoteId != state.note.id) {
      if (_titleController.text != state.note.title) {
        _titleController.text = state.note.title;
      }
      if (_contentController.text != state.note.content) {
        _contentController.text = state.note.content;
      }
      _syncedNoteId = state.note.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(noteEditProvider(widget.noteId));
    final notifier = ref.read(noteEditProvider(widget.noteId).notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final colorPreset = AppColors.getNoteColor(state.note.colorId, isDark: isDark);
    final bgColor = colorPreset.background(isDark);

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    // 当远程/异步加载完成时同步输入框内容
    _syncControllers(state);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && !state.note.isDeleted) {
          _flushAndSave();
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeTab(
                  label: '编辑',
                  icon: Icons.edit_outlined,
                  isSelected: !state.isPreviewMode,
                  onTap: () {
                    if (state.isPreviewMode) notifier.togglePreviewMode();
                  },
                ),
                _buildModeTab(
                  label: '预览',
                  icon: Icons.auto_awesome_outlined,
                  isSelected: state.isPreviewMode,
                  onTap: () {
                    if (!state.isPreviewMode) {
                      _flushAndSave();
                      notifier.togglePreviewMode();
                    }
                  },
                ),
              ],
            ),
          ),
          centerTitle: true,
          actions: [
            // 置顶按钮
            IconButton(
              icon: Icon(
                state.note.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                color: state.note.isPinned ? colorPreset.accentColor : null,
                size: 22,
              ),
              tooltip: state.note.isPinned ? '取消置顶' : '置顶笔记',
              onPressed: () => notifier.togglePin(),
            ),

            // 生成羽记书笺分享卡片
            IconButton(
              icon: const Icon(Icons.share_outlined, size: 22),
              tooltip: '分享书笺卡片',
              onPressed: () {
                _flushPendingEdits();
                NoteCardShareDialog.show(
                  context,
                  ref.read(noteEditProvider(widget.noteId)).note,
                );
              },
            ),

            // 更多操作 (字数统计/归档/删除)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) async {
                _flushPendingEdits();
                final fresh = ref.read(noteEditProvider(widget.noteId));
                switch (value) {
                  case 'color':
                    _showColorPickerBottomSheet(context, notifier, fresh.note.colorId);
                    break;
                  case 'archive':
                    final wasArchived = fresh.note.isArchived;
                    await runWithFeedback(
                      context,
                      () async {
                        notifier.toggleArchive();
                      },
                      successMessage: wasArchived ? '已移出归档' : '已归档笔记',
                    );
                    break;
                  case 'delete':
                    await runWithFeedback(
                      context,
                      notifier.deleteNote,
                      successMessage: '已移入废纸篓',
                      failureTitle: '删除失败',
                    );
                    if (context.mounted) context.pop();
                    break;
                  case 'info':
                    _showNoteInfoDialog(context, fresh.note);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'color',
                  child: Row(
                    children: [
                      Icon(Icons.palette_outlined, size: 18),
                      SizedBox(width: 12),
                      Text('更换卡片主题色'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(Icons.archive_outlined, size: 18),
                      SizedBox(width: 12),
                      Text(state.note.isArchived ? '移出归档' : '归档笔记'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'info',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18),
                      SizedBox(width: 12),
                      Text('笔记信息与字数'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                      SizedBox(width: 12),
                      Text('移入废纸篓', style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // 编辑 / 预览主体
            Expanded(
              child: state.isPreviewMode
                  ? _buildMarkdownPreview(context, state, notifier)
                  : _buildEditorContent(context, state, notifier),
            ),

            // 底部 Markdown 快捷排版工具栏与状态栏 (仅编辑模式显示)
            if (!state.isPreviewMode)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 底部轻量状态条 (字数与保存状态)
                  _NoteStatusBar(
                    isSaving: state.isSaving,
                    saveFailed: state.saveFailed,
                    controller: _contentController,
                  ),
                  NoteEditorToolbar(
                    contentController: _contentController,
                    onContentChanged: _onTextChanged,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// 模式切换 Pill
  Widget _buildModeTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? colorScheme.surfaceContainerHigh : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建编辑正文区 (支持整页点击聚焦与流畅排版)
  Widget _buildEditorContent(
    BuildContext context,
    NoteEditState state,
    NoteEditNotifier notifier,
  ) {
    final theme = Theme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!_contentFocusNode.hasFocus) {
          _contentFocusNode.requestFocus();
          _contentController.selection = TextSelection.collapsed(
            offset: _contentController.text.length,
          );
        }
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          // 标题输入框
          TextField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _contentFocusNode.requestFocus(),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            decoration: const InputDecoration(
              hintText: '标题',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => _onTextChanged(),
          ),

          const SizedBox(height: 12),

          // 标签列表与添加按钮
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...state.note.tags.map((tag) {
                return FeatherTagChip(
                  label: tag,
                  isSelected: true,
                  onDeleted: () => notifier.removeTag(tag),
                );
              }),
              InkWell(
                onTap: () => _showAddTagToNoteDialog(context, notifier),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '标签',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 正文输入框 (多行纸张画卷体验)
          TextField(
            controller: _contentController,
            focusNode: _contentFocusNode,
            maxLines: null,
            minLines: 15,
            keyboardType: TextInputType.multiline,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.7,
              fontSize: 15.5,
            ),
            decoration: const InputDecoration(
              hintText: '记录灵感、清单或随想... 支持 Markdown',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => _onTextChanged(),
          ),
        ],
      ),
    );
  }

  /// 构建 Markdown 渲染预览区 (支持可交互勾选待办清单)
  Widget _buildMarkdownPreview(
    BuildContext context,
    NoteEditState state,
    NoteEditNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final markdownContent = state.note.title.isNotEmpty
        ? '# ${state.note.title}\n\n${state.note.content}'
        : (state.note.content.isNotEmpty ? state.note.content : '*(暂无内容)*');

    int checkboxCounter = 0;

    return Markdown(
      data: markdownContent,
      selectable: true,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      checkboxBuilder: (bool checked) {
        final thisIndex = checkboxCounter++;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            final newContent = TextUtils.toggleCheckboxAt(state.note.content, thisIndex);
            notifier.setContent(newContent);
            _contentController.text = newContent;
            notifier.saveImmediate();
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 6, top: 2),
            child: Icon(
              checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              size: 20,
              color: checked ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        );
      },
      styleSheet: _markdownStyleSheetFor(theme),
    );
  }

  /// Markdown 预览样式表 (按明暗模式缓存实例)。flutter_markdown 会在
  /// styleSheet 实例变化时丢弃已解析内容重新解析全文，缓存实例可避免
  /// 页面任意状态变化 (如保存指示器) 引发的整篇重新解析卡顿。
  MarkdownStyleSheet _markdownStyleSheetFor(ThemeData theme) {
    if (_cachedStyleSheet == null || _cachedStyleSheetBrightness != theme.brightness) {
      _cachedStyleSheetBrightness = theme.brightness;
      _cachedStyleSheet = _buildMarkdownStyleSheet(theme);
    }
    return _cachedStyleSheet!;
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      h1: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      h2: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      h3: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      p: theme.textTheme.bodyLarge?.copyWith(height: 1.7, fontSize: 15.5),
      blockquote: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
            width: 3,
          ),
        ),
      ),
      code: TextStyle(
        backgroundColor: isDark ? const Color(0xFF2C3238) : const Color(0xFFE8EEF5),
        fontFamily: 'monospace',
        fontSize: 13.5,
      ),
      codeblockDecoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2328) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  /// 弹出卡片主题色选择底栏
  void _showColorPickerBottomSheet(
    BuildContext context,
    NoteEditNotifier notifier,
    String currentColorId,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '选择卡片主题色',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              FeatherColorPicker(
                selectedColorId: currentColorId,
                onColorSelected: (colorId) {
                  notifier.setColor(colorId);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 弹出添加标签对话框
  void _showAddTagToNoteDialog(BuildContext context, NoteEditNotifier notifier) {
    var text = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加标签'),
        content: FeatherDialogTextField(
          autofocus: true,
          hintText: '输入标签名 (如: 灵感、备忘)',
          onChanged: (val) => text = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final clean = text.trim();
              if (clean.isNotEmpty) {
                notifier.addTag(clean);
              }
              Navigator.pop(ctx);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  /// 弹出笔记信息统计弹窗
  void _showNoteInfoDialog(BuildContext context, Note note) {
    final text = _contentController.text;
    final wordCount = TextUtils.countWords(text);
    final readingTime = TextUtils.estimateReadingTime(text);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 20),
            SizedBox(width: 8),
            Text('笔记详情'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('字数统计', '$wordCount 字'),
            const SizedBox(height: 8),
            _buildInfoRow('预计阅读', readingTime),
            const SizedBox(height: 8),
            _buildInfoRow('最后修改', DateFormatter.formatFull(note.updatedAt)),
            const SizedBox(height: 8),
            _buildInfoRow('创建时间', DateFormatter.formatFull(note.createdAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      ],
    );
  }
}

/// 底部轻量状态条 (字数与保存状态)
class _NoteStatusBar extends StatelessWidget {
  final bool isSaving;
  final bool saveFailed;
  final TextEditingController controller;

  const _NoteStatusBar({
    required this.isSaving,
    required this.saveFailed,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      alignment: Alignment.centerRight,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final String text;
          final Color color;
          if (saveFailed) {
            text = '保存失败，内容已保留，可继续编辑重试';
            color = theme.colorScheme.error;
          } else if (isSaving) {
            text = '正在自动保存...';
            color = theme.colorScheme.onSurface.withValues(alpha: 0.45);
          } else {
            text = '${TextUtils.countWords(value.text)} 字';
            color = theme.colorScheme.onSurface.withValues(alpha: 0.45);
          }
          return Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: color, fontSize: 11),
          );
        },
      ),
    );
  }
}
