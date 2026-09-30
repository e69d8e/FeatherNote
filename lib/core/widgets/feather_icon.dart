import 'package:flutter/material.dart';

/// 羽记专属轻羽徽标组件
class FeatherIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const FeatherIcon({
    super.key,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = color ?? theme.colorScheme.primary;

    return Icon(
      Icons.flutter_dash, // 或者使用 feather 图标
      size: size,
      color: iconColor,
    );
  }
}
