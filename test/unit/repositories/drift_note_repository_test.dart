import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feathernote/core/database/app_database.dart';
import 'package:feathernote/features/notes/data/repositories/drift_note_repository.dart';
import 'package:feathernote/features/notes/domain/models/note.dart';

void main() {
  group('DriftNoteRepository (In-Memory SQLite)', () {
    late AppDatabase db;
    late DriftNoteRepository repo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = DriftNoteRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('完整 CRUD、置顶、归档与废纸篓流程', () async {
      final now = DateTime.now();
      final note = Note(
        id: 'note-crud-1',
        title: '测试笔记标题',
        content: '测试正文内容，支持 Markdown。',
        colorId: 'sakura',
        tags: ['生活', '随笔'],
        createdAt: now,
        updatedAt: now,
      );

      // 1. 创建保存
      await repo.saveNote(note);

      // 2. 根据 ID 读取
      final fetched = await repo.getNoteById('note-crud-1');
      expect(fetched, isNotNull);
      expect(fetched!.title, equals('测试笔记标题'));
      expect(fetched.tags, containsAll(['生活', '随笔']));
      expect(fetched.colorId, equals('sakura'));

      // 验证标签表自动同步
      final allTags = await db.watchAllTags().first;
      expect(allTags.map((t) => t.name), containsAll(['生活', '随笔']));

      // 3. 颜色更新
      await repo.updateNoteColor('note-crud-1', 'sage');
      final updatedColor = await repo.getNoteById('note-crud-1');
      expect(updatedColor!.colorId, equals('sage'));

      // 4. 置顶切换
      await repo.togglePinNote('note-crud-1', true);
      final pinned = await repo.getNoteById('note-crud-1');
      expect(pinned!.isPinned, isTrue);

      // 5. 归档测试
      await repo.toggleArchiveNote('note-crud-1', true);
      final archivedList = await repo.watchArchivedNotes().first;
      expect(archivedList.length, equals(1));
      expect(archivedList.first.id, equals('note-crud-1'));

      final activeList = await repo.watchActiveNotes().first;
      expect(activeList.isEmpty, isTrue);

      // 取消归档
      await repo.toggleArchiveNote('note-crud-1', false);
      final activeListAfter = await repo.watchActiveNotes().first;
      expect(activeListAfter.length, equals(1));

      // 6. 软删除测试 (移入废纸篓)
      await repo.softDeleteNote('note-crud-1');
      final trashList = await repo.watchDeletedNotes().first;
      expect(trashList.length, equals(1));
      expect(trashList.first.isDeleted, isTrue);

      // 从废纸篓恢复
      await repo.restoreNote('note-crud-1');
      final restored = await repo.getNoteById('note-crud-1');
      expect(restored!.isDeleted, isFalse);

      // 7. 永久删除单个笔记
      await repo.permanentlyDeleteNote('note-crud-1');
      final deleted = await repo.getNoteById('note-crud-1');
      expect(deleted, isNull);
    });

    test('按标签过滤活跃笔记与即时检索', () async {
      final now = DateTime.now();
      final n1 = Note(
        id: '1',
        title: 'Flutter 性能优化实录',
        content: '优化状态监听与渲染树重建',
        tags: ['技术', 'Flutter'],
        createdAt: now,
        updatedAt: now,
      );
      final n2 = Note(
        id: '2',
        title: '周末登山计划',
        content: '带好水和背包',
        tags: ['户外', '生活'],
        createdAt: now,
        updatedAt: now,
      );

      await repo.saveNote(n1);
      await repo.saveNote(n2);

      // 标签过滤
      final techNotes = await repo.watchActiveNotes(tagFilter: '技术').first;
      expect(techNotes.length, equals(1));
      expect(techNotes.first.id, equals('1'));

      // 全文检索 (标题或正文)
      final searchResults = await repo.searchNotes('登山').first;
      expect(searchResults.length, equals(1));
      expect(searchResults.first.id, equals('2'));

      final searchByTag = await repo.searchNotes('Flutter').first;
      expect(searchByTag.length, equals(1));
      expect(searchByTag.first.id, equals('1'));
    });

    test('批量导入笔记与清空废纸篓', () async {
      final now = DateTime.now();
      final batch = [
        Note(id: 'b1', title: '笔记1', content: 'c1', tags: ['T1'], createdAt: now, updatedAt: now),
        Note(id: 'b2', title: '笔记2', content: 'c2', tags: ['T2'], createdAt: now, updatedAt: now),
        Note(id: 'b3', title: '笔记3', content: 'c3', tags: ['T3'], createdAt: now, updatedAt: now),
      ];

      await repo.importNotes(batch);

      final all = await repo.getAllNotes();
      expect(all.length, equals(3));

      // 全部移入废纸篓并清空
      for (final n in batch) {
        await repo.softDeleteNote(n.id);
      }
      final trashBefore = await repo.watchDeletedNotes().first;
      expect(trashBefore.length, equals(3));

      await repo.emptyTrash();
      final trashAfter = await repo.watchDeletedNotes().first;
      expect(trashAfter.isEmpty, isTrue);
    });
  });
}
