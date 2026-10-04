import 'package:flutter_test/flutter_test.dart';
import 'package:feathernote/features/settings/domain/models/app_update_info.dart';

void main() {
  group('AppUpdateInfo.compareVersions', () {
    test('主版本号更高时返回 1', () {
      expect(AppUpdateInfo.compareVersions('2.0.0', '1.9.9'), 1);
    });

    test('次版本号与补丁号比较', () {
      expect(AppUpdateInfo.compareVersions('1.10.0', '1.9.0'), 1);
      expect(AppUpdateInfo.compareVersions('1.0.1', '1.0.0'), 1);
      expect(AppUpdateInfo.compareVersions('1.0.0', '1.0.1'), -1);
    });

    test('兼容 v 前缀与 +build / -beta 后缀', () {
      expect(AppUpdateInfo.compareVersions('v1.1.0', '1.0.0'), 1);
      expect(AppUpdateInfo.compareVersions('v1.1.0+5', 'v1.1.0-beta'), 0);
    });

    test('缺省段按 0 处理', () {
      expect(AppUpdateInfo.compareVersions('1.2', '1.2.0'), 0);
      expect(AppUpdateInfo.compareVersions('1.2.0', '1.2'), 0);
      expect(AppUpdateInfo.compareVersions('1.3', '1.2.9'), 1);
    });

    test('相同版本返回 0', () {
      expect(AppUpdateInfo.compareVersions('1.0.0', '1.0.0'), 0);
      expect(AppUpdateInfo.compareVersions('v1.0.0', '1.0.0'), 0);
    });
  });

  group('AppUpdateInfo.hasUpdate', () {
    AppUpdateInfo buildInfo(String current, String latest) {
      return AppUpdateInfo(
        currentVersion: current,
        latestVersion: latest,
        releaseUrl: 'https://github.com/e69d8e/FeatherNote/releases',
        releaseNotes: '',
      );
    }

    test('最新版本更高时提示更新', () {
      expect(buildInfo('1.0.0', 'v1.1.0').hasUpdate, isTrue);
    });

    test('版本相同时不提示更新', () {
      expect(buildInfo('1.0.0', 'v1.0.0').hasUpdate, isFalse);
    });

    test('本地版本更高 (误报防护) 时不提示更新', () {
      expect(buildInfo('1.2.0', 'v1.0.0').hasUpdate, isFalse);
    });
  });
}
