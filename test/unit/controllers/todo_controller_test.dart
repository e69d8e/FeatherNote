import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:feathernote/core/providers/shared_preferences_provider.dart';
import 'package:feathernote/core/database/app_database.dart';
import 'package:feathernote/core/providers/database_provider.dart';
import 'package:feathernote/features/notes/data/repositories/drift_note_repository.dart';
import 'package:feathernote/features/notes/domain/models/note.dart';
import 'package:feathernote/features/notes/presentation/controllers/note_list_controller.dart';
import 'package:feathernote/features/todos/domain/models/todo_item.dart';
import 'package:feathernote/features/todos/presentation/controllers/todo_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TodoController & Todo Providers', () {
    late AppDatabase db;
    late DriftNoteRepository repo;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = DriftNoteRepository(db);

      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          noteRepositoryProvider.overrideWithValue(repo),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('从笔记正文中解析提取全部、待完成与已完成待办项', () async {
      final now = DateTime.now();
      final note = Note(
        id: 'n-todo-1',
        title: '测试待办笔记',
        content: '''- [ ] 任务一
- [x] 任务二 (已完成)
* [ ] 任务三 (星号未完成)
正文普通文本段落
- [X] 任务四 (大写完成)''',
        createdAt: now,
        updatedAt: now,
      );

      await repo.saveNote(note);

      // 等待 activeNotesStreamProvider 加载
      await container.read(activeNotesStreamProvider.future);

      final allTodos = container.read(allTodosProvider);
      expect(allTodos.length, equals(4));

      final pending = container.read(pendingTodosProvider);
      expect(pending.length, equals(2));
      expect(pending.map((t) => t.text), containsAll(['任务一', '任务三 (星号未完成)']));

      final completed = container.read(completedTodosProvider);
      expect(completed.length, equals(2));
      expect(completed.map((t) => t.text), containsAll(['任务二 (已完成)', '任务四 (大写完成)']));
    });

    test('切换待办状态 toggleTodo', () async {
      final now = DateTime.now();
      final note = Note(
        id: 'n-todo-2',
        title: '清单',
        content: '- [ ] 待完成事项',
        tags: ['清单'],
        createdAt: now,
        updatedAt: now,
      );

      await repo.saveNote(note);
      await container.read(activeNotesStreamProvider.future);

      final controller = container.read(todoControllerProvider);
      final item = TodoItem(
        id: 'n-todo-2_0',
        noteId: 'n-todo-2',
        noteTitle: '清单',
        indexInNote: 0,
        text: '待完成事项',
        isCompleted: false,
        noteColorId: 'default',
        updatedAt: now,
      );

      await controller.toggleTodo(item);

      final updated = await repo.getNoteById('n-todo-2');
      expect(updated!.content, contains('- [x] 待完成事项'));
    });

    test('添加新待办项 addTodo 追加到现有清单笔记', () async {
      final now = DateTime.now();
      final note = Note(
        id: 'n-todo-3',
        title: '项目待办',
        content: '- [x] 已完成项',
        tags: ['清单'],
        createdAt: now,
        updatedAt: now,
      );

      await repo.saveNote(note);
      await container.read(activeNotesStreamProvider.future);

      final controller = container.read(todoControllerProvider);
      await controller.addTodo('新增待办测试');

      final updated = await repo.getNoteById('n-todo-3');
      expect(updated!.content, contains('- [ ] 新增待办测试'));
    });

    test('删除单条待办 deleteTodo 与 清空已完成 clearAllCompleted', () async {
      final now = DateTime.now();
      final note = Note(
        id: 'n-todo-4',
        title: '日常清单',
        content: '- [ ] 事项A\n- [x] 事项B\n- [x] 事项C',
        tags: ['清单'],
        createdAt: now,
        updatedAt: now,
      );

      await repo.saveNote(note);
      await container.read(activeNotesStreamProvider.future);

      final controller = container.read(todoControllerProvider);

      // 删除单条待办
      final itemA = TodoItem(
        id: 'n-todo-4_0',
        noteId: 'n-todo-4',
        noteTitle: '日常清单',
        indexInNote: 0,
        text: '事项A',
        isCompleted: false,
        noteColorId: 'default',
        updatedAt: now,
      );
      await controller.deleteTodo(itemA);

      final noteAfterDelete = await repo.getNoteById('n-todo-4');
      expect(noteAfterDelete!.content.contains('事项A'), isFalse);
      expect(noteAfterDelete.content.contains('事项B'), isTrue);

      // 一键清空所有已完成
      await container.read(activeNotesStreamProvider.future);
      await controller.clearAllCompleted();

      final noteAfterClear = await repo.getNoteById('n-todo-4');
      expect(noteAfterClear!.content.contains('事项B'), isFalse);
      expect(noteAfterClear.content.contains('事项C'), isFalse);
    });
  });
}
