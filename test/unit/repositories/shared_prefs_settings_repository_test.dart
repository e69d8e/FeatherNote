import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:feathernote/features/settings/data/repositories/shared_prefs_settings_repository.dart';
import 'package:feathernote/features/settings/domain/models/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPrefsSettingsRepository', () {
    test('初始无数据时加载默认设置', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPrefsSettingsRepository(prefs);

      final settings = await repo.loadSettings();
      expect(settings.themeMode, equals(ThemeMode.system));
      expect(settings.viewMode, equals(NoteViewMode.staggered));
      expect(settings.sortField, equals(NoteSortField.updatedAt));
      expect(settings.sortAscending, isFalse);
      expect(settings.fontScale, equals(1.0));
      expect(settings.defaultColorId, equals('default'));
      expect(settings.autoSaveMarkdown, isTrue);
    });

    test('保存设置并成功二次读取', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPrefsSettingsRepository(prefs);

      const customSettings = AppSettings(
        themeMode: ThemeMode.dark,
        viewMode: NoteViewMode.list,
        sortField: NoteSortField.createdAt,
        sortAscending: true,
        fontScale: 1.25,
        defaultColorId: 'sakura',
        autoSaveMarkdown: false,
      );

      await repo.saveSettings(customSettings);

      final reloaded = await repo.loadSettings();
      expect(reloaded, equals(customSettings));
      expect(reloaded.themeMode, equals(ThemeMode.dark));
      expect(reloaded.viewMode, equals(NoteViewMode.list));
      expect(reloaded.sortField, equals(NoteSortField.createdAt));
      expect(reloaded.sortAscending, isTrue);
      expect(reloaded.fontScale, equals(1.25));
      expect(reloaded.defaultColorId, equals('sakura'));
      expect(reloaded.autoSaveMarkdown, isFalse);
    });
  });
}
