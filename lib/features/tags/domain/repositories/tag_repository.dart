import '../models/tag.dart';

/// 标签仓储接口
abstract class TagRepository {
  /// 监听所有标签
  Stream<List<Tag>> watchAllTags();

  /// 获取全部标签（用于备份导出）
  Future<List<Tag>> getAllTags();

  /// 导入标签定义与颜色（按名称合并，保留现有标签）
  Future<void> importTags(List<Tag> tags);

  /// 添加标签
  Future<void> addTag(String name, {String? color});

  /// 删除标签
  Future<void> deleteTag(String id);
}
