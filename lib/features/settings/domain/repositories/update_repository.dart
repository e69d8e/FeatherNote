import '../models/app_update_info.dart';

/// 更新检查失败异常 (网络不可达、超时、接口异常等)
class UpdateCheckException implements Exception {
  final String message;

  const UpdateCheckException(this.message);

  @override
  String toString() => message;
}

/// 应用更新检查仓储接口
abstract class UpdateRepository {
  /// 当前安装的应用版本号 (如 1.0.0)
  Future<String> currentVersion();

  /// 查询最新版本信息并与当前版本比较；失败时抛出 [UpdateCheckException]
  Future<AppUpdateInfo> fetchLatestRelease();

  /// 距上次成功检查是否已超过节流间隔，可执行一次启动自动检查
  Future<bool> shouldAutoCheck();

  /// 记录一次成功的检查时间，用于自动检查节流
  Future<void> markChecked();
}
