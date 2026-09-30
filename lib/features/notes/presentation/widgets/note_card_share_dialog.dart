import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/text_utils.dart';
import '../../domain/models/note.dart';

/// 羽记笺卡片分享对话框 (生成并分享高清卡片图片)
class NoteCardShareDialog extends StatefulWidget {
  final Note note;

  const NoteCardShareDialog({super.key, required this.note});

  static void show(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (ctx) => NoteCardShareDialog(note: note),
    );
  }

  @override
  State<NoteCardShareDialog> createState() => _NoteCardShareDialogState();
}

class _NoteCardShareDialogState extends State<NoteCardShareDialog> {
  late String _selectedColorId;
  final GlobalKey _cardGlobalKey = GlobalKey();
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _selectedColorId = widget.note.colorId;
  }

  /// 将卡片 Widget 渲染为高清 PNG 图片并触发系统分享
  Future<void> _shareCardImage() async {
    setState(() => _isExporting = true);
    try {
      // 保证下一帧渲染完成后截取
      await Future.delayed(const Duration(milliseconds: 60));
      final boundary = _cardGlobalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('无法找到卡片渲染对象');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData;
      try {
        byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      } finally {
        // 及时释放原生侧位图内存，避免每次分享都泄漏一张高清图像
        image.dispose();
      }
      if (byteData == null) {
        throw Exception('生成图片数据失败');
      }

      final pngBytes = byteData.buffer.asUint8List();
      final title = widget.note.displayTitle.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final fileName = 'FeatherNote_$title.png';

      final xFile = XFile.fromData(
        pngBytes,
        mimeType: 'image/png',
        name: fileName,
      );

      await Share.shareXFiles(
        [xFile],
        text: '来自「羽记 · FeatherNote」',
        subject: widget.note.displayTitle,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成卡片图片失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorPreset = AppColors.getNoteColor(_selectedColorId, isDark: false);
    final wordCount = TextUtils.countWords(widget.note.content);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 实体卡片 (包裹 RepaintBoundary 用于截图导出图片)
            RepaintBoundary(
              key: _cardGlobalKey,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: colorPreset.lightBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colorPreset.lightBorder, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 顶部装饰：羽记 FeatherNote 徽标与日期
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.asset(
                                'assets/icons/app_icon.png',
                                fit: BoxFit.cover,
                                cacheWidth: 128,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '羽记',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorPreset.accentColor,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          DateFormatter.formatShort(widget.note.updatedAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 标题
                    Text(
                      widget.note.displayTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                        fontSize: 19,
                        height: 1.3,
                      ),
                    ),

                    // 标签
                    if (widget.note.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: widget.note.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorPreset.accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#$tag',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: colorPreset.accentColor,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // 正文 (使用 MarkdownBody 完整渲染标题、待办清单、粗斜体、代码等)
                    MarkdownBody(
                      data: widget.note.content.isNotEmpty ? widget.note.content : '*(暂无正文)*',
                      selectable: false,
                      checkboxBuilder: (bool checked) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6, top: 2),
                          child: Icon(
                            checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                            size: 18,
                            color: checked ? colorPreset.accentColor : const Color(0xFF94A3B8),
                          ),
                        );
                      },
                      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                        p: const TextStyle(
                          color: Color(0xFF334155),
                          height: 1.65,
                          fontSize: 13.5,
                        ),
                        h1: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          height: 1.4,
                        ),
                        h2: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w600,
                          fontSize: 15.5,
                          height: 1.4,
                        ),
                        h3: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          height: 1.4,
                        ),
                        blockquote: const TextStyle(
                          color: Color(0xFF475569),
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                          height: 1.5,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: colorPreset.accentColor.withValues(alpha: 0.6),
                              width: 3,
                            ),
                          ),
                        ),
                        code: const TextStyle(
                          backgroundColor: Color(0xFFE2E8F0),
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    const Divider(color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 8),

                    // 底部签名与字数
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '共 $wordCount 字 · 行云流水，轻盈如羽',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF94A3B8),
                            fontSize: 10.5,
                          ),
                        ),
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 14,
                          color: colorPreset.accentColor.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 底部操作区 (自适应宽度，避免溢出)
            Container(
              constraints: const BoxConstraints(maxWidth: 380),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 第一行：6 款羽毛颜色切换
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: AppColors.noteColors.map((c) {
                      final isSel = c.id == _selectedColorId;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColorId = c.id),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: c.lightBackground,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSel ? c.accentColor : c.lightBorder,
                              width: isSel ? 2.2 : 1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12),

                  // 第二行：操作按钮
                  Row(
                    children: [
                      // 复制文本
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final shareText = '${widget.note.displayTitle}\n\n${widget.note.content}';
                            Clipboard.setData(ClipboardData(text: shareText));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('已复制笔记文本到剪贴板'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('复制文本'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 分享图片
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isExporting ? null : _shareCardImage,
                          icon: _isExporting
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.image_outlined, size: 16),
                          label: Text(_isExporting ? '生成中...' : '分享图片'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
