import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/text_utils.dart';
import '../../domain/models/note.dart';
import '../controllers/note_list_controller.dart';
import '../../../../core/widgets/feather_color_picker.dart';

/// 笔记卡片组件 (支持柔和羽色背景、置顶徽标、标签及快捷操作)
class NoteCard extends ConsumerWidget {
  final Note note;
  final VoidCallback? onTap;
  final bool showActions;

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final colorPreset = AppColors.getNoteColor(note.colorId, isDark: isDark);
    final bgColor = colorPreset.background(isDark);
    final borderColor = colorPreset.border(isDark);
    final snippet = TextUtils.getSnippet(note.content, maxLength: 120);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: note.isPinned
              ? colorPreset.accentColor.withValues(alpha: 0.6)
              : borderColor,
          width: note.isPinned ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          onLongPress: showActions ? () => _showQuickActions(context, ref) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顶部标题与置顶标志
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        note.displayTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (note.isPinned) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.push_pin_rounded,
                        size: 15,
                        color: colorPreset.accentColor,
                      ),
                    ],
                  ],
                ),

                // 内容摘要预览
                if (snippet.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    snippet,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 13,
                      height: 1.35,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // 标签展示
                if (note.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: note.tags.take(2).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorPreset.accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '#$tag',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: colorPreset.accentColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 8),

                // 底部信息栏 (日期与快捷更多按钮)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormatter.formatRelative(note.updatedAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                        fontSize: 10.5,
                      ),
                    ),
                    if (showActions)
                      GestureDetector(
                        onTap: () => _showQuickActions(context, ref),
                        child: Icon(
                          Icons.more_horiz_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 弹出笔记快捷操作底部菜单
  void _showQuickActions(BuildContext context, WidgetRef ref) {
    final listCtrl = ref.read(noteListControllerProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 变色调色板
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FeatherColorPicker(
                    selectedColorId: note.colorId,
                    onColorSelected: (colorId) {
                      listCtrl.changeColor(note, colorId);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    note.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(note.isPinned ? '取消置顶' : '置顶笔记'),
                  onTap: () {
                    Navigator.pop(ctx);
                    runWithFeedback(
                      context,
                      () => listCtrl.togglePin(note),
                      successMessage: note.isPinned ? '已取消置顶' : '已置顶笔记',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.archive_outlined),
                  title: Text(note.isArchived ? '移出归档' : '归档笔记'),
                  onTap: () {
                    Navigator.pop(ctx);
                    runWithFeedback(
                      context,
                      () => listCtrl.toggleArchive(note),
                      successMessage: note.isArchived ? '已移出归档' : '已归档笔记',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  title: const Text('移入废纸篓', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(ctx);
                    runWithFeedback(
                      context,
                      () => listCtrl.softDelete(note),
                      successMessage: '已移入废纸篓',
                      onUndo: () => ref.read(noteRepositoryProvider).restoreNote(note.id),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
