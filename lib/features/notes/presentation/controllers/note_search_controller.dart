import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/database_provider.dart';
import '../../domain/models/note.dart';

/// 搜索关键词 Provider
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// 搜索结果响应式 StreamProvider
final searchResultsProvider = StreamProvider.autoDispose<List<Note>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final repo = ref.watch(noteRepositoryProvider);

  if (query.trim().isEmpty) {
    return Stream.value([]);
  }

  return repo.searchNotes(query.trim());
});
