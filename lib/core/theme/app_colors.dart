import 'package:flutter/material.dart';

/// 羽记主题颜色与马卡龙羽毛色板
class AppColors {
  AppColors._();

  // 基础强调色
  static const Color primary = Color(0xFF4A6572);
  static const Color primaryContainer = Color(0xFFD6E4EB);
  static const Color secondary = Color(0xFFF9AA33);
  static const Color secondaryContainer = Color(0xFFFFE0B2);
  static const Color tertiary = Color(0xFF708090);

  // 浅色背景与表面
  static const Color lightBackground = Color(0xFFFBFBFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF0F3F6);
  static const Color lightCardBorder = Color(0xFFE8ECEF);

  // 深色背景与表面
  static const Color darkBackground = Color(0xFF14171A);
  static const Color darkSurface = Color(0xFF1E2328);
  static const Color darkSurfaceVariant = Color(0xFF272D34);
  static const Color darkCardBorder = Color(0xFF323A42);

  // 笔记专属「羽色」马卡龙轻柔调色板 (Note Color Presets)
  static const List<FeatherNoteColor> noteColors = [
    FeatherNoteColor(
      id: 'default',
      name: '纯羽白',
      lightBackground: Color(0xFFFFFFFF),
      lightBorder: Color(0xFFE5E9EC),
      darkBackground: Color(0xFF1E2328),
      darkBorder: Color(0xFF2E3740),
      accentColor: Color(0xFF607D8B),
    ),
    FeatherNoteColor(
      id: 'sakura',
      name: '落樱粉',
      lightBackground: Color(0xFFFFF0F3),
      lightBorder: Color(0xFFFFD1DC),
      darkBackground: Color(0xFF2E1C22),
      darkBorder: Color(0xFF4D2C37),
      accentColor: Color(0xFFE86A82),
    ),
    FeatherNoteColor(
      id: 'sage',
      name: '初晴绿',
      lightBackground: Color(0xFFF0F7F2),
      lightBorder: Color(0xFFD3E8D7),
      darkBackground: Color(0xFF1A2920),
      darkBorder: Color(0xFF2B4435),
      accentColor: Color(0xFF52A36B),
    ),
    FeatherNoteColor(
      id: 'lavender',
      name: '微风紫',
      lightBackground: Color(0xFFF5F2FD),
      lightBorder: Color(0xFFE1D7FA),
      darkBackground: Color(0xFF241C2E),
      darkBorder: Color(0xFF3B2E4C),
      accentColor: Color(0xFF8B68E6),
    ),
    FeatherNoteColor(
      id: 'amber',
      name: '暖阳杏',
      lightBackground: Color(0xFFFFF8EC),
      lightBorder: Color(0xFFFFE5BF),
      darkBackground: Color(0xFF2E2416),
      darkBorder: Color(0xFF4C3B24),
      accentColor: Color(0xFFE29227),
    ),
    FeatherNoteColor(
      id: 'sky',
      name: '空境蓝',
      lightBackground: Color(0xFFF0F6FF),
      lightBorder: Color(0xFFD0E2FF),
      darkBackground: Color(0xFF162233),
      darkBorder: Color(0xFF253955),
      accentColor: Color(0xFF3D87F5),
    ),
  ];

  /// 根据 ID 获取笔记预设颜色配置
  static FeatherNoteColor getNoteColor(String? colorId, {bool isDark = false}) {
    final found = noteColors.firstWhere(
      (c) => c.id == colorId,
      orElse: () => noteColors.first,
    );
    return found;
  }
}

/// 笔记单个配色方案
class FeatherNoteColor {
  final String id;
  final String name;
  final Color lightBackground;
  final Color lightBorder;
  final Color darkBackground;
  final Color darkBorder;
  final Color accentColor;

  const FeatherNoteColor({
    required this.id,
    required this.name,
    required this.lightBackground,
    required this.lightBorder,
    required this.darkBackground,
    required this.darkBorder,
    required this.accentColor,
  });

  Color background(bool isDark) => isDark ? darkBackground : lightBackground;
  Color border(bool isDark) => isDark ? darkBorder : lightBorder;
}
