import 'package:drift/drift.dart' as drift;
import '../../../../core/database/app_database.dart';

/// 笔记实体领域模型
class Note {
  final String id;
  final String title;
  final String content;
  final String colorId;
  final bool isPinned;
  final bool isArchived;
  final bool isDeleted;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Note({
    required this.id,
    this.title = '',
    this.content = '',
    this.colorId = 'default',
    this.isPinned = false,
    this.isArchived = false,
    this.isDeleted = false,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  /// 是否是空笔记 (标题和内容均为空)
  bool get isEmpty => title.trim().isEmpty && content.trim().isEmpty;

  static final RegExp _headingRegex = RegExp(r'#+\s*');

  /// 显示标题 (若无标题则从内容前15字作为标题)
  String get displayTitle {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isNotEmpty) {
      return trimmedTitle;
    }
    final trimmedContent = content.trim();
    if (trimmedContent.isNotEmpty) {
      final newlineIdx = trimmedContent.indexOf('\n');
      final firstLine = (newlineIdx == -1 ? trimmedContent : trimmedContent.substring(0, newlineIdx)).trim();
      final clean = firstLine.replaceAll(_headingRegex, '');
      return clean.length > 20 ? '${clean.substring(0, 20)}...' : clean;
    }
    return '无标题笔记';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Note) return false;
    if (other.id != id ||
        other.title != title ||
        other.content != content ||
        other.colorId != colorId ||
        other.isPinned != isPinned ||
        other.isArchived != isArchived ||
        other.isDeleted != isDeleted ||
        other.createdAt != createdAt ||
        other.updatedAt != updatedAt ||
        other.deletedAt != deletedAt ||
        other.tags.length != tags.length) {
      return false;
    }
    for (int i = 0; i < tags.length; i++) {
      if (tags[i] != other.tags[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        content,
        colorId,
        isPinned,
        isArchived,
        isDeleted,
        createdAt,
        updatedAt,
        deletedAt,
        Object.hashAll(tags),
      );

  /// 复制并更新属性
  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? colorId,
    bool? isPinned,
    bool? isArchived,
    bool? isDeleted,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      colorId: colorId ?? this.colorId,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  /// 从 Drift 数据库实体构造
  factory Note.fromEntry(NoteEntry entry) {
    final tagList = entry.tags.isNotEmpty
        ? entry.tags.split(',').where((t) => t.trim().isNotEmpty).map((t) => t.trim()).toList()
        : <String>[];

    return Note(
      id: entry.id,
      title: entry.title,
      content: entry.content,
      colorId: entry.colorId,
      isPinned: entry.isPinned,
      isArchived: entry.isArchived,
      isDeleted: entry.isDeleted,
      tags: tagList,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      deletedAt: entry.deletedAt,
    );
  }

  /// 转换为 Drift 伴随对象
  NotesTableCompanion toCompanion() {
    return NotesTableCompanion(
      id: drift.Value(id),
      title: drift.Value(title),
      content: drift.Value(content),
      colorId: drift.Value(colorId),
      isPinned: drift.Value(isPinned),
      isArchived: drift.Value(isArchived),
      isDeleted: drift.Value(isDeleted),
      tags: drift.Value(tags.join(',')),
      createdAt: drift.Value(createdAt),
      updatedAt: drift.Value(updatedAt),
      deletedAt: drift.Value(deletedAt),
    );
  }

  /// 序列化为 Map (用于备份与 JSON 导出)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'colorId': colorId,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'isDeleted': isDeleted,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  /// 从 Map 反序列化
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      colorId: json['colorId'] as String? ?? 'default',
      isPinned: json['isPinned'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt'] as String) : null,
    );
  }
}
