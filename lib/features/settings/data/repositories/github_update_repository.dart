import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/app_update_info.dart';
import '../../domain/repositories/update_repository.dart';

/// 基于 GitHub Releases API 的更新检查实现
class GithubUpdateRepository implements UpdateRepository {
  GithubUpdateRepository({
    http.Client? client,
    required this.prefs,
    this.overrideVersion,
  }) : _client = client ?? http.Client();

  /// 托管 Release 的 GitHub 仓库
  static const repoSlug = 'e69d8e/FeatherNote';

  static const _apiLatestUrl =
      'https://api.github.com/repos/$repoSlug/releases/latest';
  static const _releasesPageUrl = 'https://github.com/$repoSlug/releases';
  static const _keyLastCheckMs = 'feathernote_last_update_check_ms';

  /// 自动检查节流间隔，避免每次启动都请求 GitHub API
  static const autoCheckInterval = Duration(hours: 24);

  static const _requestTimeout = Duration(seconds: 10);

  final http.Client _client;

  /// 应用偏好存储，持久化上次成功检查的时间戳
  final SharedPreferences prefs;

  /// 测试注入用；非空时跳过 PackageInfo 平台通道
  final String? overrideVersion;

  String? _cachedCurrentVersion;

  @override
  Future<String> currentVersion() async {
    final cached = _cachedCurrentVersion ?? overrideVersion;
    if (cached != null) return cached;
    final info = await PackageInfo.fromPlatform();
    return _cachedCurrentVersion = info.version;
  }

  @override
  Future<AppUpdateInfo> fetchLatestRelease() async {
    final current = await currentVersion();
    try {
      final response = await _client.get(
        Uri.parse(_apiLatestUrl),
        headers: const {
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'FeatherNote-UpdateCheck',
        },
      ).timeout(_requestTimeout);

      if (response.statusCode != 200) {
        throw UpdateCheckException('GitHub 服务返回异常 (HTTP ${response.statusCode})');
      }

      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final tagName = (json['tag_name'] as String?)?.trim() ?? '';
      if (tagName.isEmpty) {
        throw UpdateCheckException('Release 数据格式异常');
      }

      return AppUpdateInfo(
        currentVersion: current,
        latestVersion: tagName,
        releaseUrl: (json['html_url'] as String?)?.isNotEmpty == true
            ? json['html_url'] as String
            : _releasesPageUrl,
        releaseNotes: (json['body'] as String?) ?? '',
        publishedAt: DateTime.tryParse((json['published_at'] as String?) ?? ''),
      );
    } on UpdateCheckException {
      rethrow;
    } catch (e) {
      // 网络不可达、超时、JSON 解析失败等统一转为领域异常，屏蔽实现细节
      throw const UpdateCheckException('无法连接 GitHub，请检查网络后重试');
    }
  }

  @override
  Future<bool> shouldAutoCheck() async {
    final lastCheckMs = prefs.getInt(_keyLastCheckMs);
    if (lastCheckMs == null) return true;
    return DateTime.now().millisecondsSinceEpoch - lastCheckMs >=
        autoCheckInterval.inMilliseconds;
  }

  @override
  Future<void> markChecked() {
    return prefs.setInt(_keyLastCheckMs, DateTime.now().millisecondsSinceEpoch);
  }
}
