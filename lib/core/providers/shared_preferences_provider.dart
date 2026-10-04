import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/repositories/update_repository.dart';
import '../../features/settings/data/repositories/shared_prefs_settings_repository.dart';
import '../../features/settings/data/repositories/github_update_repository.dart';

/// SharedPreferences 实例 Provider (在应用启动时在 ProviderScope 中通过 overrideWithValue 注入)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main()');
});

/// 设置仓储 Provider
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SharedPrefsSettingsRepository(prefs);
});

/// 更新检查仓储 Provider
final updateRepositoryProvider = Provider<UpdateRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return GithubUpdateRepository(prefs: prefs);
});
