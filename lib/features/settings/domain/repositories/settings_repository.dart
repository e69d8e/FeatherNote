import '../models/app_settings.dart';

/// 设置仓储接口
abstract class SettingsRepository {
  Future<AppSettings> loadSettings();
  Future<void> saveSettings(AppSettings settings);
}
