import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/widgets/feather_empty_state.dart';
import '../../../notes/domain/models/note.dart';
import '../controllers/trash_controller.dart';
import '../../../notes/presentation/widgets/note_card.dart';

/// 废纸篓页面 (支持恢复与永久删除)
class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashAsync = ref.watch(trashNotesStreamProvider);
    final trashCtrl = ref.read(trashControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('废纸篓', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          trashAsync.maybeWhen(
            data: (notes) => notes.isNotEmpty
                ? TextButton.icon(
                    onPressed: () => _confirmEmptyTrash(context, trashCtrl),
                    icon: const Icon(Icons.delete_forever_rounded, size: 18, color: Colors.redAccent),
                    label: const Text('清空废纸篓', style: TextStyle(color: Colors.redAccent)),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: trashAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return const FeatherEmptyState(
              icon: Icons.delete_outline_rounded,
              title: '废纸篓是空的',
              subtitle: '删除的笔记会出现在这里，可随时恢复',
            );
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
                showActions: false,
                onTap: () => _showTrashItemActions(context, note, trashCtrl),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        error: (err, _) => Center(child: Text('加载废纸篓失败: $err')),
      ),
    );
  }

  void _showTrashItemActions(BuildContext context, Note note, TrashController trashCtrl) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restore_from_trash_rounded, color: Colors.green),
              title: const Text('恢复笔记到主列表'),
              onTap: () {
                Navigator.pop(ctx);
                runWithFeedback(
                  context,
                  () => trashCtrl.restoreNote(note),
                  successMessage: '已成功恢复笔记',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
              title: const Text('永久删除', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmPermanentDelete(context, note, trashCtrl);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 单条笔记永久删除前的二次确认
  void _confirmPermanentDelete(BuildContext context, Note note, TrashController trashCtrl) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('永久删除？'),
        content: Text('「${note.displayTitle}」将被永久删除，此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(dlgCtx);
              runWithFeedback(
                context,
                () => trashCtrl.permanentlyDelete(note),
                successMessage: '已永久删除',
                failureTitle: '删除失败',
              );
            },
            child: const Text('永久删除'),
          ),
        ],
      ),
    );
  }

  void _confirmEmptyTrash(BuildContext context, TrashController trashCtrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空废纸篓？'),
        content: const Text('此操作将永久删除废纸篓中的所有笔记，不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              runWithFeedback(
                context,
                () => trashCtrl.emptyTrash(),
                successMessage: '废纸篓已清空',
                failureTitle: '清空失败',
              );
            },
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
  }
}
