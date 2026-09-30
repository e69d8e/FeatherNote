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
    return _db.watchAllTags().map((entries) => entries.map(Tag.fromEntry).toList());
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
