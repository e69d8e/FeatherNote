import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:feathernote/core/database/app_database.dart';
import 'package:feathernote/core/providers/database_provider.dart';
import 'package:feathernote/core/providers/shared_preferences_provider.dart';
import 'package:feathernote/features/notes/data/repositories/drift_note_repository.dart';
import 'package:feathernote/features/notes/domain/models/note.dart';
import 'package:feathernote/features/notes/presentation/screens/note_list_screen.dart';
import 'package:feathernote/features/settings/data/repositories/shared_prefs_settings_repository.dart';
import 'package:feathernote/features/settings/domain/models/app_settings.dart';
import 'package:feathernote/features/settings/presentation/controllers/settings_controller.dart';
import 'package:feathernote/features/tags/presentation/controllers/tags_controller.dart';
import 'package:feathernote/features/todos/presentation/controllers/todo_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DriftNoteRepository repo;
  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftNoteRepository(db);

    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
        noteRepositoryProvider.overrideWithValue(repo),
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(SharedPrefsSettingsRepository(prefs), const AppSettings()),
        ),
      ],
    );

    // 预置一篇普通笔记 + 一篇含待办的笔记，避免空状态动画干扰 settle
    final now = DateTime.now();
    await repo.saveNote(Note(
      id: 'seed-1',
      title: '普通笔记',
      content: '正文内容',
      createdAt: now,
      updatedAt: now,
    ));
    await repo.saveNote(Note(
      id: 'seed-2',
      title: '待办清单',
      content: '- [ ] 已有待办一\n- [x] 已有待办二',
      tags: ['清单'],
      createdAt: now,
      updatedAt: now,
    ));
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Widget buildApp() {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: NoteListScreen()),
    );
  }

  testWidgets('新建标签流程不卡死且数据落库', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('新建标签'));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(find.byType(TextField), '工作');
    await tester.tap(find.widgetWithText(FilledButton, '创建'));

    // 对话框退出动画 + 流刷新，逐帧推进
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final tags = await container.read(tagsStreamProvider.future);
    expect(tags.map((t) => t.name), contains('工作'));
  }, timeout: const Timeout(Duration(seconds: 45)));

  testWidgets('新建待办流程不卡死且数据落库', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump(const Duration(seconds: 1));

    // 切到待办 Tab (种子数据 1 条未完成)
    await tester.tap(find.text('待办 (1)'));
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.tap(find.text('加待办'));
    await tester.pump(const Duration(milliseconds: 400));

    // 待办页本身有一个快捷输入框，对话框内的输入框需要限定范围
    await tester.enterText(
      find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)),
      '写周报',
    );
    await tester.tap(find.widgetWithText(FilledButton, '添加'));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final todos = container.read(allTodosProvider);
    expect(todos.map((t) => t.text), contains('写周报'));
  }, timeout: const Timeout(Duration(seconds: 45)));
}
