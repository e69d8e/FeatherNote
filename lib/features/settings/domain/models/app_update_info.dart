/// 应用更新信息
class AppUpdateInfo {
  /// 当前安装的版本号 (如 1.0.0)
  final String currentVersion;

  /// 最新 Release 的版本号 (保留原始 tag 文本，如 v1.1.0)
  final String latestVersion;

  /// Release 详情页链接
  final String releaseUrl;

  /// Release 更新说明 (Markdown 文本)
  final String releaseNotes;

  /// Release 发布时间
  final DateTime? publishedAt;

  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    required this.releaseNotes,
    this.publishedAt,
  });

  /// 最新版本是否高于当前版本
  bool get hasUpdate =>
      compareVersions(latestVersion, currentVersion) > 0;

  /// 比较两个语义化版本号：a 大于 b 返回 1，小于返回 -1，相等返回 0。
  ///
  /// 兼容 "v1.2.3" 前缀与 "+build"、"-beta" 等后缀，缺省的段按 0 处理 (1.2 视为 1.2.0)。
  static int compareVersions(String a, String b) {
    final partsA = _versionParts(a);
    final partsB = _versionParts(b);
    final length = partsA.length > partsB.length ? partsA.length : partsB.length;
    for (var i = 0; i < length; i++) {
      final pa = i < partsA.length ? partsA[i] : 0;
      final pb = i < partsB.length ? partsB[i] : 0;
      if (pa != pb) return pa.compareTo(pb);
    }
    return 0;
  }

  /// 把版本号文本解析为数字段列表 (如 "v1.10.2+4" → [1, 10, 2])
  static List<int> _versionParts(String version) {
    final cleaned = version
        .trim()
        .replaceFirst(RegExp('^[vV]'), '')
        .split(RegExp(r'[+\-_]'))
        .first;
    return cleaned
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
  }

  @override
  String toString() =>
      'AppUpdateInfo(current: $currentVersion, latest: $latestVersion)';
}
