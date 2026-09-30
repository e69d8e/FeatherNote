import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:feathernote/core/providers/shared_preferences_provider.dart';
import 'package:feathernote/features/settings/data/repositories/shared_prefs_settings_repository.dart';
import 'package:feathernote/features/settings/domain/models/app_settings.dart';
import 'package:feathernote/features/settings/presentation/controllers/settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsController & SettingsNotifier', () {
    late ProviderContainer container;
    late SharedPrefsSettingsRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = SharedPrefsSettingsRepository(prefs);

      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          settingsRepositoryProvider.overrideWithValue(repo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('更新主题模式 updateThemeMode', () async {
      final notifier = container.read(settingsProvider.notifier);
      await notifier.updateThemeMode(ThemeMode.dark);

      expect(container.read(settingsProvider).themeMode, equals(ThemeMode.dark));

      final persisted = await repo.loadSettings();
      expect(persisted.themeMode, equals(ThemeMode.dark));
    });

    test('更新卡片视图模式 updateViewMode', () async {
      final notifier = container.read(settingsProvider.notifier);
      await notifier.updateViewMode(NoteViewMode.list);

      expect(container.read(settingsProvider).viewMode, equals(NoteViewMode.list));

      final persisted = await repo.loadSettings();
      expect(persisted.viewMode, equals(NoteViewMode.list));
    });

    test('更新排序方式与升降序 updateSort', () async {
      final notifier = container.read(settingsProvider.notifier);
      await notifier.updateSort(NoteSortField.title, true);

      final state = container.read(settingsProvider);
      expect(state.sortField, equals(NoteSortField.title));
      expect(state.sortAscending, isTrue);

      final persisted = await repo.loadSettings();
      expect(persisted.sortField, equals(NoteSortField.title));
      expect(persisted.sortAscending, isTrue);
    });

    test('更新字体缩放比例 updateFontScale', () async {
      final notifier = container.read(settingsProvider.notifier);
      await notifier.updateFontScale(1.15);

      expect(container.read(settingsProvider).fontScale, equals(1.15));

      final persisted = await repo.loadSettings();
      expect(persisted.fontScale, equals(1.15));
    });

    test('更新默认卡片配色 updateDefaultColor', () async {
      final notifier = container.read(settingsProvider.notifier);
      await notifier.updateDefaultColor('lavender');

      expect(container.read(settingsProvider).defaultColorId, equals('lavender'));

      final persisted = await repo.loadSettings();
      expect(persisted.defaultColorId, equals('lavender'));
    });

    test('切换 Markdown 自动保存 toggleAutoSaveMarkdown', () async {
      final notifier = container.read(settingsProvider.notifier);
      await notifier.toggleAutoSaveMarkdown(false);

      expect(container.read(settingsProvider).autoSaveMarkdown, isFalse);

      final persisted = await repo.loadSettings();
      expect(persisted.autoSaveMarkdown, isFalse);
    });
  });
}
