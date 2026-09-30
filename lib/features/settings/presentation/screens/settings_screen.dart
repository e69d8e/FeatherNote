import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/widgets/feather_color_picker.dart';
import '../../../../core/widgets/feather_dialog_text_field.dart';
import '../../domain/models/app_settings.dart';
import '../controllers/settings_controller.dart';
import '../../../notes/domain/models/note.dart';

/// 设置中心页面
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsCtrl = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置与个性化', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _buildSectionHeader(context, '主题与外观'),

          // 主题模式切换 (系统/明亮/深色)
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('主题外观'),
            subtitle: Text(_getThemeModeName(settings.themeMode)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showThemeModeDialog(context, settingsCtrl, settings.themeMode),
          ),

          // 默认笔记卡片配色
          ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            title: const Text('新建笔记默认色'),
            subtitle: Text(AppColors.getNoteColor(settings.defaultColorId).name),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.getNoteColor(settings.defaultColorId).lightBackground,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.getNoteColor(settings.defaultColorId).accentColor,
                  width: 2,
                ),
              ),
            ),
            onTap: () => _showDefaultColorDialog(context, settingsCtrl, settings.defaultColorId),
          ),

          // 字体大小调节
          ListTile(
            leading: const Icon(Icons.format_size_rounded),
            title: const Text('全局字体大小'),
            subtitle: Text(_getFontScaleName(settings.fontScale)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showFontScaleDialog(context, settingsCtrl, settings.fontScale),
          ),

          const Divider(height: 32),
          _buildSectionHeader(context, '视图与排序'),

          // 默认视图
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('主页卡片布局'),
            subtitle: Text(_getViewModeName(settings.viewMode)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showViewModeDialog(context, settingsCtrl, settings.viewMode),
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
            subtitle: const Text('备份所有笔记内容与标签配置'),
            onTap: () => _exportJsonBackup(context, ref),
          ),

          // 导入 JSON 备份
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('导入数据恢复'),
            subtitle: const Text('从 JSON 文本或备份文件导入笔记'),
            onTap: () => _showImportJsonDialog(context, ref),
          ),

          const Divider(height: 32),
          _buildSectionHeader(context, '关于羽记'),

          ListTile(
            leading: const Icon(Icons.flutter_dash, color: AppColors.primary),
            title: const Text('羽记 / FeatherNote'),
            subtitle: const Text('v1.0.0 · 行云流水，轻盈如羽'),
            onTap: () => _showAboutDialog(context),
          ),
        ],
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

  void _showThemeModeDialog(BuildContext context, SettingsNotifier ctrl, ThemeMode current) {
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

  void _showFontScaleDialog(BuildContext context, SettingsNotifier ctrl, double current) {
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

  void _showDefaultColorDialog(BuildContext context, SettingsNotifier ctrl, String current) {
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
              const Text('选择新建笔记默认配色', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
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

  void _showViewModeDialog(BuildContext context, SettingsNotifier ctrl, NoteViewMode current) {
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

  void _showSortDialog(BuildContext context, SettingsNotifier ctrl, AppSettings settings) {
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
      final repo = ref.read(noteRepositoryProvider);
      final notes = await repo.getAllNotes();

      // 笔记数量大时把 JSON 序列化放入后台 isolate，避免卡顿 UI
      // (Web 平台不支持 isolate，退回主线程执行)
      final jsonString = kIsWeb
          ? _encodeNotesJson(notes)
          : await Isolate.run(() => _encodeNotesJson(notes));

      await Clipboard.setData(ClipboardData(text: jsonString));

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('备份数据导出成功'),
            content: Text('已将全部 ${notes.length} 条笔记数据以 JSON 格式复制到系统剪贴板，您可以粘贴保存到文件中。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
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

  /// 把全部笔记序列化为格式化 JSON 文本
  static String _encodeNotesJson(List<Note> notes) {
    final jsonList = notes.map((n) => n.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(jsonList);
  }

  void _showImportJsonDialog(BuildContext context, WidgetRef ref) {
    var text = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入 JSON 备份'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FeatherDialogTextField(
              maxLines: 6,
              hintText: '在此粘贴导出的 JSON 数据文本...',
              onChanged: (val) => text = val,
            ),
            const SizedBox(height: 8),
            const Text(
              '注意：与现有笔记 ID 相同的记录会被覆盖更新。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final clean = text.trim();
              if (clean.isEmpty) {
                showAppSnackBar(context, '请先粘贴 JSON 备份内容', isError: true);
                return;
              }
              Navigator.pop(ctx);
              _importJsonBackup(context, ref, clean);
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  Future<void> _importJsonBackup(BuildContext context, WidgetRef ref, String rawText) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    try {
      // JSON 解析放入后台 isolate，避免大文件解析卡顿 UI (Web 不支持 isolate)
      final json = kIsWeb
          ? jsonDecode(rawText) as List<dynamic>
          : await Isolate.run(() => jsonDecode(rawText) as List<dynamic>);
      final notes = json.map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
      await ref.read(noteRepositoryProvider).importNotes(notes);
      messenger.showSnackBar(
        SnackBar(
          content: Text('成功导入 ${notes.length} 条笔记'),
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

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: '羽记 · FeatherNote',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.flutter_dash, size: 48, color: AppColors.primary),
      children: const [
        Text('羽记是一款追求极致轻盈、行云流水般书写体验的跨平台离线记事本应用。'),
        SizedBox(height: 12),
        Text('技术栈：Flutter · Riverpod · Drift/SQLite · GoRouter · Material 3'),
      ],
    );
  }
}
