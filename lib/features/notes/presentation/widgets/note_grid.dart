import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../domain/models/note.dart';
import 'note_card.dart';

enum NoteGridLayout { staggered, grid, list }

/// 响应式笔记网格：按可用宽度自动切换列数，并将桌面内容限制在最大宽度内。
class NoteGrid extends StatelessWidget {
  final List<Note> notes;
  final NoteGridLayout layout;
  final ValueChanged<Note> onTap;
  final ValueChanged<Note>? onMoreTap;
  final ValueChanged<Note>? onLongPress;
  final bool showActions;
  final EdgeInsets padding;
  final double maxWidth;

  const NoteGrid({
    super.key,
    required this.notes,
    required this.onTap,
    this.layout = NoteGridLayout.staggered,
    this.onMoreTap,
    this.onLongPress,
    this.showActions = true,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 80),
    this.maxWidth = 1200,
  });

  static int columnsForWidth(double width) {
    if (width >= 1180) return 4;
    if (width >= 820) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final contentMaxWidth = layout == NoteGridLayout.list
        ? math.min(maxWidth, 760.0)
        : maxWidth;

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = math.min(constraints.maxWidth, contentMaxWidth);
        final columns = columnsForWidth(contentWidth);

        final scrollView = switch (layout) {
          NoteGridLayout.staggered => MasonryGridView.count(
            padding: padding,
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            itemCount: notes.length,
            itemBuilder: (context, index) => _buildCard(context, notes[index]),
          ),
          NoteGridLayout.grid => GridView.builder(
            padding: padding,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: notes.length,
            itemBuilder: (context, index) => _buildCard(context, notes[index]),
          ),
          NoteGridLayout.list => ListView.separated(
            padding: padding,
            itemCount: notes.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _buildCard(context, notes[index]),
          ),
        };

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: scrollView,
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, Note note) {
    return NoteCard(
      key: ValueKey(note.id),
      note: note,
      showActions: showActions,
      onTap: () => onTap(note),
      onMoreTap: onMoreTap == null ? null : () => onMoreTap!(note),
      onLongPress: onLongPress == null ? null : () => onLongPress!(note),
    );
  }
}
