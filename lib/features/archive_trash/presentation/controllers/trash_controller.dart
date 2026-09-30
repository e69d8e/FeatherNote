import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../notes/domain/models/note.dart';

/// 废纸篓笔记 StreamProvider (autoDispose：离开页面即取消数据库订阅，不再常驻刷新)
final trashNotesStreamProvider = StreamProvider.autoDispose<List<Note>>((ref) {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.watchDeletedNotes();
});

/// 废纸篓操作 Controller
class TrashController {
  final Ref _ref;

  TrashController(this._ref);

  /// 恢复笔记
  Future<void> restoreNote(Note note) async {
    await _ref.read(noteRepositoryProvider).restoreNote(note.id);
  }

  /// 永久删除
  Future<void> permanentlyDelete(Note note) async {
    await _ref.read(noteRepositoryProvider).permanentlyDeleteNote(note.id);
  }

  /// 清空废纸篓
  Future<void> emptyTrash() async {
    await _ref.read(noteRepositoryProvider).emptyTrash();
  }
}

final trashControllerProvider = Provider<TrashController>((ref) => TrashController(ref));
