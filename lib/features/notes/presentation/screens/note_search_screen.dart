import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/debouncer.dart';
import '../../../../core/widgets/feather_content_width.dart';
import '../../../../core/widgets/feather_empty_state.dart';
import '../../../../core/widgets/feather_search_bar.dart';
import '../../domain/models/note.dart';
import '../controllers/note_search_controller.dart';
import '../widgets/note_grid.dart';

/// 笔记即时搜索页面
class NoteSearchScreen extends ConsumerStatefulWidget {
  const NoteSearchScreen({super.key});

  @override
  ConsumerState<NoteSearchScreen> createState() => _NoteSearchScreenState();
}

class _NoteSearchScreenState extends ConsumerState<NoteSearchScreen> {
  late final TextEditingController _searchController;
  final Debouncer _searchDebouncer = Debouncer(
    delay: const Duration(milliseconds: 250),
  );

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
          child: FeatherContentWidth(
            maxWidth: 760,
            alignment: Alignment.center,
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
  Widget _buildResults(
    BuildContext context,
    AsyncValue<List<Note>> resultsAsync,
  ) {
    final notes = resultsAsync.valueOrNull;

    if (notes == null) {
      if (resultsAsync.hasError) {
        return Center(child: Text('搜索出错: ${resultsAsync.error}'));
      }
      return const _SearchSkeleton();
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

    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            '找到 ${notes.length} 条笔记',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: NoteGrid(
            notes: notes,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            onTap: (note) => context.push('/edit/${note.id}'),
          ),
        ),
      ],
    );
  }
}

/// 首次搜索时的轻量骨架屏，避免空白等待。
class _SearchSkeleton extends StatelessWidget {
  const _SearchSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = math.min(constraints.maxWidth, 1200.0);
        final columns = NoteGrid.columnsForWidth(contentWidth);
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.65,
              ),
              itemCount: columns * 2,
              itemBuilder: (context, index) => Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.55,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBar(width: 150, height: 16, color: theme),
                    const SizedBox(height: 14),
                    _SkeletonBar(
                      width: double.infinity,
                      height: 10,
                      color: theme,
                    ),
                    const SizedBox(height: 8),
                    _SkeletonBar(
                      width: double.infinity,
                      height: 10,
                      color: theme,
                    ),
                    const SizedBox(height: 8),
                    _SkeletonBar(width: 120, height: 10, color: theme),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final ThemeData color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.colorScheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
