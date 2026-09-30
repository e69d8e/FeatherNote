import 'dart:async';
import 'package:flutter/foundation.dart';

/// 防抖执行器 (用于输入实时自动保存)
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  /// 触发防抖执行
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// 立即触发并取消等待
  void flush(VoidCallback action) {
    _timer?.cancel();
    _timer = null;
    action();
  }

  /// 取消当前定时器
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// 销毁
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
