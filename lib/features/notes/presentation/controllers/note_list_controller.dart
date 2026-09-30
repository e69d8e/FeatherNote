import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/database_provider.dart';
import '../../domain/models/note.dart';
import '../../../tags/presentation/controllers/tags_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../settings/domain/models/app_settings.dart';

/// 活跃笔记列表 StreamProvider (结合标签筛选与偏好排序)
final activeNotesStreamProvider = StreamProvider<List<Note>>((ref) {
  final tagFilter = ref.watch(selectedTagFilterProvider);
  final repo = ref.watch(noteRepositoryProvider);
  final (sortField, sortAscending) = ref.watch(
    settingsProvider.select((s) => (s.sortField, s.sortAscending)),
  );

  return repo.watchActiveNotes(tagFilter: tagFilter).map((notes) {
    // 排序逻辑 (保持置顶在前，其余按用户设置排序)
    final pinned = notes.where((n) => n.isPinned).toList();
    final unpinned = notes.where((n) => !n.isPinned).toList();

    int Function(Note, Note) comparator;
    switch (sortField) {
      case NoteSortField.createdAt:
        comparator = (a, b) => sortAscending
            ? a.createdAt.compareTo(b.createdAt)
            : b.createdAt.compareTo(a.createdAt);
        break;
      case NoteSortField.title:
        comparator = (a, b) => sortAscending
            ? a.displayTitle.compareTo(b.displayTitle)
            : b.displayTitle.compareTo(a.displayTitle);
        break;
      case NoteSortField.updatedAt:
        comparator = (a, b) => sortAscending
            ? a.updatedAt.compareTo(b.updatedAt)
            : b.updatedAt.compareTo(a.updatedAt);
        break;
    }

    pinned.sort(comparator);
    unpinned.sort(comparator);

    return [...pinned, ...unpinned];
  });
});

/// 笔记列表快捷操作 Controller
class NoteListController {
  final Ref _ref;

  NoteListController(this._ref);

  /// 切换置顶状态
  Future<void> togglePin(Note note) async {
    await _ref.read(noteRepositoryProvider).togglePinNote(note.id, !note.isPinned);
  }

  /// 移入废纸篓 (软删除)
  Future<void> softDelete(Note note) async {
    await _ref.read(noteRepositoryProvider).softDeleteNote(note.id);
  }

  /// 切换归档状态
  Future<void> toggleArchive(Note note) async {
    await _ref.read(noteRepositoryProvider).toggleArchiveNote(note.id, !note.isArchived);
  }

  /// 更改笔记主题色
  Future<void> changeColor(Note note, String colorId) async {
    await _ref.read(noteRepositoryProvider).updateNoteColor(note.id, colorId);
  }
}

final noteListControllerProvider = Provider<NoteListController>((ref) => NoteListController(ref));
