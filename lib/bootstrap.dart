import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'app.dart';
import 'core/database/app_database.dart';
import 'core/providers/database_provider.dart';
import 'core/providers/shared_preferences_provider.dart';
import 'features/notes/domain/models/note.dart';
import 'features/settings/data/repositories/shared_prefs_settings_repository.dart';
import 'features/settings/presentation/controllers/settings_controller.dart';

/// 应用启动初始化
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 字体文件已打包进 assets/google_fonts/，离线也不再联网拉取字体
  GoogleFonts.config.allowRuntimeFetching = false;

  // 仅等待轻量的 platform channel，保证首帧即可应用用户的主题设置
  final sharedPrefs = await SharedPreferences.getInstance();
  final settingsRepo = SharedPrefsSettingsRepository(sharedPrefs);
  final initialSettings = await settingsRepo.loadSettings();

  // AppDatabase 构造是惰性的，真正打开 SQLite 发生在首次查询时
  final database = AppDatabase();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        appDatabaseProvider.overrideWithValue(database),
        settingsProvider.overrideWith((ref) => SettingsNotifier(settingsRepo, initialSettings)),
      ],
      child: const FeatherNoteApp(),
    ),
  );

  // 首帧渲染完成后再打开数据库并填充示例笔记，避免冷启动被 SQLite I/O 阻塞出现白屏
  unawaited(
    WidgetsBinding.instance.endOfFrame.then((_) => _seedInitialNotesIfEmpty(database)),
  );
}

/// 首次安装预置精美欢迎示例笔记
Future<void> _seedInitialNotesIfEmpty(AppDatabase db) async {
  await db.transaction(() async {
    final existing = await (db.selectOnly(db.notesTable)
          ..addColumns([db.notesTable.id])
          ..limit(1))
        .get();
    if (existing.isNotEmpty) return;

    final now = DateTime.now();

  // 1. 欢迎笔记 (落樱粉)
  final welcomeNote = Note(
    id: const Uuid().v4(),
    title: '欢迎使用羽记 · FeatherNote 🪶',
    content: '''轻盈如羽，行云流水。感谢使用「羽记」！

### 核心功能速览：
- **离线优先**：基于 SQLite/Drift 本地驱动，响应迅速，无需联网。
- **Markdown 支持**：支持标题、待办清单、粗斜体、代码块等快捷排版。
- **柔和羽色**：点击右上角更多或在列表长按卡片，随心变换 6 款马卡龙配色。
- **羽记书笺**：点击分享按钮，生成典雅的明信片卡片与好友分享。
- **即时搜索**：毫秒级全文与标签检索，轻松定位灵感。''',
    colorId: 'sakura',
    isPinned: true,
    tags: ['指南', '欢迎'],
    createdAt: now.subtract(const Duration(minutes: 5)),
    updatedAt: now.subtract(const Duration(minutes: 5)),
  );

  // 2. 待办清单示例 (初晴绿)
  final todoNote = Note(
    id: const Uuid().v4(),
    title: '今日待办与轻灵计划 🌱',
    content: '''- [x] 体验羽记流畅的瀑布流卡片
- [x] 尝试点击右上角切换 Markdown 预览
- [ ] 长按卡片尝试更换主题配色
- [ ] 创建属于自己的第一条专属标签''',
    colorId: 'sage',
    isPinned: false,
    tags: ['清单', '日常'],
    createdAt: now.subtract(const Duration(minutes: 15)),
    updatedAt: now.subtract(const Duration(minutes: 15)),
  );

  // 3. 灵感手记示例 (微风紫)
  final poemNote = Note(
    id: const Uuid().v4(),
    title: '微风与羽毛 🍃',
    content: '''> 飞鸟掠过湖面，羽毛轻轻飘落。
> 在指尖与屏幕相触的一瞬，灵感便有了归宿。

随时记录所思所想，让记忆轻盈无负担。''',
    colorId: 'lavender',
    isPinned: false,
    tags: ['随笔', '灵感'],
    createdAt: now.subtract(const Duration(minutes: 30)),
    updatedAt: now.subtract(const Duration(minutes: 30)),
  );

    // 单次批量写入，避免逐条插入
    await db.batch((batch) {
      batch.insert(db.notesTable, welcomeNote.toCompanion(), mode: InsertMode.insertOrReplace);
      batch.insert(db.notesTable, todoNote.toCompanion(), mode: InsertMode.insertOrReplace);
      batch.insert(db.notesTable, poemNote.toCompanion(), mode: InsertMode.insertOrReplace);
    });
  });
}
