import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/models/note.dart';
import '../../domain/repositories/note_repository.dart';

/// 基于 Drift SQLite 实现的高性能离线笔记仓储
class DriftNoteRepository implements NoteRepository {
  final AppDatabase _db;

  DriftNoteRepository(this._db);

  @override
  Stream<List<Note>> watchActiveNotes({String? tagFilter}) {
    return _db
        .watchActiveNotes(tagFilter: tagFilter)
        .map((entries) => entries.map(Note.fromEntry).toList());
  }

  @override
  Stream<List<Note>> watchArchivedNotes() {
    return _db.watchArchivedNotes().map((entries) => entries.map(Note.fromEntry).toList());
  }

  @override
  Stream<List<Note>> watchDeletedNotes() {
    return _db.watchDeletedNotes().map((entries) => entries.map(Note.fromEntry).toList());
  }

  @override
  Stream<List<Note>> searchNotes(String query) {
    return _db.searchNotes(query).map((entries) => entries.map(Note.fromEntry).toList());
  }

  @override
  Future<Note?> getNoteById(String id) async {
    final entry = await _db.getNoteById(id);
    return entry != null ? Note.fromEntry(entry) : null;
  }

  @override
  Stream<Note?> watchNoteById(String id) {
    return _db.watchNoteById(id).map((entry) => entry != null ? Note.fromEntry(entry) : null);
  }

  @override
  Future<void> saveNote(Note note) async {
    // 去除逗号：标签以逗号分隔存储，标签名本身不能包含逗号
    final cleanTags = note.tags
        .map((t) => t.trim().replaceAll(',', ''))
        .where((t) => t.isNotEmpty)
        .toSet();

    final now = DateTime.now();
    await _db.batch((batch) {
      for (final tag in cleanTags) {
        batch.insert(
          _db.tagsTable,
          TagsTableCompanion(
            id: Value(tag),
            name: Value(tag),
            createdAt: Value(now),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
      batch.insert(
        _db.notesTable,
        note.toCompanion(),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  @override
  Future<void> softDeleteNote(String id) async {
    await _db.softDeleteNote(id);
  }

  @override
  Future<void> restoreNote(String id) async {
    await _db.restoreNote(id);
  }

  @override
  Future<void> toggleArchiveNote(String id, bool isArchived) async {
    await _db.toggleArchiveNote(id, isArchived);
  }

  @override
  Future<void> togglePinNote(String id, bool isPinned) async {
    await _db.togglePinNote(id, isPinned);
  }

  @override
  Future<void> updateNoteColor(String id, String colorId) async {
    await _db.updateNoteColor(id, colorId);
  }

  @override
  Future<void> permanentlyDeleteNote(String id) async {
    await _db.permanentlyDeleteNote(id);
  }

  @override
  Future<void> emptyTrash() async {
    await _db.emptyTrash();
  }

  @override
  Future<List<Note>> getAllNotes() async {
    final entries = await _db.getAllNotes();
    return entries.map(Note.fromEntry).toList();
  }

  @override
  Future<List<Note>> getNotesByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final entries = await (_db.select(_db.notesTable)..where((tbl) => tbl.id.isIn(ids))).get();
    return entries.map(Note.fromEntry).toList();
  }

  @override
  Future<void> saveNotes(List<Note> notes) async {
    if (notes.isEmpty) return;
    // 单次批量写入，避免逐条保存造成的多次事务与多次流式刷新
    await _db.batch((batch) {
      for (final note in notes) {
        batch.insert(_db.notesTable, note.toCompanion(), mode: InsertMode.insertOrReplace);
      }
    });
  }

  @override
  Future<void> importNotes(List<Note> notes) async {
    final now = DateTime.now();
    final allTags = <String>{};
    for (final note in notes) {
      for (final tag in note.tags) {
        final clean = tag.trim().replaceAll(',', '');
        if (clean.isNotEmpty) {
          allTags.add(clean);
        }
      }
    }

    await _db.batch((batch) {
      // 批量同步标签
      for (final tag in allTags) {
        batch.insert(
          _db.tagsTable,
          TagsTableCompanion(
            id: Value(tag),
            name: Value(tag),
            createdAt: Value(now),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
      // 批量写入笔记
      for (final note in notes) {
        batch.insert(
          _db.notesTable,
          note.toCompanion(),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }
}
