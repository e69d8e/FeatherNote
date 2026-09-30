import '../models/tag.dart';

/// 标签仓储接口
abstract class TagRepository {
  /// 监听所有标签
  Stream<List<Tag>> watchAllTags();

  /// 添加标签
  Future<void> addTag(String name, {String? color});

  /// 删除标签
  Future<void> deleteTag(String id);
}
