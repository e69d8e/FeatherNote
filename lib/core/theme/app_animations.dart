import 'package:flutter/material.dart';

/// 羽记轻盈动效规范
class AppAnimations {
  AppAnimations._();

  // 动效时长
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration pageTransition = Duration(milliseconds: 320);

  // 动效曲线 (采用如羽毛轻落般的轻微回弹与减速曲线)
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve springCurve = Curves.easeOutBack;
  static const Curve smooth = Curves.easeInOutCubicEmphasized;
  static const Curve entrance = Curves.fastOutSlowIn;
}
