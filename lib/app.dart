import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/controllers/settings_controller.dart';

/// 羽记根应用组件
class FeatherNoteApp extends ConsumerWidget {
  const FeatherNoteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // 只监听主题相关字段：其它设置变化 (如视图模式、排序) 不再触发
    // MaterialApp 级别的全局重建
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    final fontScale = ref.watch(settingsProvider.select((s) => s.fontScale));

    return MaterialApp.router(
      title: '羽记',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(fontScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
