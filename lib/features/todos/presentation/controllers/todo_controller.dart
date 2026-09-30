import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../notes/domain/models/note.dart';
import '../../../notes/presentation/controllers/note_list_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../domain/models/todo_item.dart';

/// 单条待办的解析中间结果 (与笔记元数据解耦，便于按内容缓存)
class _ParsedTodo {
  final int index;
  final bool isCompleted;
  final String text;
  const _ParsedTodo(this.index, this.isCompleted, this.text);
}

/// 待办解析缓存：笔记内容不变时直接复用上次解析结果，
/// 避免每次笔记流刷新都对全部笔记重新做正则扫描
final _todoParseCache = <String, List<_ParsedTodo>>{};

/// 从所有活跃笔记中解析提取出的全部待办清单项 Provider
final allTodosProvider = Provider<List<TodoItem>>((ref) {
  ref.onDispose(_todoParseCache.clear);
  final notes = ref.watch(activeNotesStreamProvider).valueOrNull ?? const <Note>[];

  final List<TodoItem> items = [];
  final usedIds = <String>{};

  for (final note in notes) {
    if (note.content.isEmpty) {
      _todoParseCache.remove(note.id);
      continue;
    }

    var parsed = _todoParseCache[note.id];
    if (parsed == null) {
      parsed = _parseTodoLines(note.content);
      _todoParseCache[note.id] = parsed;
    }

    for (final todo in parsed) {
      // 以内容指纹为主生成稳定 id：删除中间某条后其余 id 不漂移，
      // Dismissible 等依赖 key 的组件不会错位；同文本重复项用序号消歧
      var occurrence = 0;
      String id;
      do {
        id = occurrence == 0
            ? '${note.id}_${todo.text.hashCode}'
            : '${note.id}_${todo.text.hashCode}_$occurrence';
        occurrence++;
      } while (!usedIds.add(id));

      items.add(TodoItem(
        id: id,
        noteId: note.id,
        noteTitle: note.displayTitle,
        indexInNote: todo.index,
        text: todo.text,
        isCompleted: todo.isCompleted,
        noteColorId: note.colorId,
        updatedAt: note.updatedAt,
      ));
    }
  }

  return items;
});

List<_ParsedTodo> _parseTodoLines(String content) {
  final todos = <_ParsedTodo>[];
  int index = 0;
  for (final match in TextUtils.todoItemRegex.allMatches(content)) {
    final isChecked = match.group(2)?.toLowerCase() == 'x';
    final text = match.group(4)?.trim() ?? '';
    todos.add(_ParsedTodo(index, isChecked, text.isNotEmpty ? text : '(未命名待办)'));
    index++;
  }
  return todos;
}

/// 未完成的待办事项
final pendingTodosProvider = Provider<List<TodoItem>>((ref) {
  final all = ref.watch(allTodosProvider);
  return all.where((t) => !t.isCompleted).toList();
});

/// 已完成的待办事项
final completedTodosProvider = Provider<List<TodoItem>>((ref) {
  final all = ref.watch(allTodosProvider);
  return all.where((t) => t.isCompleted).toList();
});

/// 待办操作控制器
class TodoController {
  final Ref _ref;

  TodoController(this._ref);

  /// 切换指定待办的勾选状态
  Future<void> toggleTodo(TodoItem item) async {
    final noteRepo = _ref.read(noteRepositoryProvider);
    final note = await noteRepo.getNoteById(item.noteId);
    if (note == null) return;

    final newContent = TextUtils.toggleCheckboxAt(note.content, item.indexInNote);
    final updatedNote = note.copyWith(
      content: newContent,
      updatedAt: DateTime.now(),
    );
    await noteRepo.saveNote(updatedNote);
  }

  /// 快速添加一条新待办事项
  Future<void> addTodo(String title) async {
    final clean = title.trim();
    if (clean.isEmpty) return;

    final noteRepo = _ref.read(noteRepositoryProvider);
    final notes = _ref.read(activeNotesStreamProvider).valueOrNull ?? [];

    // 寻找最近带有 #清单 标签或名为 "待办清单" 的笔记
    Note? targetNote;
    for (final n in notes) {
      if (n.tags.contains('清单') || n.title.contains('待办') || n.title.contains('清单')) {
        targetNote = n;
        break;
      }
    }

    if (targetNote != null) {
      // 在目标笔记末尾追加该待办项
      final newContent = targetNote.content.isEmpty
          ? '- [ ] $clean'
          : '${targetNote.content.trimRight()}\n- [ ] $clean';
      final updated = targetNote.copyWith(
        content: newContent,
        updatedAt: DateTime.now(),
      );
      await noteRepo.saveNote(updated);
    } else {
      // 若无现有待办笔记，则自动新建一篇「我的待办清单」笔记
      final defaultColor = _ref.read(settingsProvider).defaultColorId;
      final now = DateTime.now();
      final newNote = Note(
        id: const Uuid().v4(),
        title: '我的待办清单 📋',
        content: '- [ ] $clean',
        colorId: defaultColor,
        tags: ['清单'],
        createdAt: now,
        updatedAt: now,
      );
      await noteRepo.saveNote(newNote);
    }
  }

  /// 删除某一条待办事项
  Future<void> deleteTodo(TodoItem item) async {
    final noteRepo = _ref.read(noteRepositoryProvider);
    final note = await noteRepo.getNoteById(item.noteId);
    if (note == null) return;

    int currentIndex = 0;
    final lines = note.content.split('\n');
    final newLines = <String>[];

    for (final line in lines) {
      if (TextUtils.todoItemRegex.hasMatch(line)) {
        if (currentIndex == item.indexInNote) {
          currentIndex++;
          continue; // 移除该行
        }
        currentIndex++;
      }
      newLines.add(line);
    }

    final updated = note.copyWith(
      content: newLines.join('\n').trim(),
      updatedAt: DateTime.now(),
    );
    await noteRepo.saveNote(updated);
  }

  /// 一键清空所有已完成的待办事项 (单次批量读取 + 单次批量写入)
  Future<void> clearAllCompleted() async {
    final completed = _ref.read(completedTodosProvider);
    if (completed.isEmpty) return;
    final noteRepo = _ref.read(noteRepositoryProvider);

    final noteIds = completed.map((c) => c.noteId).toSet().toList();
    final notes = await noteRepo.getNotesByIds(noteIds);

    final now = DateTime.now();
    final updated = <Note>[];
    for (final note in notes) {
      final newContent = note.content
          .split('\n')
          .where((line) => !TextUtils.completedTodoLineRegex.hasMatch(line))
          .join('\n')
          .trim();
      if (newContent != note.content) {
        updated.add(note.copyWith(content: newContent, updatedAt: now));
      }
    }
    if (updated.isEmpty) return;
    await noteRepo.saveNotes(updated);
  }
}

final todoControllerProvider = Provider<TodoController>((ref) {
  return TodoController(ref);
});
