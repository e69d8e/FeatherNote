/// 待办清单项实体模型
class TodoItem {
  final String id;
  final String noteId;
  final String noteTitle;
  final int indexInNote;
  final String text;
  final bool isCompleted;
  final String noteColorId;
  final DateTime updatedAt;

  const TodoItem({
    required this.id,
    required this.noteId,
    required this.noteTitle,
    required this.indexInNote,
    required this.text,
    required this.isCompleted,
    required this.noteColorId,
    required this.updatedAt,
  });

  TodoItem copyWith({
    String? id,
    String? noteId,
    String? noteTitle,
    int? indexInNote,
    String? text,
    bool? isCompleted,
    String? noteColorId,
    DateTime? updatedAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      noteTitle: noteTitle ?? this.noteTitle,
      indexInNote: indexInNote ?? this.indexInNote,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
      noteColorId: noteColorId ?? this.noteColorId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TodoItem &&
        other.id == id &&
        other.noteId == noteId &&
        other.noteTitle == noteTitle &&
        other.indexInNote == indexInNote &&
        other.text == text &&
        other.isCompleted == isCompleted &&
        other.noteColorId == noteColorId &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        noteId,
        noteTitle,
        indexInNote,
        text,
        isCompleted,
        noteColorId,
        updatedAt,
      );
}
