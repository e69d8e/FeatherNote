import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/models/tag.dart';
import '../../domain/repositories/tag_repository.dart';

/// Drift 标签仓储实现
class DriftTagRepository implements TagRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  DriftTagRepository(this._db);

  @override
  Stream<List<Tag>> watchAllTags() {
    return _db.watchAllTags().map(
      (entries) => entries.map(Tag.fromEntry).toList(),
    );
  }

  @override
  Future<List<Tag>> getAllTags() async {
    final entries = await _db.select(_db.tagsTable).get();
    return entries.map(Tag.fromEntry).toList();
  }

  @override
  Future<void> importTags(List<Tag> tags) async {
    if (tags.isEmpty) return;
    final existing = {
      for (final entry in await _db.select(_db.tagsTable).get())
        entry.name: entry,
    };
    await _db.batch((batch) {
      for (final tag in tags) {
        final name = tag.name.trim();
        if (name.isEmpty) continue;
        if (existing.containsKey(name)) {
          batch.update(
            _db.tagsTable,
            TagsTableCompanion(color: Value(tag.color)),
            where: (tbl) => tbl.name.equals(name),
          );
        } else {
          batch.insert(
            _db.tagsTable,
            TagsTableCompanion(
              id: Value(name),
              name: Value(name),
              color: Value(tag.color),
              createdAt: Value(tag.createdAt),
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
      }
    });
  }

  @override
  Future<void> addTag(String name, {String? color}) async {
    final clean = name.trim();
    if (clean.isEmpty) return;

    await _db.insertTag(
      TagsTableCompanion(
        id: Value(_uuid.v4()),
        name: Value(clean),
        color: Value(color),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteTag(String id) async {
    await _db.deleteTag(id);
  }
}
