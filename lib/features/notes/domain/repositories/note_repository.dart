import '../models/note.dart';

/// 笔记仓储接口
abstract class NoteRepository {
  /// 监听活跃笔记列表
  Stream<List<Note>> watchActiveNotes({String? tagFilter});

  /// 监听已归档笔记
  Stream<List<Note>> watchArchivedNotes();

  /// 监听废纸篓笔记
  Stream<List<Note>> watchDeletedNotes();

  /// 搜索笔记
  Stream<List<Note>> searchNotes(String query);

  /// 根据 ID 获取单个笔记
  Future<Note?> getNoteById(String id);

  /// 监听单个笔记
  Stream<Note?> watchNoteById(String id);

  /// 保存/更新笔记
  Future<void> saveNote(Note note);

  /// 软删除笔记 (移入废纸篓)
  Future<void> softDeleteNote(String id);

  /// 从废纸篓恢复笔记
  Future<void> restoreNote(String id);

  /// 切换归档状态
  Future<void> toggleArchiveNote(String id, bool isArchived);

  /// 切换置顶状态
  Future<void> togglePinNote(String id, bool isPinned);

  /// 更改笔记卡片主题色
  Future<void> updateNoteColor(String id, String colorId);

  /// 永久删除笔记
  Future<void> permanentlyDeleteNote(String id);

  /// 清空废纸篓
  Future<void> emptyTrash();

  /// 获取全部笔记 (用于备份导出)
  Future<List<Note>> getAllNotes();

  /// 批量获取指定 ID 的笔记 (单次查询)
  Future<List<Note>> getNotesByIds(List<String> ids);

  /// 批量保存笔记 (单次事务写入)
  Future<void> saveNotes(List<Note> notes);

  /// 批量导入笔记
  Future<void> importNotes(List<Note> notes);
}
