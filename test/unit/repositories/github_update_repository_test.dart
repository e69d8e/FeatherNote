import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:feathernote/features/settings/data/repositories/github_update_repository.dart';
import 'package:feathernote/features/settings/domain/repositories/update_repository.dart';

void main() {
  const releaseJson = {
    'tag_name': 'v1.1.0',
    'html_url': 'https://github.com/e69d8e/FeatherNote/releases/tag/v1.1.0',
    'body': '### 更新内容\n- 新增检查更新功能',
    'published_at': '2026-10-01T10:00:00Z',
  };

  Future<GithubUpdateRepository> buildRepo(
    http.Client client, {
    String overrideVersion = '1.0.0',
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return GithubUpdateRepository(
      client: client,
      prefs: prefs,
      overrideVersion: overrideVersion,
    );
  }

  group('GithubUpdateRepository.fetchLatestRelease', () {
    test('解析 Release 数据并正确判定有新版本', () async {
      http.Request? captured;
      final repo = await buildRepo(MockClient((request) async {
        captured = request;
        // 声明 application/json 才会按 UTF-8 编码，与真实 GitHub API 响应头一致
        return http.Response(jsonEncode(releaseJson), 200,
            headers: {'content-type': 'application/json; charset=utf-8'});
      }));

      final info = await repo.fetchLatestRelease();

      expect(info.currentVersion, '1.0.0');
      expect(info.latestVersion, 'v1.1.0');
      expect(info.hasUpdate, isTrue);
      expect(info.releaseUrl, 'https://github.com/e69d8e/FeatherNote/releases/tag/v1.1.0');
      expect(info.releaseNotes, contains('检查更新'));
      expect(info.publishedAt, DateTime.utc(2026, 10, 1, 10));

      // 请求应打向 latest Release 端点并携带 GitHub 要求的 User-Agent
      expect(captured!.url.toString(), contains('/repos/e69d8e/FeatherNote/releases/latest'));
      expect(captured!.headers['User-Agent'], isNotEmpty);
    });

    test('已是最新版本时 hasUpdate 为 false', () async {
      final repo = await buildRepo(MockClient((request) async {
        return http.Response(
          jsonEncode({...releaseJson, 'tag_name': 'v1.0.0'}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }));

      final info = await repo.fetchLatestRelease();
      expect(info.hasUpdate, isFalse);
    });

    test('接口状态异常时抛出 UpdateCheckException', () async {
      final repo = await buildRepo(MockClient((request) async {
        return http.Response('rate limited', 403);
      }));

      expect(
        () => repo.fetchLatestRelease(),
        throwsA(isA<UpdateCheckException>()),
      );
    });

    test('网络失败转为 UpdateCheckException', () async {
      final repo = await buildRepo(MockClient((request) async {
        throw http.ClientException('offline');
      }));

      await expectLater(
        repo.fetchLatestRelease(),
        throwsA(isA<UpdateCheckException>()),
      );
    });
  });

  group('GithubUpdateRepository 自动检查节流', () {
    test('首次使用需要检查，记录后进入节流窗口', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = GithubUpdateRepository(
        client: MockClient((request) async => http.Response('[]', 200)),
        prefs: prefs,
        overrideVersion: '1.0.0',
      );

      expect(await repo.shouldAutoCheck(), isTrue);

      await repo.markChecked();
      expect(await repo.shouldAutoCheck(), isFalse);
    });
  });
}
