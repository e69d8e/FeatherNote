import 'package:flutter/material.dart';

/// 将页面主体限制在可读宽度内并水平居中。
///
/// 宽屏（桌面 / 平板横屏）下避免内容铺满整个窗口；窄屏时保持原宽度。
class FeatherContentWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Alignment alignment;

  const FeatherContentWidth({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
