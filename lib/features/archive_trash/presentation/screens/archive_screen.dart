import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/widgets/feather_empty_state.dart';
import '../../../notes/domain/models/note.dart';
import '../controllers/archive_controller.dart';
import '../../../notes/presentation/widgets/note_card.dart';

/// 归档箱页面
class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedAsync = ref.watch(archivedNotesStreamProvider);
    final archiveCtrl = ref.read(archiveControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('归档箱', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: archivedAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return const FeatherEmptyState(
              icon: Icons.archive_outlined,
              title: '归档箱为空',
              subtitle: '已完成或暂时不用的笔记可以归档收纳',
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
                onTap: () => _showArchiveOptions(context, ref, note, archiveCtrl),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        error: (err, _) => Center(child: Text('加载归档失败: $err')),
      ),
    );
  }

  void _showArchiveOptions(
    BuildContext context,
    WidgetRef ref,
    Note note,
    ArchiveController archiveCtrl,
  ) {
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
              leading: const Icon(Icons.edit_outlined),
              title: const Text('查看与编辑'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/edit/${note.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.unarchive_outlined),
              title: const Text('取消归档 (放回主笔记列表)'),
              onTap: () {
                Navigator.pop(ctx);
                runWithFeedback(
                  context,
                  () => archiveCtrl.unarchive(note),
                  successMessage: '已恢复到全部笔记',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: const Text('移入废纸篓', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(ctx);
                runWithFeedback(
                  context,
                  () => archiveCtrl.moveToTrash(note),
                  successMessage: '已移入废纸篓，可在废纸篓中恢复',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
