import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/notes_table.dart';
import 'tables/tags_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [NotesTable, TagsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  /// FTS5 全文索引是否可用 (环境缺少 fts5/trigram 扩展时自动降级为 LIKE 搜索)
  bool get ftsAvailable => _ftsAvailable;
  bool _ftsAvailable = false;

  /// FTS 索引创建失败的原因 (诊断用；正常情况下为 null)
  Object? get ftsLastError => _ftsLastError;
  Object? _ftsLastError;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        // FTS 索引的创建/自愈放在 beforeOpen：无论新库、旧库升级、
        // 还是曾因异常留下的残缺状态，每次启动都会收敛到正确结构
        beforeOpen: (details) async {
          await _ensureNotesFtsIndex();
        },
      );

  /// 确保 notes_fts 全文索引虚拟表与同步触发器就绪，并回填缺失数据。
  ///
  /// 采用 trigram 分词器：支持任意 ≥3 字符的子串匹配 (包括中文)。
  /// 注意：Drift 表类 NotesTable 对应的实际 SQL 表名是 `notes` (去掉 Table 后缀)。
  /// 创建失败 (如环境不支持 FTS5) 时静默降级，搜索退回 LIKE 全表扫描。
  Future<void> _ensureNotesFtsIndex() async {
    try {
      final ftsExists = (await customSelect(
        "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'notes_fts'",
      ).get()).isNotEmpty;
      final triggerExists = (await customSelect(
        "SELECT 1 FROM sqlite_master WHERE type = 'trigger' AND name = 'notes_fts_ai'",
      ).get()).isNotEmpty;

      if (ftsExists && triggerExists) {
        _ftsAvailable = true;
        return;
      }

      if (!ftsExists) {
        await customStatement(
          "CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5("
          "note_id UNINDEXED, title, content, tags, tokenize='trigram')",
        );
      }

      // 触发器缺失时 (新库或残缺状态) 重建：清空后全量回填，避免旧索引行残留
      await customStatement('DROP TRIGGER IF EXISTS notes_fts_ai');
      await customStatement('DROP TRIGGER IF EXISTS notes_fts_ad');
      await customStatement('DROP TRIGGER IF EXISTS notes_fts_au');
      await customStatement('DELETE FROM notes_fts');
      await customStatement(
        'INSERT INTO notes_fts(note_id, title, content, tags) '
        'SELECT id, title, content, tags FROM notes',
      );
      // INSERT OR REPLACE 不会触发 AFTER DELETE 触发器 (递归触发器默认关闭)，
      // 因此 INSERT/UPDATE 触发器都先按 note_id 清理旧行再写入，保证不产生重复
      await customStatement('''
        CREATE TRIGGER notes_fts_ai AFTER INSERT ON notes BEGIN
          DELETE FROM notes_fts WHERE note_id = new.id;
          INSERT INTO notes_fts(note_id, title, content, tags)
          VALUES (new.id, new.title, new.content, new.tags);
        END;
      ''');
      await customStatement('''
        CREATE TRIGGER notes_fts_ad AFTER DELETE ON notes BEGIN
          DELETE FROM notes_fts WHERE note_id = old.id;
        END;
      ''');
      await customStatement('''
        CREATE TRIGGER notes_fts_au AFTER UPDATE ON notes BEGIN
          DELETE FROM notes_fts WHERE note_id = new.id;
          INSERT INTO notes_fts(note_id, title, content, tags)
          VALUES (new.id, new.title, new.content, new.tags);
        END;
      ''');
      _ftsAvailable = true;
      _ftsLastError = null;
    } catch (e) {
      _ftsAvailable = false;
      _ftsLastError = e;
    }
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'feathernote_db',
      native: const DriftNativeOptions(
        shareAcrossIsolates: true,
      ),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }

  // ================= 笔记相关响应式流与查询 =================

  /// 监听活跃笔记列表 (未删除、未归档，置顶优先，更新时间倒序)
  Stream<List<NoteEntry>> watchActiveNotes({String? tagFilter}) {
    final query = select(notesTable)
      ..where((tbl) => tbl.isDeleted.equals(false) & tbl.isArchived.equals(false));

    if (tagFilter != null && tagFilter.isNotEmpty) {
      // 标签以逗号分隔存储，两侧补逗号后做精确匹配：
      // 避免 LIKE 子串匹配把「工作」误匹配到「工作任务」等标签
      query.where((tbl) {
        final delimited = Constant(',') + tbl.tags + Constant(',');
        return delimited.like('%,$tagFilter,%');
      });
    }

    query.orderBy([
      (tbl) => OrderingTerm(expression: tbl.isPinned, mode: OrderingMode.desc),
      (tbl) => OrderingTerm(expression: tbl.updatedAt, mode: OrderingMode.desc),
    ]);

    return query.watch();
  }

  /// 监听已归档笔记
  Stream<List<NoteEntry>> watchArchivedNotes() {
    final query = select(notesTable)
      ..where((tbl) => tbl.isDeleted.equals(false) & tbl.isArchived.equals(true))
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.updatedAt, mode: OrderingMode.desc),
      ]);
    return query.watch();
  }

  /// 监听废纸篓笔记
  Stream<List<NoteEntry>> watchDeletedNotes() {
    final query = select(notesTable)
      ..where((tbl) => tbl.isDeleted.equals(true))
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.deletedAt, mode: OrderingMode.desc),
      ]);
    return query.watch();
  }

  /// 搜索笔记 (标题、正文或标签模糊匹配)
  ///
  /// ≥3 字符的查询优先走 FTS5 trigram 倒排索引 (任意子串匹配，含中文)，
  /// 避免 LIKE 全表扫描；更短的查询 (如二字中文词) 或 FTS 不可用的环境
  /// 自动退回 LIKE 路径。
  Stream<List<NoteEntry>> searchNotes(String query) {
    final q = query.trim();
    if (q.isEmpty) {
      return Stream.value([]);
    }

    if (_ftsAvailable && q.length >= 3) {
      // 引号包裹为短语查询并转义内部引号，防止 FTS 语法注入。
      // 注意 MATCH 左侧必须是 FTS 表的真实表名 (隐藏列名)，不能使用别名
      final matchQuery = '"${q.replaceAll('"', '""')}"';
      return customSelect(
        'SELECT n.* FROM notes_fts '
        'JOIN notes n ON n.id = notes_fts.note_id '
        'WHERE notes_fts MATCH ? AND n.is_deleted = 0 '
        'ORDER BY n.updated_at DESC',
        variables: [Variable(matchQuery)],
        readsFrom: {notesTable},
      ).watch().asyncMap((rows) async => [
            for (final row in rows) await notesTable.mapFromRow(row),
          ]);
    }

    final pattern = '%$q%';
    final like = select(notesTable)
      ..where((tbl) =>
          tbl.isDeleted.equals(false) &
          (tbl.title.like(pattern) | tbl.content.like(pattern) | tbl.tags.like(pattern)))
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.updatedAt, mode: OrderingMode.desc),
      ]);
    return like.watch();
  }

  /// 根据 ID 获取单个笔记
  Future<NoteEntry?> getNoteById(String id) {
    return (select(notesTable)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// 根据 ID 监听单个笔记变化
  Stream<NoteEntry?> watchNoteById(String id) {
    return (select(notesTable)..where((tbl) => tbl.id.equals(id))).watchSingleOrNull();
  }

  /// 插入或更新笔记
  Future<int> upsertNote(NotesTableCompanion note) {
    return into(notesTable).insertOnConflictUpdate(note);
  }

  /// 软删除笔记 (移入废纸篓)
  Future<int> softDeleteNote(String id) {
    return (update(notesTable)..where((tbl) => tbl.id.equals(id))).write(
      NotesTableCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 从废纸篓恢复笔记
  Future<int> restoreNote(String id) {
    return (update(notesTable)..where((tbl) => tbl.id.equals(id))).write(
      const NotesTableCompanion(
        isDeleted: Value(false),
        deletedAt: Value(null),
      ),
    );
  }

  /// 归档 / 取消归档笔记
  Future<int> toggleArchiveNote(String id, bool isArchived) {
    return (update(notesTable)..where((tbl) => tbl.id.equals(id))).write(
      NotesTableCompanion(
        isArchived: Value(isArchived),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 置顶 / 取消置顶笔记
  Future<int> togglePinNote(String id, bool isPinned) {
    return (update(notesTable)..where((tbl) => tbl.id.equals(id))).write(
      NotesTableCompanion(
        isPinned: Value(isPinned),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 更新笔记颜色
  Future<int> updateNoteColor(String id, String colorId) {
    return (update(notesTable)..where((tbl) => tbl.id.equals(id))).write(
      NotesTableCompanion(
        colorId: Value(colorId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 永久删除单个笔记
  Future<int> permanentlyDeleteNote(String id) {
    return (delete(notesTable)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// 清空废纸篓
  Future<int> emptyTrash() {
    return (delete(notesTable)..where((tbl) => tbl.isDeleted.equals(true))).go();
  }

  /// 获取所有笔记数据 (用于导出备份)
  Future<List<NoteEntry>> getAllNotes() {
    return select(notesTable).get();
  }

  // ================= 标签相关操作 =================

  /// 监听所有标签列表
  Stream<List<TagEntry>> watchAllTags() {
    return (select(tagsTable)..orderBy([(tbl) => OrderingTerm(expression: tbl.name)])).watch();
  }

  /// 插入新标签 (若已存在则忽略)
  Future<int> insertTag(TagsTableCompanion tag) {
    return into(tagsTable).insert(tag, mode: InsertMode.insertOrIgnore);
  }

  /// 删除标签
  Future<int> deleteTag(String id) {
    return (delete(tagsTable)..where((tbl) => tbl.id.equals(id))).go();
  }
}
