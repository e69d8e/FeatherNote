import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/widgets/feather_empty_state.dart';
import '../../domain/models/todo_item.dart';
import '../controllers/todo_controller.dart';

/// 待办清单专区视图
class TodoListView extends ConsumerStatefulWidget {
  const TodoListView({super.key});

  @override
  ConsumerState<TodoListView> createState() => _TodoListViewState();
}

class _TodoListViewState extends ConsumerState<TodoListView> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _showCompleted = true;

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _submitTodo() {
    final text = _inputController.text.trim();
    if (text.isNotEmpty) {
      runWithFeedback(
        context,
        () => ref.read(todoControllerProvider).addTodo(text),
        failureTitle: '添加待办失败',
      );
      _inputController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final allTodos = ref.watch(allTodosProvider);
    final pendingTodos = ref.watch(pendingTodosProvider);
    final completedTodos = ref.watch(completedTodosProvider);

    final totalCount = allTodos.length;
    final completedCount = completedTodos.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 快捷添加待办输入框
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surfaceContainerHighest : colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          focusNode: _inputFocusNode,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submitTodo(),
                          style: theme.textTheme.bodyMedium,
                          decoration: const InputDecoration(
                            hintText: '添加待办事项，按回车保存...',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                        visualDensity: VisualDensity.compact,
                        color: colorScheme.primary,
                        onPressed: _submitTodo,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 待办完成进度概览卡片
                if (totalCount > 0)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                            : [const Color(0xFFE0F2FE), const Color(0xFFF0FDF4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFBAE6FD),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.task_alt_rounded,
                                  size: 18,
                                  color: isDark ? Colors.lightBlueAccent : const Color(0xFF0284C7),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '今日待办专注',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '$completedCount / $totalCount 项 · ${(progress * 100).toInt()}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.lightBlueAccent : const Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.8),
                            color: progress >= 1.0
                                ? Colors.tealAccent.shade400
                                : (isDark ? Colors.lightBlueAccent : const Color(0xFF0284C7)),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 空状态展示
                if (totalCount == 0)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: FeatherEmptyState(
                      icon: Icons.checklist_rtl_rounded,
                      title: '暂无待办事项',
                      subtitle: '在上方快速添加，或在任何笔记中插入 - [ ] 待办列表',
                    ),
                  ),

                // 进行中待办标头
                if (pendingTodos.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      '待完成 (${pendingTodos.length})',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // 进行中待办项列表 (SliverList 虚拟化惰性加载)
        if (pendingTodos.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.builder(
              itemCount: pendingTodos.length,
              itemBuilder: (context, index) => _buildTodoCard(context, pendingTodos[index], isDark),
            ),
          ),

        // 已完成待办项列表折叠标头
        if (completedTodos.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            sliver: SliverToBoxAdapter(
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _showCompleted = !_showCompleted),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _showCompleted ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '已完成 (${completedTodos.length})',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          final count = completedTodos.length;
                          runWithFeedback(
                            context,
                            () => ref.read(todoControllerProvider).clearAllCompleted(),
                            successMessage: '已清空 $count 条已完成待办',
                            failureTitle: '清空失败',
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          '清空已完成',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // 已完成待办项列表 (SliverList 虚拟化惰性加载)
        if (completedTodos.isNotEmpty && _showCompleted)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.builder(
              itemCount: completedTodos.length,
              itemBuilder: (context, index) => _buildTodoCard(context, completedTodos[index], isDark),
            ),
          ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  /// 构建单条待办卡片
  Widget _buildTodoCard(BuildContext context, TodoItem item, bool isDark) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colorPreset = AppColors.getNoteColor(item.noteColorId, isDark: isDark);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        runWithFeedback(
          context,
          () => ref.read(todoControllerProvider).deleteTodo(item),
          failureTitle: '删除待办失败',
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              runWithFeedback(
                context,
                () => ref.read(todoControllerProvider).toggleTodo(item),
                failureTitle: '更新待办失败',
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // 复选框图标
                  IconButton(
                    icon: Icon(
                      item.isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: item.isCompleted
                          ? Colors.teal
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      size: 22,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      runWithFeedback(
                        context,
                        () => ref.read(todoControllerProvider).toggleTodo(item),
                        failureTitle: '更新待办失败',
                      );
                    },
                  ),
                  const SizedBox(width: 6),

                  // 待办文本
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.text,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                            color: item.isCompleted
                                ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                                : theme.colorScheme.onSurface,
                            fontWeight: item.isCompleted ? FontWeight.w400 : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // 所属笔记小标
                        GestureDetector(
                          onTap: () => context.push('/edit/${item.noteId}'),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.article_outlined,
                                size: 11,
                                color: colorPreset.accentColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                item.noteTitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10.5,
                                  color: colorPreset.accentColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 删除小按钮
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: '删除待办',
                    onPressed: () {
                      runWithFeedback(
                        context,
                        () => ref.read(todoControllerProvider).deleteTodo(item),
                        failureTitle: '删除待办失败',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
