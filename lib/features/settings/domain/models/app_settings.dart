import 'package:flutter/material.dart';

enum NoteViewMode {
  staggered, // 瀑布流
  grid,      // 紧凑网格
  list,      // 单列列表
}

enum NoteSortField {
  updatedAt,
  createdAt,
  title,
}

/// 应用设置实体
class AppSettings {
  final ThemeMode themeMode;
  final NoteViewMode viewMode;
  final NoteSortField sortField;
  final bool sortAscending;
  final double fontScale;
  final String defaultColorId;
  final bool autoSaveMarkdown;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.viewMode = NoteViewMode.staggered,
    this.sortField = NoteSortField.updatedAt,
    this.sortAscending = false,
    this.fontScale = 1.0,
    this.defaultColorId = 'default',
    this.autoSaveMarkdown = true,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    NoteViewMode? viewMode,
    NoteSortField? sortField,
    bool? sortAscending,
    double? fontScale,
    String? defaultColorId,
    bool? autoSaveMarkdown,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      viewMode: viewMode ?? this.viewMode,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      fontScale: fontScale ?? this.fontScale,
      defaultColorId: defaultColorId ?? this.defaultColorId,
      autoSaveMarkdown: autoSaveMarkdown ?? this.autoSaveMarkdown,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.themeMode == themeMode &&
        other.viewMode == viewMode &&
        other.sortField == sortField &&
        other.sortAscending == sortAscending &&
        other.fontScale == fontScale &&
        other.defaultColorId == defaultColorId &&
        other.autoSaveMarkdown == autoSaveMarkdown;
  }

  @override
  int get hashCode => Object.hash(
        themeMode,
        viewMode,
        sortField,
        sortAscending,
        fontScale,
        defaultColorId,
        autoSaveMarkdown,
      );
}
