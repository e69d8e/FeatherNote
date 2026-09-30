import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feathernote/core/database/app_database.dart';
import 'package:feathernote/core/utils/date_formatter.dart';
import 'package:feathernote/core/utils/text_utils.dart';
import 'package:feathernote/features/notes/data/repositories/drift_note_repository.dart';
import 'package:feathernote/features/notes/domain/models/note.dart';
import 'package:feathernote/features/settings/domain/models/app_settings.dart';
import 'package:feathernote/features/todos/domain/models/todo_item.dart';

void main() {
  group('FeatherNote Utils & Domain Models', () {
    test('TextUtils word count and snippet', () {
      const text = '# 标题\n这是一篇**测试**笔记，包含中文字符和 English words 123。';
      final words = TextUtils.countWords(text);
      expect(words, greaterThan(0));

      final snippet = TextUtils.getSnippet(text, maxLength: 20);
      expect(snippet.contains('#'), isFalse);
      expect(snippet.contains('**'), isFalse);

      final readingTime = TextUtils.estimateReadingTime('测试文本');
      expect(readingTime, equals('1 分钟'));

      // 待办清单勾选切换测试
      const mdList = '- [ ] 未完成事项\n- [x] 已完成事项\n  - [ ] 嵌套待办\n* [ ] 星号待办\n+ [ ] 加号待办';
      final toggled0 = TextUtils.toggleCheckboxAt(mdList, 0);
      expect(toggled0.contains('- [x] 未完成事项'), isTrue);

      final toggled1 = TextUtils.toggleCheckboxAt(mdList, 1);
      expect(toggled1.contains('- [ ] 已完成事项'), isTrue);

      final toggled2 = TextUtils.toggleCheckboxAt(mdList, 2);
      expect(toggled2.contains('  - [x] 嵌套待办'), isTrue);

      final toggled3 = TextUtils.toggleCheckboxAt(mdList, 3);
      expect(toggled3.contains('* [x] 星号待办'), isTrue);

      final toggled4 = TextUtils.toggleCheckboxAt(mdList, 4);
      expect(toggled4.contains('+ [x] 加号待办'), isTrue);
    });

    test('DateFormatter formatting', () {
      final now = DateTime.now();
      expect(DateFormatter.formatRelative(now), equals('刚刚'));

      final past = DateTime(2026, 1, 1, 10, 0);
      expect(DateFormatter.formatShort(past), equals('2026-01-01'));
    });

    test('Note JSON serialization and copyWith', () {
      final now = DateTime.now();
      final note = Note(
        id: 'test-uuid-1',
        title: '测试标题',
        content: '测试内容 Markdown',
        colorId: 'sakura',
        tags: ['测试', '生活'],
        createdAt: now,
        updatedAt: now,
      );

      final json = note.toJson();
      final fromJson = Note.fromJson(json);

      expect(fromJson.id, equals('test-uuid-1'));
      expect(fromJson.title, equals('测试标题'));
      expect(fromJson.colorId, equals('sakura'));
      expect(fromJson.tags, contains('测试'));

      final updated = note.copyWith(title: '新标题', isPinned: true);
      expect(updated.title, equals('新标题'));
      expect(updated.isPinned, isTrue);
    });

    test('TodoItem model attributes and copyWith', () {
      final now = DateTime.now();
      final todo = TodoItem(
        id: 'note-1_0',
        noteId: 'note-1',
        noteTitle: '测试笔记',
        indexInNote: 0,
        text: '完成羽记测试',
        isCompleted: false,
        noteColorId: 'white',
        updatedAt: now,
      );

      expect(todo.isCompleted, isFalse);
      final completedTodo = todo.copyWith(isCompleted: true);
      expect(completedTodo.isCompleted, isTrue);
      expect(completedTodo.text, equals('完成羽记测试'));
    });

    test('AppSettings defaults and font scale', () {
      const settings = AppSettings();
      expect(settings.viewMode, equals(NoteViewMode.staggered));
      expect(settings.sortField, equals(NoteSortField.updatedAt));
      expect(settings.fontScale, equals(1.0));

      final scaled = settings.copyWith(fontScale: 1.1);
      expect(scaled.fontScale, equals(1.1));
    });
  });

  group('DriftNoteRepository in-memory DB tests', () {
    late AppDatabase db;
    late DriftNoteRepository repo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = DriftNoteRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Save, query, pin, archive and soft-delete note', () async {
      final now = DateTime.now();
      final note = Note(
        id: 'note-1',
        title: '第一篇羽记',
        content: '离线优先设计',
        colorId: 'sage',
        tags: ['工作'],
        createdAt: now,
        updatedAt: now,
      );

      // 保存笔记
      await repo.saveNote(note);

      // 查询单条笔记
      final fetched = await repo.getNoteById('note-1');
      expect(fetched, isNotNull);
      expect(fetched!.title, equals('第一篇羽记'));
      expect(fetched.tags, contains('工作'));

      // 搜索测试
      final searchResults = await repo.searchNotes('羽记').first;
      expect(searchResults.length, equals(1));
      expect(searchResults.first.id, equals('note-1'));

      // 置顶测试
      await repo.togglePinNote('note-1', true);
      final pinned = await repo.getNoteById('note-1');
      expect(pinned!.isPinned, isTrue);

      // 归档测试
      await repo.toggleArchiveNote('note-1', true);
      final archived = await repo.watchArchivedNotes().first;
      expect(archived.length, equals(1));

      // 软删除测试
      await repo.softDeleteNote('note-1');
      final deleted = await repo.watchDeletedNotes().first;
      expect(deleted.length, equals(1));

      // 从废纸篓恢复测试
      await repo.restoreNote('note-1');
      final restored = await repo.getNoteById('note-1');
      expect(restored!.isDeleted, isFalse);

      // 清空废纸篓测试
      await repo.softDeleteNote('note-1');
      await repo.emptyTrash();
      final afterEmpty = await repo.watchDeletedNotes().first;
      expect(afterEmpty.isEmpty, isTrue);
    });

    test('Batch importNotes and tag synchronization', () async {
      final now = DateTime.now();
      final notes = [
        Note(
          id: 'batch-1',
          title: '批量笔记1',
          content: '正文1',
          tags: ['标签A', '标签B'],
          createdAt: now,
          updatedAt: now,
        ),
        Note(
          id: 'batch-2',
          title: '批量笔记2',
          content: '正文2',
          tags: ['标签B', '标签C'],
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await repo.importNotes(notes);

      final allNotes = await repo.getAllNotes();
      expect(allNotes.length, equals(2));

      final allTags = await db.watchAllTags().first;
      final tagNames = allTags.map((t) => t.name).toList();
      expect(tagNames, containsAll(['标签A', '标签B', '标签C']));
    });

    test('Tag filter matches tags exactly, not by substring', () async {
      final now = DateTime.now();
      await repo.saveNote(Note(
        id: 'tag-note-1',
        title: '工作笔记',
        content: '正文',
        tags: ['工作', '日常'],
        createdAt: now,
        updatedAt: now,
      ));
      await repo.saveNote(Note(
        id: 'tag-note-2',
        title: '工作任务清单',
        content: '正文',
        tags: ['工作任务'],
        createdAt: now,
        updatedAt: now,
      ));

      // 精确匹配「工作」只应命中第一条，不应被子串误伤到「工作任务」
      final byExact = await repo.watchActiveNotes(tagFilter: '工作').first;
      expect(byExact.map((n) => n.id).toList(), equals(['tag-note-1']));

      final byCompound = await repo.watchActiveNotes(tagFilter: '工作任务').first;
      expect(byCompound.map((n) => n.id).toList(), equals(['tag-note-2']));
    });

    test('getNotesByIds and batch saveNotes', () async {
      final now = DateTime.now();
      await repo.importNotes([
        Note(id: 'b1', title: '笔记1', content: '内容1', createdAt: now, updatedAt: now),
        Note(id: 'b2', title: '笔记2', content: '内容2', createdAt: now, updatedAt: now),
        Note(id: 'b3', title: '笔记3', content: '内容3', createdAt: now, updatedAt: now),
      ]);

      final fetched = await repo.getNotesByIds(['b1', 'b3']);
      expect(fetched.length, equals(2));

      // 批量更新内容 (clearAllCompleted 的写入路径)
      final notes = await repo.getNotesByIds(['b1', 'b2']);
      await repo.saveNotes(notes.map((n) => n.copyWith(content: '${n.content}-updated')).toList());
      final updated = await repo.getNoteById('b1');
      expect(updated!.content, equals('内容1-updated'));

      // 空入参不抛错
      await repo.saveNotes(const []);
      expect(await repo.getNotesByIds(const []), isEmpty);
    });

    test('FTS search: substring matching, sync triggers and short-query fallback', () async {
      final now = DateTime.now();
      await repo.saveNote(Note(
        id: 'fts-1',
        title: 'Flutter 性能优化笔记',
        content: '研究 trigram 分词与全文索引的落地',
        tags: ['技术'],
        createdAt: now,
        updatedAt: now,
      ));

      // 首次查询会触发惰性迁移，FTS 索引必须创建成功，
      // 否则搜索静默退化为 LIKE，此测试也就失去了意义
      expect(db.ftsAvailable, isTrue, reason: 'FTS 创建失败: ${db.ftsLastError}');

      await repo.saveNote(Note(
        id: 'fts-2',
        title: '购物清单',
        content: '牛奶、鸡蛋、面包',
        createdAt: now,
        updatedAt: now,
      ));
      await repo.saveNote(Note(
        id: 'fts-3',
        title: '性能优化草稿',
        content: '待整理',
        isDeleted: true,
        createdAt: now,
        updatedAt: now,
      ));

      // ≥3 字符中文子串匹配，命中正文 (走 FTS 路径)
      final byContent = await repo.searchNotes('全文索引').first;
      expect(byContent.map((n) => n.id).toList(), equals(['fts-1']));

      // 已删除笔记不参与搜索
      final deletedExcluded = await repo.searchNotes('性能优化草稿').first;
      expect(deletedExcluded.map((n) => n.id), isNot(contains('fts-3')));

      // 写入后索引保持同步 (触发器)
      await repo.saveNote(Note(
        id: 'fts-4',
        title: '新笔记',
        content: '刚刚加入的羽毛收藏清单',
        createdAt: now,
        updatedAt: now,
      ));
      final afterInsert = await repo.searchNotes('羽毛收藏').first;
      expect(afterInsert.map((n) => n.id).toList(), equals(['fts-4']));

      // 更新后索引同步刷新
      final fetched4 = await repo.getNoteById('fts-4');
      await repo.saveNote(fetched4!.copyWith(content: '改成整理计划了'));
      final afterUpdate = await repo.searchNotes('羽毛收藏').first;
      expect(afterUpdate, isEmpty);

      // 删除后索引同步清理
      await repo.softDeleteNote('fts-4');
      final afterSoftDelete = await repo.searchNotes('整理计划').first;
      expect(afterSoftDelete, isEmpty);

      // INSERT OR REPLACE 路径 (saveNote 即 insertOrReplace) 不会留下重复命中
      final duplicates = await repo.searchNotes('性能优化笔记').first;
      expect(duplicates.where((n) => n.id == 'fts-1').length, equals(1));

      // 短查询 (<3 字符) 走 LIKE 回退路径
      final shortQuery = await repo.searchNotes('牛奶').first;
      expect(shortQuery.map((n) => n.id).toList(), equals(['fts-2']));
    });
  });
}
