import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// 羽记轻量级空状态组件
class FeatherEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const FeatherEmptyState({
    super.key,
    this.icon = Icons.edit_note_rounded,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 38,
                color: colorScheme.primary.withValues(alpha: 0.7),
              ),
            )
                // 链式效果按顺序播放：两轮上下浮动 (共 4 秒) 后自然结束，
                // 不用 repeat(reverse) —— 它永远不会发出终止状态，会无限占用动画帧
                .animate()
                .moveY(begin: 0, end: -6, duration: 1.seconds, curve: Curves.easeInOut)
                .moveY(begin: -6, end: 0, duration: 1.seconds, curve: Curves.easeInOut)
                .moveY(begin: 0, end: -6, duration: 1.seconds, curve: Curves.easeInOut)
                .moveY(begin: -6, end: 0, duration: 1.seconds, curve: Curves.easeInOut),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
