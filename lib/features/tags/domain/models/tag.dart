import '../../../../core/database/app_database.dart';

/// 标签实体领域模型
class Tag {
  final String id;
  final String name;
  final String? color;
  final DateTime createdAt;

  const Tag({
    required this.id,
    required this.name,
    this.color,
    required this.createdAt,
  });

  factory Tag.fromEntry(TagEntry entry) {
    return Tag(
      id: entry.id,
      name: entry.name,
      color: entry.color,
      createdAt: entry.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tag &&
        other.id == id &&
        other.name == name &&
        other.color == color &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, name, color, createdAt);
}
