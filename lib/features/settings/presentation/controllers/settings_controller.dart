import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// 应用设置状态通知器
class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsRepository _repo;

  SettingsNotifier(this._repo, AppSettings initial) : super(initial);

  /// 切换主题模式 (亮色/暗色/跟随系统)
  Future<void> updateThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _repo.saveSettings(state);
  }

  /// 切换视图布局 (瀑布流/网格/列表)
  Future<void> updateViewMode(NoteViewMode viewMode) async {
    state = state.copyWith(viewMode: viewMode);
    await _repo.saveSettings(state);
  }

  /// 切换排序字段
  Future<void> updateSort(NoteSortField field, bool ascending) async {
    state = state.copyWith(sortField: field, sortAscending: ascending);
    await _repo.saveSettings(state);
  }

  /// 调整字体缩放
  Future<void> updateFontScale(double scale) async {
    state = state.copyWith(fontScale: scale);
    await _repo.saveSettings(state);
  }

  /// 更改新建笔记默认卡片配色
  Future<void> updateDefaultColor(String colorId) async {
    state = state.copyWith(defaultColorId: colorId);
    await _repo.saveSettings(state);
  }

  /// 切换 Markdown 自动保存
  Future<void> toggleAutoSaveMarkdown(bool value) async {
    state = state.copyWith(autoSaveMarkdown: value);
    await _repo.saveSettings(state);
  }

  /// 切换启动时自动检查更新
  Future<void> toggleAutoCheckUpdate(bool value) async {
    state = state.copyWith(autoCheckUpdate: value);
    await _repo.saveSettings(state);
  }
}

/// 设置 StateNotifierProvider
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  // 默认初始设置，稍后可通过异步加载或初始化时同步覆盖
  return SettingsNotifier(repo, const AppSettings());
});
