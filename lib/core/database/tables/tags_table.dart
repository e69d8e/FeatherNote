import 'package:drift/drift.dart';

/// 标签数据库表
@DataClassName('TagEntry')
class TagsTable extends Table {
  @override
  String get tableName => 'tags';

  // 标签 ID
  TextColumn get id => text()();

  // 标签名称 (唯一)
  TextColumn get name => text().unique()();

  // 标签预设强调色
  TextColumn get color => text().nullable()();

  // 创建时间
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
