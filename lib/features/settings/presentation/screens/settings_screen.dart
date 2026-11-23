import 'dart:convert';
import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/providers/database_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/widgets/feather_color_picker.dart';
import '../../../../core/widgets/feather_content_width.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/repositories/update_repository.dart';
import '../controllers/settings_controller.dart';
import '../controllers/update_controller.dart';
import '../widgets/app_update_dialog.dart';
import '../../../notes/domain/models/note.dart';
import '../../../tags/domain/models/tag.dart';

/// 设置中心页面
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsCtrl = ref.read(settingsProvider.notifier);
    final updateState = ref.watch(updateControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '设置与个性化',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: FeatherContentWidth(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            _buildSectionHeader(context, '主题与外观'),

            // 主题模式切换 (系统/明亮/深色)
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('主题外观'),
              subtitle: Text(_getThemeModeName(settings.themeMode)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showThemeModeDialog(
                context,
                settingsCtrl,
                settings.themeMode,
              ),
            ),

            // 默认笔记卡片配色
            ListTile(
              leading: const Icon(Icons.color_lens_outlined),
              title: const Text('新建笔记默认色'),
              subtitle: Text(
                AppColors.getNoteColor(settings.defaultColorId).name,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.getNoteColor(settings.defaultColorId)
                          .lightBackground,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.getNoteColor(settings.defaultColorId)
                            .accentColor,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.getNoteColor(settings.defaultColorId)
                          .accentColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              onTap: () => _showDefaultColorDialog(
                context,
                settingsCtrl,
                settings.defaultColorId,
              ),
            ),

            // 字体大小调节
            ListTile(
              leading: const Icon(Icons.format_size_rounded),
              title: const Text('全局字体大小'),
              subtitle: Text(_getFontScaleName(settings.fontScale)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showFontScaleDialog(
                context,
                settingsCtrl,
                settings.fontScale,
              ),
            ),

            const Divider(height: 32),
            _buildSectionHeader(context, '视图与排序'),

            // 默认视图
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('主页卡片布局'),
              subtitle: Text(_getViewModeName(settings.viewMode)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () =>
                  _showViewModeDialog(context, settingsCtrl, settings.viewMode),
            ),

            // 默认排序规则
            ListTile(
              leading: const Icon(Icons.sort_rounded),
              title: const Text('笔记排序方式'),
              subtitle: Text(_getSortFieldName(settings.sortField)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showSortDialog(context, settingsCtrl, settings),
            ),

            const Divider(height: 32),
            _buildSectionHeader(context, '数据管理与备份'),

            // 导出 JSON 备份
            ListTile(
              leading: const Icon(Icons.cloud_download_outlined),
              title: const Text('导出全部数据 (JSON)'),
              subtitle: const Text('备份所有笔记内容与标签颜色配置'),
              onTap: () => _exportJsonBackup(context, ref),
            ),

            // 导入 JSON 备份
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: const Text('导入数据恢复'),
              subtitle: const Text('从 JSON 备份文件或粘贴文本导入，同 ID 笔记会被覆盖'),
              onTap: () => _showImportJsonDialog(context, ref),
            ),

            const Divider(height: 32),
            _buildSectionHeader(context, '关于羽记'),

            ListTile(
              leading: const Icon(Icons.flutter_dash, color: AppColors.primary),
              title: const Text('羽记 / FeatherNote'),
              subtitle: Text(
                updateState.currentVersion.isEmpty
                    ? '行云流水，轻盈如羽'
                    : 'v${updateState.currentVersion} · 行云流水，轻盈如羽',
              ),
              onTap: () =>
                  _showAboutDialog(context, updateState.currentVersion),
            ),

            // 手动检查更新
            ListTile(
              leading: const Icon(Icons.system_update_alt_rounded),
              title: const Text('检查更新'),
              subtitle: Text(
                updateState.currentVersion.isEmpty
                    ? '正在读取版本信息…'
                    : '当前版本 v${updateState.currentVersion}',
              ),
              trailing: updateState.checking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: updateState.checking
                  ? null
                  : () => _checkForUpdateManually(context, ref),
            ),

            // 启动时自动检查更新开关
            SwitchListTile(
              secondary: const Icon(Icons.sync_outlined),
              title: const Text('自动检查更新'),
              subtitle: const Text('启动时联网查询 GitHub 新版本 (每 24 小时最多一次)'),
              value: settings.autoCheckUpdate,
              onChanged: (value) => settingsCtrl.toggleAutoCheckUpdate(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => '跟随系统',
      ThemeMode.light => '明亮模式',
      ThemeMode.dark => '深色模式',
    };
  }

  String _getViewModeName(NoteViewMode mode) {
    return switch (mode) {
      NoteViewMode.staggered => '瀑布流 (错落有致)',
      NoteViewMode.grid => '双列网格 (规整紧凑)',
      NoteViewMode.list => '单列列表 (宽幅阅读)',
    };
  }

  String _getSortFieldName(NoteSortField field) {
    return switch (field) {
      NoteSortField.updatedAt => '按最后修改时间 (倒序)',
      NoteSortField.createdAt => '按创建时间 (倒序)',
      NoteSortField.title => '按标题字母顺序',
    };
  }

  void _showThemeModeDialog(
    BuildContext context,
    SettingsNotifier ctrl,
    ThemeMode current,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择主题外观'),
        children: ThemeMode.values.map((mode) {
          final isSelected = mode == current;
          return ListTile(
            leading: Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
            ),
            title: Text(_getThemeModeName(mode)),
            onTap: () {
              ctrl.updateThemeMode(mode);
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    );
  }

  String _getFontScaleName(double scale) {
    if (scale <= 0.9) return '偏小 (0.9x)';
    if (scale >= 1.2) return '较大 (1.2x)';
    if (scale >= 1.1) return '适中 (1.1x)';
    return '标准 (1.0x)';
  }

  void _showFontScaleDialog(
    BuildContext context,
    SettingsNotifier ctrl,
    double current,
  ) {
    const scales = [
      (0.9, '偏小 (0.9x)'),
      (1.0, '标准 (1.0x)'),
      (1.1, '适中 (1.1x)'),
      (1.2, '较大 (1.2x)'),
    ];

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择全局字体大小'),
        children: scales.map((item) {
          final isSelected = (item.$1 - current).abs() < 0.01;
          return ListTile(
            leading: Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
            ),
            title: Text(item.$2),
            onTap: () {
              ctrl.updateFontScale(item.$1);
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    );
  }

  void _showDefaultColorDialog(
    BuildContext context,
    SettingsNotifier ctrl,
    String current,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '选择新建笔记默认配色',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 16),
              FeatherColorPicker(
                selectedColorId: current,
                onColorSelected: (id) {
                  ctrl.updateDefaultColor(id);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showViewModeDialog(
    BuildContext context,
    SettingsNotifier ctrl,
    NoteViewMode current,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('卡片布局风格'),
        children: NoteViewMode.values.map((mode) {
          final isSelected = mode == current;
          return ListTile(
            leading: Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
            ),
            title: Text(_getViewModeName(mode)),
            onTap: () {
              ctrl.updateViewMode(mode);
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    );
  }

  void _showSortDialog(
    BuildContext context,
    SettingsNotifier ctrl,
    AppSettings settings,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('排序规则'),
        children: NoteSortField.values.map((field) {
          final isSelected = field == settings.sortField;
          return ListTile(
            leading: Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
            ),
            title: Text(_getSortFieldName(field)),
            onTap: () {
              ctrl.updateSort(field, settings.sortAscending);
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _exportJsonBackup(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    try {
      final notes = await ref.read(noteRepositoryProvider).getAllNotes();
      final tags = await ref.read(tagRepositoryProvider).getAllTags();

      // 笔记数量大时把 JSON 序列化放入后台 isolate，避免卡顿 UI
      // (Web 平台不支持 isolate，退回主线程执行)
      final jsonString = kIsWeb
          ? _encodeBackupJson(notes, tags)
          : await Isolate.run(() => _encodeBackupJson(notes, tags));
      final fileName =
          'feathernote-backup-${_timestampForFileName(DateTime.now())}.json';
      final bytes = Uint8List.fromList(utf8.encode(jsonString));

      String message;
      try {
        // Web 端优先调用系统分享；浏览器不支持时 share_plus 会自动下载文件。
        final result = await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                bytes,
                mimeType: 'application/json',
                name: fileName,
              ),
            ],
            subject: '羽记备份',
            text: '羽记备份：${notes.length} 条笔记，${tags.length} 个标签',
          ),
        );
        message = switch (result.status) {
          ShareResultStatus.success => '备份文件已通过系统分享保存。',
          ShareResultStatus.dismissed => '分享已取消，未保存备份文件。',
          ShareResultStatus.unavailable => '备份文件已生成，浏览器已开始下载。',
        };
      } catch (_) {
        // 桌面 Linux 等不支持分享的平台退回剪贴板，至少不丢数据。
        await Clipboard.setData(ClipboardData(text: jsonString));
        message = '当前平台暂不支持保存文件，已将 JSON 备份复制到剪贴板。';
      }

      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('备份数据已导出'),
          content: Text(
            '$message\n\n文件名：$fileName\n包含 ${notes.length} 条笔记、${tags.length} 个标签。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('导出失败：$e'),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// 把全部笔记与标签配置序列化为格式化 JSON 文本
  static String _encodeBackupJson(List<Note> notes, List<Tag> tags) {
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'feathernote-backup',
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'notes': notes.map((n) => n.toJson()).toList(),
      'tags': tags
          .map(
            (t) => {
              'id': t.id,
              'name': t.name,
              'color': t.color,
              'createdAt': t.createdAt.toIso8601String(),
            },
          )
          .toList(),
    });
  }

  static String _timestampForFileName(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}${two(time.month)}${two(time.day)}-'
        '${two(time.hour)}${two(time.minute)}${two(time.second)}';
  }

  Future<void> _showImportJsonDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    String? fileName;
    var readingFile = false;

    final data = await showDialog<_BackupData>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> pickBackupFile() async {
            if (readingFile) return;
            setDialogState(() => readingFile = true);
            try {
              final picked = await FilePicker.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['json'],
              );
              if (picked.isEmpty) return;
              final file = picked.first;
              final bytes = await file.readAsBytes();
              final text = utf8.decode(bytes);
              if (!ctx.mounted) return;
              controller.text = text;
              setDialogState(() => fileName = file.name);
            } catch (e) {
              if (ctx.mounted) {
                showAppSnackBar(ctx, '读取备份文件失败：$e', isError: true);
              }
            } finally {
              if (ctx.mounted) setDialogState(() => readingFile = false);
            }
          }

          return AlertDialog(
            title: const Text('导入 JSON 备份'),
            content: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: readingFile ? null : pickBackupFile,
                        icon: readingFile
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.folder_open_rounded, size: 18),
                        label: const Text('选择备份文件'),
                      ),
                      if (fileName != null) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            fileName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller,
                    maxLines: 6,
                    minLines: 4,
                    decoration: const InputDecoration(
                      hintText: '在此粘贴导出的 JSON 数据文本...',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '支持 .json 备份文件，也可直接粘贴文本。导入前会显示笔记与标签数量供确认。',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () {
                  final clean = controller.text.trim();
                  if (clean.isEmpty) {
                    showAppSnackBar(ctx, '请先选择备份文件或粘贴 JSON 内容', isError: true);
                    return;
                  }
                  try {
                    Navigator.pop(ctx, _parseBackup(clean));
                  } catch (e) {
                    showAppSnackBar(ctx, '无法解析备份文件：$e', isError: true);
                  }
                },
                child: const Text('预览导入'),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
    if (data == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认导入备份？'),
        content: Text(
          '将导入 ${data.notes.length} 条笔记、${data.tags.length} 个标签。\n\n'
          '与现有笔记 ID 相同的记录会被覆盖更新，且此操作无法撤销。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('导入'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _importJsonBackup(context, ref, data);
    }
  }

  /// 解析备份文本，兼容新版 {notes,tags} 与旧版纯笔记数组格式
  static _BackupData _parseBackup(String rawText) {
    final decoded = jsonDecode(rawText);
    final List<dynamic> noteJson;
    final List<dynamic> tagJson;

    if (decoded is List) {
      noteJson = decoded;
      tagJson = const [];
    } else if (decoded is Map<String, dynamic>) {
      noteJson = decoded['notes'] as List<dynamic>? ?? const [];
      tagJson = decoded['tags'] as List<dynamic>? ?? const [];
    } else {
      throw const FormatException('备份格式无法识别');
    }

    final notes = noteJson
        .map((e) => Note.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final tags = tagJson
        .map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          final name = (map['name'] ?? '').toString().trim();
          if (name.isEmpty) return null;
          return Tag(
            id: (map['id'] ?? name).toString(),
            name: name,
            color: map['color'] as String?,
            createdAt:
                DateTime.tryParse((map['createdAt'] ?? '').toString()) ??
                DateTime.now(),
          );
        })
        .whereType<Tag>()
        .toList();

    if (notes.isEmpty && tags.isEmpty) {
      throw const FormatException('备份中没有可导入的笔记或标签');
    }
    return _BackupData(notes: notes, tags: tags);
  }

  Future<void> _importJsonBackup(
    BuildContext context,
    WidgetRef ref,
    _BackupData data,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    try {
      if (data.notes.isNotEmpty) {
        await ref.read(noteRepositoryProvider).importNotes(data.notes);
      }
      if (data.tags.isNotEmpty) {
        await ref.read(tagRepositoryProvider).importTags(data.tags);
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '成功导入 ${data.notes.length} 条笔记、${data.tags.length} 个标签',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('导入失败：$e'),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAboutDialog(BuildContext context, String currentVersion) {
    showAboutDialog(
      context: context,
      applicationName: '羽记 · FeatherNote',
      applicationVersion: currentVersion.isEmpty ? null : currentVersion,
      applicationIcon: const Icon(
        Icons.flutter_dash,
        size: 48,
        color: AppColors.primary,
      ),
      children: const [
        Text('羽记是一款追求极致轻盈、行云流水般书写体验的跨平台离线记事本应用。'),
        SizedBox(height: 12),
        Text('技术栈：Flutter · Riverpod · Drift/SQLite · GoRouter · Material 3'),
      ],
    );
  }

  /// 手动检查更新，用弹窗/提示条反馈结果
  Future<void> _checkForUpdateManually(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    try {
      final update = await ref
          .read(updateControllerProvider.notifier)
          .checkManually();
      if (!context.mounted) return;
      if (update == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('当前已是最新版本 🎉'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        await showAppUpdateDialog(context, update);
      }
    } on UpdateCheckException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('检查更新失败：$e'),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// 解析后的备份数据
class _BackupData {
  final List<Note> notes;
  final List<Tag> tags;

  const _BackupData({required this.notes, required this.tags});
}
