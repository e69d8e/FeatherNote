import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../domain/models/app_update_info.dart';
import '../../domain/repositories/update_repository.dart';

/// 更新检查状态
class UpdateCheckState {
  /// 是否正在检查 (用于设置页手动检查的加载动画)
  final bool checking;

  /// 当前安装的版本号 (如 1.0.0)，加载完成前为空字符串
  final String currentVersion;

  /// 启动自动检查发现的新版本；展示后由 UI 调用 [UpdateController.dismissAutoUpdate] 清除
  final AppUpdateInfo? pendingAutoUpdate;

  const UpdateCheckState({
    this.checking = false,
    this.currentVersion = '',
    this.pendingAutoUpdate,
  });

  UpdateCheckState copyWith({
    bool? checking,
    String? currentVersion,
    AppUpdateInfo? pendingAutoUpdate,
    bool clearPendingAutoUpdate = false,
  }) {
    return UpdateCheckState(
      checking: checking ?? this.checking,
      currentVersion: currentVersion ?? this.currentVersion,
      pendingAutoUpdate:
          clearPendingAutoUpdate ? null : (pendingAutoUpdate ?? this.pendingAutoUpdate),
    );
  }
}

/// 更新检查状态通知器
class UpdateController extends StateNotifier<UpdateCheckState> {
  final UpdateRepository _repo;

  UpdateController(this._repo) : super(const UpdateCheckState()) {
    _loadCurrentVersion();
  }

  /// 异步读取当前版本号，用于设置页展示
  Future<void> _loadCurrentVersion() async {
    try {
      final version = await _repo.currentVersion();
      if (mounted) state = state.copyWith(currentVersion: version);
    } catch (_) {
      // 版本号读取失败仅影响展示，不打断主流程
    }
  }

  /// 手动检查更新：发现新版本返回其信息，已是最新返回 null，失败抛出异常由 UI 反馈
  Future<AppUpdateInfo?> checkManually() async {
    state = state.copyWith(checking: true);
    try {
      final info = await _repo.fetchLatestRelease();
      return info.hasUpdate ? info : null;
    } finally {
      if (mounted) state = state.copyWith(checking: false);
    }
  }

  /// 启动自动检查：受用户开关与节流间隔控制，任何失败都静默处理，不打扰用户
  Future<void> checkOnStartup({required bool enabled}) async {
    if (!enabled) return;
    try {
      if (!await _repo.shouldAutoCheck()) return;
      final info = await _repo.fetchLatestRelease();
      await _repo.markChecked();
      if (info.hasUpdate && mounted) {
        state = state.copyWith(pendingAutoUpdate: info);
      }
    } catch (_) {
      // 自动检查失败保持静默，不记录状态
    }
  }

  /// 用户已知晓启动时发现的新版本，关闭弹窗
  void dismissAutoUpdate() {
    state = state.copyWith(clearPendingAutoUpdate: true);
  }
}

/// 更新检查 StateNotifierProvider
final updateControllerProvider =
    StateNotifierProvider<UpdateController, UpdateCheckState>((ref) {
  return UpdateController(ref.watch(updateRepositoryProvider));
});
