import 'package:flutter/material.dart';

/// 展示统一的轻量操作提示 (自动顶替上一条，避免提示堆积)
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  SnackBarAction? action,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
        action: action,
      ),
    );
}

/// 执行异步操作并统一反馈：成功显示可选的成功提示 (可带「撤销」)，失败显示错误提示。
/// 在 await 之前捕获 ScaffoldMessenger 与配色，避免异步间隙后使用失效的 context。
Future<void> runWithFeedback(
  BuildContext context,
  Future<void> Function() action, {
  String? successMessage,
  VoidCallback? onUndo,
  String failureTitle = '操作失败',
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final errorColor = Theme.of(context).colorScheme.error;
  try {
    await action();
    if (successMessage != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(successMessage),
            behavior: SnackBarBehavior.floating,
            action: onUndo == null ? null : SnackBarAction(label: '撤销', onPressed: onUndo),
          ),
        );
    }
  } catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$failureTitle：$e'),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
