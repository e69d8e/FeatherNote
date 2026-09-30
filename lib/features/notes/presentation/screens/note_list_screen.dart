import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/widgets/feather_dialog_text_field.dart';
import '../../../../core/widgets/feather_empty_state.dart';
import '../../../../core/widgets/feather_search_bar.dart';
import '../../../../core/widgets/feather_tag_chip.dart';
import '../../../settings/domain/models/app_settings.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../tags/domain/models/tag.dart';
import '../../../tags/presentation/controllers/tags_controller.dart';
import '../../../todos/presentation/controllers/todo_controller.dart';
import '../../../todos/presentation/widgets/todo_list_view.dart';
import '../../domain/models/note.dart';
import '../controllers/note_list_controller.dart';
import '../widgets/note_card.dart';

/// 笔记主列表与待办专区双 Tab 页面
class NoteListScreen extends ConsumerStatefulWidget {
  const NoteListScreen({super.key});

  @override
  ConsumerState<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends ConsumerState<NoteListScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.index != _currentTabIndex) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddTodoDialog(BuildContext context, WidgetRef ref) {
    var text = '';
    void submit(BuildContext dlgCtx) {
      final clean = text.trim();
      if (clean.isEmpty) return;
      Navigator.pop(dlgCtx);
      runWithFeedback(
        context,
        () => ref.read(todoControllerProvider).addTodo(clean),
        failureTitle: '添加待办失败',
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_task_rounded, size: 20),
            SizedBox(width: 8),
            Text('新建待办事项'),
          ],
        ),
        content: FeatherDialogTextField(
          autofocus: true,
          hintText: '输入待办内容 (如: 明天下午两点开会)',
          onChanged: (val) => text = val,
          onSubmitted: (_) => submit(ctx),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => submit(ctx),
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final notesAsync = ref.watch(activeNotesStreamProvider);
    final tagsAsync = ref.watch(tagsStreamProvider);
    final selectedTag = ref.watch(selectedTagFilterProvider);
    final viewMode = ref.watch(settingsProvider.select((s) => s.viewMode));
    final todosCount = ref.watch(pendingTodosProvider.select((t) => t.length));

    final notesCount = notesAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      drawer: _buildDrawer(context, ref),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部搜索与布局切换栏
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Builder(
                        builder: (ctx) => IconButton(
                          icon: const Icon(Icons.menu_rounded),
                          tooltip: '打开侧边栏',
                          onPressed: () => Scaffold.of(ctx).openDrawer(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FeatherSearchBar(
                          readOnly: true,
                          onTap: () => context.push('/search'),
                        ),
                      ),
                      if (_currentTabIndex == 0) ...[
                        const SizedBox(width: 8),
                        // 切换视图布局按钮 (瀑布流 / 网格 / 列表)
                        IconButton(
                          icon: Icon(_getViewModeIcon(viewMode)),
                          tooltip: '切换布局',
                          onPressed: () {
                            final nextMode = switch (viewMode) {
                              NoteViewMode.staggered => NoteViewMode.grid,
                              NoteViewMode.grid => NoteViewMode.list,
                              NoteViewMode.list => NoteViewMode.staggered,
                            };
                            ref.read(settingsProvider.notifier).updateViewMode(nextMode);
                          },
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 顶部 Tab 切换胶囊 [ 📝 笔记 | ✅ 待办 ]
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.surfaceContainerHighest : colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      dividerHeight: 0,
                      labelColor: colorScheme.primary,
                      unselectedLabelColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      labelStyle: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                      unselectedLabelStyle: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 13.5,
                      ),
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.note_alt_outlined, size: 16),
                              const SizedBox(width: 6),
                              Text('笔记 ${notesCount > 0 ? "($notesCount)" : ""}'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.checklist_rtl_rounded, size: 16),
                              const SizedBox(width: 6),
                              Text('待办 ${todosCount > 0 ? "($todosCount)" : ""}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab 视图主体
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 0: 笔记列表
                  Column(
                    children: [
                      // 标签横滑过滤栏
                      _buildTagFilterBar(context, ref, tagsAsync, selectedTag),
                      const SizedBox(height: 6),
                      // 笔记卡片列表
                      Expanded(
                        child: notesAsync.when(
                          data: (notes) {
                            if (notes.isEmpty) {
                              return FeatherEmptyState(
                                icon: Icons.note_alt_outlined,
                                title: selectedTag != null
                                    ? '标签 #$selectedTag 下暂无笔记'
                                    : '轻触右下角羽毛笔，开始记录第一篇笔记',
                                subtitle: selectedTag != null ? '可点击“全部”查看全部笔记' : '随想、清单、灵感，轻盈如羽',
                                action: selectedTag != null
                                    ? OutlinedButton.icon(
                                        onPressed: () => ref.read(tagsControllerProvider).selectTag(null),
                                        icon: const Icon(Icons.clear_all_rounded, size: 18),
                                        label: const Text('清除标签筛选'),
                                      )
                                    : null,
                              );
                            }

                            return RefreshIndicator(
                              onRefresh: () async {
                                ref.invalidate(activeNotesStreamProvider);
                              },
                              child: _buildNotesLayout(context, ref, notes, viewMode),
                            );
                          },
                          // 下拉刷新时保留现有列表展示，避免整页闪现加载圈
                          skipLoadingOnRefresh: true,
                          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
                          error: (err, stack) => Center(
                            child: Text('加载笔记失败: $err', style: TextStyle(color: colorScheme.error)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Tab 1: 待办清单专区
                  const TodoListView(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton.extended(
              heroTag: 'fab_create_note',
              onPressed: () => context.push('/edit/new'),
              icon: const Icon(Icons.create_rounded, size: 20),
              label: const Text(
                '记一笔',
                style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
            )
          : FloatingActionButton.extended(
              heroTag: 'fab_add_todo',
              onPressed: () => _showAddTodoDialog(context, ref),
              icon: const Icon(Icons.add_task_rounded, size: 20),
              label: const Text(
                '加待办',
                style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
            ),
    );
  }

  /// 标签过滤横向滑块 (懒构建：标签数量多时也不会一次性全部铺开)
  Widget _buildTagFilterBar(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Tag>> tagsAsync,
    String? selectedTag,
  ) {
    final tags = tagsAsync.valueOrNull ?? const <Tag>[];

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tags.length + 2,
        itemBuilder: (context, index) {
          // 「全部」标签
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FeatherTagChip(
                label: '全部',
                isSelected: selectedTag == null,
                onTap: () => ref.read(tagsControllerProvider).selectTag(null),
              ),
            );
          }

          // 用户标签
          if (index <= tags.length) {
            final tag = tags[index - 1];
            final isSelected = selectedTag == tag.name;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FeatherTagChip(
                label: tag.name,
                isSelected: isSelected,
                onTap: () {
                  ref.read(tagsControllerProvider).selectTag(isSelected ? null : tag.name);
                },
              ),
            );
          }

          // 新增标签按钮
          return _buildAddTagButton(context, ref);
        },
      ),
    );
  }

  Widget _buildAddTagButton(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _showAddTagDialog(context, ref),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              '新建标签',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建笔记布局 (瀑布流 / 网格 / 列表)
  Widget _buildNotesLayout(
    BuildContext context,
    WidgetRef ref,
    List<Note> notes,
    NoteViewMode viewMode,
  ) {
    const padding = EdgeInsets.fromLTRB(16, 4, 16, 80);

    switch (viewMode) {
      case NoteViewMode.staggered:
        return MasonryGridView.count(
          padding: padding,
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

      case NoteViewMode.grid:
        return GridView.builder(
          padding: padding,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
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

      case NoteViewMode.list:
        return ListView.separated(
          padding: padding,
          itemCount: notes.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
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

  IconData _getViewModeIcon(NoteViewMode mode) {
    return switch (mode) {
      NoteViewMode.staggered => Icons.dashboard_customize_outlined,
      NoteViewMode.grid => Icons.grid_view_rounded,
      NoteViewMode.list => Icons.view_agenda_outlined,
    };
  }

  /// 弹出新建标签对话框
  void _showAddTagDialog(BuildContext context, WidgetRef ref) {
    var text = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建标签'),
        content: FeatherDialogTextField(
          autofocus: true,
          hintText: '输入标签名称 (如: 工作、想法、学习)',
          onChanged: (val) => text = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final clean = text.trim();
              if (clean.isEmpty) return;
              Navigator.pop(ctx);
              runWithFeedback(
                context,
                () => ref.read(tagsControllerProvider).addTag(clean),
                failureTitle: '创建标签失败',
              );
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  /// 构建侧边栏 Drawer
  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // 抽屉头部
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/icons/app_icon.png',
                      fit: BoxFit.cover,
                      // 44px 小图标无需解码 1024px 原图，限制解码尺寸省内存
                      cacheWidth: 192,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '羽记',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '行云流水，轻盈如羽',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),

            // 导航项
            ListTile(
              leading: const Icon(Icons.note_alt_outlined),
              title: const Text('全部笔记'),
              selected: true,
              onTap: () {
                Navigator.pop(context);
                ref.read(tagsControllerProvider).selectTag(null);
                _tabController.animateTo(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist_rtl_rounded),
              title: const Text('待办清单'),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('归档箱'),
              onTap: () {
                Navigator.pop(context);
                context.push('/archive');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('废纸篓'),
              onTap: () {
                Navigator.pop(context);
                context.push('/trash');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('设置与个性化'),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings');
              },
            ),

            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '羽记 FeatherNote v1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
