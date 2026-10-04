import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feathernote/core/providers/shared_preferences_provider.dart';
import 'package:feathernote/features/settings/domain/models/app_update_info.dart';
import 'package:feathernote/features/settings/domain/repositories/update_repository.dart';
import 'package:feathernote/features/settings/presentation/controllers/update_controller.dart';

/// 固定返回值/记录调用次数的假仓储
class FakeUpdateRepository implements UpdateRepository {
  FakeUpdateRepository({this.installedVersion = '1.0.0'});

  final String installedVersion;

  /// fetchLatestRelease 的返回值
  AppUpdateInfo? nextInfo;

  /// 非空时 fetchLatestRelease 抛出该异常
  Object? nextError;

  bool due = true;
  int fetchCount = 0;
  int markCount = 0;

  @override
  Future<String> currentVersion() async => installedVersion;

  @override
  Future<AppUpdateInfo> fetchLatestRelease() async {
    fetchCount++;
    final error = nextError;
    if (error != null) throw error;
    return nextInfo!;
  }

  @override
  Future<bool> shouldAutoCheck() async => due;

  @override
  Future<void> markChecked() async => markCount++;
}

AppUpdateInfo newInfo({String current = '1.0.0', String latest = 'v1.1.0'}) {
  return AppUpdateInfo(
    currentVersion: current,
    latestVersion: latest,
    releaseUrl: 'https://github.com/e69d8e/FeatherNote/releases',
    releaseNotes: '- 修复问题',
  );
}

void main() {
  test('构造后异步加载当前版本号', () async {
    final fake = FakeUpdateRepository();
    final container = ProviderContainer(
      overrides: [updateRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final controller = container.read(updateControllerProvider.notifier);
    expect(controller.state.currentVersion, isEmpty);

    await pumpEventQueue();
    expect(controller.state.currentVersion, '1.0.0');
  });

  group('checkManually', () {
    test('发现新版本时返回更新信息并结束 checking 状态', () async {
      final fake = FakeUpdateRepository()..nextInfo = newInfo();
      final container = ProviderContainer(
        overrides: [updateRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      final controller = container.read(updateControllerProvider.notifier);

      final result = await controller.checkManually();

      expect(result, isNotNull);
      expect(result!.latestVersion, 'v1.1.0');
      expect(controller.state.checking, isFalse);
    });

    test('已是最新版本时返回 null', () async {
      final fake = FakeUpdateRepository()..nextInfo = newInfo(latest: 'v1.0.0');
      final container = ProviderContainer(
        overrides: [updateRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      final controller = container.read(updateControllerProvider.notifier);

      expect(await controller.checkManually(), isNull);
      expect(controller.state.checking, isFalse);
    });
  });

  group('checkOnStartup', () {
    test('开关关闭时不发起请求', () async {
      final fake = FakeUpdateRepository()..nextInfo = newInfo();
      final container = ProviderContainer(
        overrides: [updateRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      final controller = container.read(updateControllerProvider.notifier);

      await controller.checkOnStartup(enabled: false);

      expect(fake.fetchCount, 0);
      expect(controller.state.pendingAutoUpdate, isNull);
    });

    test('发现新版本时记录待提示状态并标记检查时间', () async {
      final fake = FakeUpdateRepository()..nextInfo = newInfo();
      final container = ProviderContainer(
        overrides: [updateRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      final controller = container.read(updateControllerProvider.notifier);

      await controller.checkOnStartup(enabled: true);

      expect(fake.fetchCount, 1);
      expect(fake.markCount, 1);
      expect(controller.state.pendingAutoUpdate, isNotNull);
    });

    test('无新版本时不弹提示', () async {
      final fake = FakeUpdateRepository()..nextInfo = newInfo(latest: 'v1.0.0');
      final container = ProviderContainer(
        overrides: [updateRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      final controller = container.read(updateControllerProvider.notifier);

      await controller.checkOnStartup(enabled: true);

      expect(controller.state.pendingAutoUpdate, isNull);
    });

    test('处于节流窗口内时不发起请求', () async {
      final fake = FakeUpdateRepository()
        ..due = false
        ..nextInfo = newInfo();
      final container = ProviderContainer(
        overrides: [updateRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      final controller = container.read(updateControllerProvider.notifier);

      await controller.checkOnStartup(enabled: true);

      expect(fake.fetchCount, 0);
    });

    test('检查失败时静默处理，不记录检查时间也不弹提示', () async {
      final fake = FakeUpdateRepository()..nextError = const UpdateCheckException('网络不可用');
      final container = ProviderContainer(
        overrides: [updateRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      final controller = container.read(updateControllerProvider.notifier);

      await controller.checkOnStartup(enabled: true);

      expect(fake.markCount, 0);
      expect(controller.state.pendingAutoUpdate, isNull);
    });
  });

  test('dismissAutoUpdate 清除待提示状态', () async {
    final fake = FakeUpdateRepository()..nextInfo = newInfo();
    final container = ProviderContainer(
      overrides: [updateRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    final controller = container.read(updateControllerProvider.notifier);

    await controller.checkOnStartup(enabled: true);
    expect(controller.state.pendingAutoUpdate, isNotNull);

    controller.dismissAutoUpdate();
    expect(controller.state.pendingAutoUpdate, isNull);
  });
}
