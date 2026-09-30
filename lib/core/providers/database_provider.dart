import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../../features/notes/domain/repositories/note_repository.dart';
import '../../features/notes/data/repositories/drift_note_repository.dart';
import '../../features/tags/domain/repositories/tag_repository.dart';
import '../../features/tags/data/repositories/drift_tag_repository.dart';

/// 全局 Drift 数据库单例 Provider
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// 笔记仓储 Provider
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftNoteRepository(db);
});

/// 标签仓储 Provider
final tagRepositoryProvider = Provider<TagRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftTagRepository(db);
});
