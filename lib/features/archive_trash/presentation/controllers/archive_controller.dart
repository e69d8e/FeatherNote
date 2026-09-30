import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../notes/domain/models/note.dart';

/// 已归档笔记 StreamProvider (autoDispose：离开页面即取消数据库订阅，不再常驻刷新)
final archivedNotesStreamProvider = StreamProvider.autoDispose<List<Note>>((ref) {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.watchArchivedNotes();
});

/// 归档操作 Controller
class ArchiveController {
  final Ref _ref;

  ArchiveController(this._ref);

  Future<void> unarchive(Note note) async {
    await _ref.read(noteRepositoryProvider).toggleArchiveNote(note.id, false);
  }

  Future<void> moveToTrash(Note note) async {
    await _ref.read(noteRepositoryProvider).softDeleteNote(note.id);
  }
}

final archiveControllerProvider = Provider<ArchiveController>((ref) => ArchiveController(ref));
