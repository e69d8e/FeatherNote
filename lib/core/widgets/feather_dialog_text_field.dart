import 'package:flutter/material.dart';

/// 对话框一次性输入框：内部持有 TextEditingController，
/// 释放时机跟随对话框路由销毁 (晚于退出动画)，
/// 避免「pop 时立即 dispose」导致退出动画期间控制器被提前释放。
///
/// 文本读取方式：通过 [onChanged] 回传给外部，提交按钮直接读外部变量。
class FeatherDialogTextField extends StatefulWidget {
  final String? hintText;
  final int maxLines;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const FeatherDialogTextField({
    super.key,
    this.hintText,
    this.maxLines = 1,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<FeatherDialogTextField> createState() => _FeatherDialogTextFieldState();
}

class _FeatherDialogTextFieldState extends State<FeatherDialogTextField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => widget.onChanged?.call(_controller.text));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      maxLines: widget.maxLines,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(hintText: widget.hintText),
    );
  }
}
