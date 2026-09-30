import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/utils/debouncer.dart';
import '../../domain/models/note.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';

/// 笔记编辑界面状态
class NoteEditState {
  final Note note;
  final bool isNew;
  final bool isLoading;
  final bool isPreviewMode;
  final bool isSaving;
  final bool hasChanges;

  /// 上一次自动保存是否失败 (内容仍在，等待下次编辑或手动退出时重试)
  final bool saveFailed;

  const NoteEditState({
    required this.note,
    this.isNew = false,
    this.isLoading = false,
    this.isPreviewMode = false,
    this.isSaving = false,
    this.hasChanges = false,
    this.saveFailed = false,
  });

  NoteEditState copyWith({
    Note? note,
    bool? isNew,
    bool? isLoading,
    bool? isPreviewMode,
    bool? isSaving,
    bool? hasChanges,
    bool? saveFailed,
  }) {
    return NoteEditState(
      note: note ?? this.note,
      isNew: isNew ?? this.isNew,
      isLoading: isLoading ?? this.isLoading,
      isPreviewMode: isPreviewMode ?? this.isPreviewMode,
      isSaving: isSaving ?? this.isSaving,
      hasChanges: hasChanges ?? this.hasChanges,
      saveFailed: saveFailed ?? this.saveFailed,
    );
  }
}

/// 笔记编辑控制器 (支持自动保存与防抖)
class NoteEditNotifier extends StateNotifier<NoteEditState> {
  final Ref _ref;
  final Debouncer _autoSaveDebouncer = Debouncer(delay: const Duration(milliseconds: 600));

  NoteEditNotifier(
    this._ref,
    Note initialNote, {
    bool isNew = false,
    bool isLoading = false,
    bool initialPreviewMode = false,
  }) : super(NoteEditState(
          note: initialNote,
          isNew: isNew,
          isLoading: isLoading,
          isPreviewMode: initialPreviewMode,
        ));

  @override
  void dispose() {
    _autoSaveDebouncer.dispose();
    super.dispose();
  }

  /// 更改标题
  void setTitle(String newTitle) {
    if (state.note.title == newTitle) return;
    final updated = state.note.copyWith(
      title: newTitle,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(note: updated, hasChanges: true);
    _triggerAutoSave();
  }

  /// 更改正文
  void setContent(String newContent) {
    if (state.note.content == newContent) return;
    final updated = state.note.copyWith(
      content: newContent,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(note: updated, hasChanges: true);
    _triggerAutoSave();
  }

  /// 更改笔记卡片主题色
  void setColor(String colorId) {
    final updated = state.note.copyWith(
      colorId: colorId,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(note: updated, hasChanges: true);
    saveImmediate();
  }

  /// 切换置顶
  void togglePin() {
    final updated = state.note.copyWith(
      isPinned: !state.note.isPinned,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(note: updated, hasChanges: true);
    saveImmediate();
  }

  /// 切换归档
  void toggleArchive() {
    final updated = state.note.copyWith(
      isArchived: !state.note.isArchived,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(note: updated, hasChanges: true);
    saveImmediate();
  }

  /// 添加标签
  void addTag(String tag) {
    final clean = tag.trim();
    if (clean.isEmpty || state.note.tags.contains(clean)) return;

    final newTags = [...state.note.tags, clean];
    final updated = state.note.copyWith(
      tags: newTags,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(note: updated, hasChanges: true);
    saveImmediate();
  }

  /// 移除标签
  void removeTag(String tag) {
    final newTags = state.note.tags.where((t) => t != tag).toList();
    final updated = state.note.copyWith(
      tags: newTags,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(note: updated, hasChanges: true);
    saveImmediate();
  }

  /// 切换 Markdown 实时预览 / 编辑模式
  void togglePreviewMode() {
    state = state.copyWith(isPreviewMode: !state.isPreviewMode);
  }

  /// 触发防抖自动保存
  void _triggerAutoSave() {
    _autoSaveDebouncer.run(() {
      saveImmediate();
    });
  }

  /// 立即持久化保存到 Drift 数据库
  Future<void> saveImmediate() async {
    // 若已被删除，或者为空白新笔记且从未输入内容，则不保存
    if (state.note.isDeleted || (state.note.isEmpty && state.isNew)) return;

    final noteToSave = state.note;
    state = state.copyWith(isSaving: true, saveFailed: false);
    try {
      await _ref.read(noteRepositoryProvider).saveNote(noteToSave);
      if (mounted) {
        state = state.copyWith(isSaving: false, hasChanges: false, isNew: false);
      }
    } catch (e) {
      // 保存失败时不丢弃内容：保留 hasChanges 并标记失败，状态栏会提示用户，
      // 后续编辑或退出时会自动再次尝试保存，isSaving 也不会卡死
      if (mounted) {
        state = state.copyWith(isSaving: false, hasChanges: true, saveFailed: true);
      }
    }
  }

  /// 从外部加载已有笔记
  void loadNote(Note loadedNote) {
    state = state.copyWith(note: loadedNote, isNew: false, isLoading: false);
  }

  /// 软删除该笔记 (移入废纸篓)
  Future<void> deleteNote() async {
    _autoSaveDebouncer.cancel();
    final noteId = state.note.id;
    state = state.copyWith(
      note: state.note.copyWith(
        isDeleted: true,
        deletedAt: DateTime.now(),
      ),
    );
    await _ref.read(noteRepositoryProvider).softDeleteNote(noteId);
  }
}

/// 笔记编辑 Provider 参数族 (依据 noteId 初始化或新建)
final noteEditProvider = StateNotifierProvider.autoDispose.family<NoteEditNotifier, NoteEditState, String?>(
  (ref, noteId) {
    // 只监听默认配色字段：其它设置变化不会导致编辑中的笔记被重建 (丢输入)
    final defaultColor = ref.watch(settingsProvider.select((s) => s.defaultColorId));

    if (noteId == null || noteId == 'new') {
      final now = DateTime.now();
      final newNote = Note(
        id: const Uuid().v4(),
        title: '',
        content: '',
        colorId: defaultColor,
        createdAt: now,
        updatedAt: now,
      );
      return NoteEditNotifier(ref, newNote, isNew: true, isLoading: false, initialPreviewMode: false);
    }

    // 已有笔记：默认进入「预览模式」
    final now = DateTime.now();
    final placeholder = Note(
      id: noteId,
      createdAt: now,
      updatedAt: now,
    );

    final notifier = NoteEditNotifier(
      ref,
      placeholder,
      isNew: false,
      isLoading: true,
      initialPreviewMode: true,
    );

    // 异步从数据库加载该笔记真实内容
    ref.read(noteRepositoryProvider).getNoteById(noteId).then((loadedNote) {
      if (loadedNote != null && notifier.mounted) {
        notifier.loadNote(loadedNote);
      }
    });

    return notifier;
  },
);
