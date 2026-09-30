import 'package:drift/drift.dart';

/// 笔记数据库表
@DataClassName('NoteEntry')
@TableIndex(name: 'notes_active_idx', columns: {#isDeleted, #isArchived, #isPinned, #updatedAt})
@TableIndex(name: 'notes_deleted_idx', columns: {#isDeleted, #deletedAt})
class NotesTable extends Table {
  @override
  String get tableName => 'notes';

  // 唯一 ID (UUID)
  TextColumn get id => text()();

  // 标题
  TextColumn get title => text().withDefault(const Constant(''))();

  // 正文内容 (支持 Markdown)
  TextColumn get content => text().withDefault(const Constant(''))();

  // 预设主题色 ID (如 default, sakura, sage, lavender, amber, sky)
  TextColumn get colorId => text().withDefault(const Constant('default'))();

  // 是否置顶
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  // 是否归档
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  // 是否软删除 (移入废纸篓)
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  // 关联标签列表 (以逗号分隔存储，如 "工作,学习")
  TextColumn get tags => text().withDefault(const Constant(''))();

  // 创建时间
  DateTimeColumn get createdAt => dateTime()();

  // 最后修改时间
  DateTimeColumn get updatedAt => dateTime()();

  // 移入废纸篓时间
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
