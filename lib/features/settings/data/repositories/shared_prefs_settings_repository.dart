import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// 基于 SharedPreferences 的设置仓储实现
class SharedPrefsSettingsRepository implements SettingsRepository {
  final SharedPreferences _prefs;

  static const _keyThemeMode = 'feathernote_theme_mode';
  static const _keyViewMode = 'feathernote_view_mode';
  static const _keySortField = 'feathernote_sort_field';
  static const _keySortAsc = 'feathernote_sort_asc';
  static const _keyFontScale = 'feathernote_font_scale';
  static const _keyDefaultColor = 'feathernote_default_color';
  static const _keyAutoSaveMd = 'feathernote_auto_save_md';

  SharedPrefsSettingsRepository(this._prefs);

  @override
  Future<AppSettings> loadSettings() async {
    final themeIndex = _prefs.getInt(_keyThemeMode);
    final themeMode = themeIndex != null && themeIndex < ThemeMode.values.length
        ? ThemeMode.values[themeIndex]
        : ThemeMode.system;

    final viewIndex = _prefs.getInt(_keyViewMode);
    final viewMode = viewIndex != null && viewIndex < NoteViewMode.values.length
        ? NoteViewMode.values[viewIndex]
        : NoteViewMode.staggered;

    final sortIndex = _prefs.getInt(_keySortField);
    final sortField = sortIndex != null && sortIndex < NoteSortField.values.length
        ? NoteSortField.values[sortIndex]
        : NoteSortField.updatedAt;

    final sortAsc = _prefs.getBool(_keySortAsc) ?? false;
    final fontScale = _prefs.getDouble(_keyFontScale) ?? 1.0;
    final defaultColor = _prefs.getString(_keyDefaultColor) ?? 'default';
    final autoSaveMd = _prefs.getBool(_keyAutoSaveMd) ?? true;

    return AppSettings(
      themeMode: themeMode,
      viewMode: viewMode,
      sortField: sortField,
      sortAscending: sortAsc,
      fontScale: fontScale,
      defaultColorId: defaultColor,
      autoSaveMarkdown: autoSaveMd,
    );
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setInt(_keyThemeMode, settings.themeMode.index);
    await _prefs.setInt(_keyViewMode, settings.viewMode.index);
    await _prefs.setInt(_keySortField, settings.sortField.index);
    await _prefs.setBool(_keySortAsc, settings.sortAscending);
    await _prefs.setDouble(_keyFontScale, settings.fontScale);
    await _prefs.setString(_keyDefaultColor, settings.defaultColorId);
    await _prefs.setBool(_keyAutoSaveMd, settings.autoSaveMarkdown);
  }
}
