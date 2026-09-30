import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feathernote/core/widgets/feather_empty_state.dart';

void main() {
  testWidgets('FeatherEmptyState 动画两轮后停止调度帧', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: FeatherEmptyState(icon: Icons.edit, title: '空')),
    ));

    // 动画时长 2s：一轮 = 上 2s + 下 2s？moveY duration 2s → 单程 2s
    // 两轮 ≈ 8s，多泵一点确认帧不再被调度
    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(tester.binding.hasScheduledFrame, isFalse,
        reason: '空状态动画应在约 8 秒后停止占用帧');
  });
}
