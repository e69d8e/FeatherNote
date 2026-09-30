import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/widgets/feather_empty_state.dart';
import '../../../../core/widgets/feather_search_bar.dart';
import '../../domain/models/note.dart';
import '../controllers/note_search_controller.dart';
import '../widgets/note_card.dart';

/// 笔记即时搜索页面
class NoteSearchScreen extends ConsumerStatefulWidget {
  const NoteSearchScreen({super.key});

  @override
  ConsumerState<NoteSearchScreen> createState() => _NoteSearchScreenState();
}

class _NoteSearchScreenState extends ConsumerState<NoteSearchScreen> {
  late final TextEditingController _searchController;
  final Debouncer _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 250));

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: FeatherSearchBar(
            controller: _searchController,
            autofocus: true,
            hintText: '搜索笔记标题、内容或标签...',
            onChanged: (val) {
              _searchDebouncer.run(() {
                if (mounted) {
                  ref.read(searchQueryProvider.notifier).state = val;
                }
              });
            },
            onClear: () {
              _searchDebouncer.cancel();
              ref.read(searchQueryProvider.notifier).state = '';
            },
          ),
        ),
      ),
      body: query.trim().isEmpty
          ? const FeatherEmptyState(
              icon: Icons.search_rounded,
              title: '输入关键词即刻搜索',
              subtitle: '支持搜索笔记标题、正文文本以及标签',
            )
          : _buildResults(context, searchResultsAsync),
    );
  }

  /// 结果展示：切换关键词加载新结果期间保留上一批结果，
  /// 避免每次输入都闪现空白加载圈 (stale-while-revalidate)
  Widget _buildResults(BuildContext context, AsyncValue<List<Note>> resultsAsync) {
    final notes = resultsAsync.valueOrNull;

    if (notes == null) {
      if (resultsAsync.hasError) {
        return Center(child: Text('搜索出错: ${resultsAsync.error}'));
      }
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }

    if (notes.isEmpty) {
      if (resultsAsync.hasError) {
        return Center(child: Text('搜索出错: ${resultsAsync.error}'));
      }
      if (!resultsAsync.isLoading) {
        return const FeatherEmptyState(
          icon: Icons.find_in_page_outlined,
          title: '未找到匹配的笔记',
          subtitle: '尝试换一个关键词或检查拼写',
        );
      }
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }

    return MasonryGridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return NoteCard(
          key: ValueKey(note.id),
          note: note,
          onTap: () => context.push('/edit/${note.id}'),
        );
      },
    );
  }
}
