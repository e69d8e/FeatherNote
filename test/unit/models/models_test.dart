import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feathernote/features/notes/domain/models/note.dart';
import 'package:feathernote/features/settings/domain/models/app_settings.dart';
import 'package:feathernote/features/tags/domain/models/tag.dart';
import 'package:feathernote/features/todos/domain/models/todo_item.dart';

void main() {
  group('Note Model', () {
    final now = DateTime(2026, 9, 4, 12, 0);

    test('值对象相等性与散列值一致性', () {
      final note1 = Note(
        id: 'n-1',
        title: '测试笔记',
        content: '这是内容',
        colorId: 'sakura',
        tags: ['工作', 'flutter'],
        createdAt: now,
        updatedAt: now,
      );

      final note2 = Note(
        id: 'n-1',
        title: '测试笔记',
        content: '这是内容',
        colorId: 'sakura',
        tags: ['工作', 'flutter'],
        createdAt: now,
        updatedAt: now,
      );

      final note3 = note1.copyWith(title: '变更后标题');

      expect(note1, equals(note2));
      expect(note1.hashCode, equals(note2.hashCode));
      expect(note1 == note3, isFalse);
    });

    test('displayTitle 行为与截断逻辑', () {
      // 1. 有明确标题时使用标题
      final n1 = Note(
        id: '1',
        title: ' 我的专属标题 ',
        content: '# 一级标题\n其他内容',
        createdAt: now,
        updatedAt: now,
      );
      expect(n1.displayTitle, equals('我的专属标题'));

      // 2. 标题为空但内容有首行标题时，提取首行并清洗 #
      final n2 = Note(
        id: '2',
        title: '',
        content: '###   首行核心灵感提炼\n第二行正文\n第三行正文',
        createdAt: now,
        updatedAt: now,
      );
      expect(n2.displayTitle, equals('首行核心灵感提炼'));

      // 3. 首行超长时截断并加省略号 (上限 20 字)
      final n3 = Note(
        id: '3',
        title: '',
        content: '这是一个非常非常非常非常非常非常非常非常长长长长长的首行',
        createdAt: now,
        updatedAt: now,
      );
      expect(n3.displayTitle.length, equals(23)); // 20 + 3
      expect(n3.displayTitle.endsWith('...'), isTrue);

      // 4. 标题与正文均为空时默认兜底
      final n4 = Note(
        id: '4',
        title: '  ',
        content: '  ',
        createdAt: now,
        updatedAt: now,
      );
      expect(n4.displayTitle, equals('无标题笔记'));
      expect(n4.isEmpty, isTrue);
    });

    test('toJson 与 fromJson 序列化一致性', () {
      final note = Note(
        id: 'json-1',
        title: '备份导出',
        content: '正文测试',
        colorId: 'sage',
        isPinned: true,
        isArchived: false,
        isDeleted: false,
        tags: ['标签1', '标签2'],
        createdAt: now,
        updatedAt: now,
      );

      final map = note.toJson();
      final restored = Note.fromJson(map);

      expect(restored, equals(note));
      expect(restored.tags, equals(['标签1', '标签2']));
      expect(restored.isPinned, isTrue);
    });
  });

  group('TodoItem Model', () {
    final now = DateTime(2026, 9, 4, 12, 0);

    test('值对象相等性与 copyWith', () {
      final item1 = TodoItem(
        id: 't-1',
        noteId: 'n-1',
        noteTitle: '笔记A',
        indexInNote: 0,
        text: '准备会议议程',
        isCompleted: false,
        noteColorId: 'sage',
        updatedAt: now,
      );

      final item2 = TodoItem(
        id: 't-1',
        noteId: 'n-1',
        noteTitle: '笔记A',
        indexInNote: 0,
        text: '准备会议议程',
        isCompleted: false,
        noteColorId: 'sage',
        updatedAt: now,
      );

      expect(item1, equals(item2));
      expect(item1.hashCode, equals(item2.hashCode));

      final completed = item1.copyWith(isCompleted: true);
      expect(completed.isCompleted, isTrue);
      expect(item1 == completed, isFalse);
    });
  });

  group('Tag Model', () {
    final now = DateTime(2026, 9, 4, 12, 0);

    test('值对象相等性与字段一致', () {
      final tag1 = Tag(id: 'flutter', name: 'Flutter', createdAt: now);
      final tag2 = Tag(id: 'flutter', name: 'Flutter', createdAt: now);
      final tag3 = Tag(id: 'drift', name: 'Drift', createdAt: now);

      expect(tag1, equals(tag2));
      expect(tag1.hashCode, equals(tag2.hashCode));
      expect(tag1 == tag3, isFalse);
    });
  });

  group('AppSettings Model', () {
    test('默认设置与 copyWith', () {
      const settings = AppSettings();
      expect(settings.themeMode, equals(ThemeMode.system));
      expect(settings.viewMode, equals(NoteViewMode.staggered));
      expect(settings.sortField, equals(NoteSortField.updatedAt));
      expect(settings.sortAscending, isFalse);
      expect(settings.fontScale, equals(1.0));
      expect(settings.defaultColorId, equals('default'));
      expect(settings.autoSaveMarkdown, isTrue);

      const settings2 = AppSettings();
      expect(settings, equals(settings2));
      expect(settings.hashCode, equals(settings2.hashCode));

      final custom = settings.copyWith(
        themeMode: ThemeMode.dark,
        viewMode: NoteViewMode.list,
        fontScale: 1.2,
      );

      expect(custom.themeMode, equals(ThemeMode.dark));
      expect(custom.viewMode, equals(NoteViewMode.list));
      expect(custom.fontScale, equals(1.2));
      expect(custom == settings, isFalse);
    });
  });
}
