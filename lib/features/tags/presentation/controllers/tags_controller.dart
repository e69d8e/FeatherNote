import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/database_provider.dart';
import '../../domain/models/tag.dart';

/// 当前选中的标签过滤器 (null 表示全部笔记)
final selectedTagFilterProvider = StateProvider<String?>((ref) => null);

/// 标签列表响应式 StreamProvider
final tagsStreamProvider = StreamProvider<List<Tag>>((ref) {
  final repo = ref.watch(tagRepositoryProvider);
  return repo.watchAllTags();
});

/// 标签管理 Controller
class TagsController {
  final Ref _ref;

  TagsController(this._ref);

  Future<void> addTag(String name, {String? color}) async {
    await _ref.read(tagRepositoryProvider).addTag(name, color: color);
  }

  /// 删除标签 (标签表以标签名作为主键，按名删除并同步清理筛选状态)
  Future<void> deleteTag(String tagName) async {
    await _ref.read(tagRepositoryProvider).deleteTag(tagName);
    if (_ref.read(selectedTagFilterProvider) == tagName) {
      _ref.read(selectedTagFilterProvider.notifier).state = null;
    }
  }

  void selectTag(String? tagName) {
    _ref.read(selectedTagFilterProvider.notifier).state = tagName;
  }
}

final tagsControllerProvider = Provider<TagsController>((ref) => TagsController(ref));
