import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/app_update_info.dart';
import '../controllers/update_controller.dart';

/// 展示新版本提示对话框 (设置页手动检查与首页启动自动检查共用)
Future<void> showAppUpdateDialog(BuildContext context, AppUpdateInfo update) {
  return showDialog(
    context: context,
    builder: (_) => AppUpdateDialog(update: update),
  );
}

/// 新版本发现对话框：展示版本变化与 Release 更新说明，可跳转下载页
class AppUpdateDialog extends ConsumerWidget {
  const AppUpdateDialog({super.key, required this.update});

  final AppUpdateInfo update;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final hasNotes = update.releaseNotes.trim().isNotEmpty;

    return AlertDialog(
      title: Text('发现新版本 ${update.latestVersion}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '当前版本 v${update.currentVersion}，最新版本 v${update.latestVersion}。',
                style: textTheme.bodySmall,
              ),
              if (hasNotes) ...[
                const SizedBox(height: 12),
                Text(
                  '更新说明',
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                MarkdownBody(data: update.releaseNotes),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(updateControllerProvider.notifier).dismissAutoUpdate();
            Navigator.pop(context);
          },
          child: const Text('下次再说'),
        ),
        FilledButton(
          onPressed: () {
            ref.read(updateControllerProvider.notifier).dismissAutoUpdate();
            Navigator.pop(context);
            _openReleasePage(context, update.releaseUrl);
          },
          child: const Text('前往下载'),
        ),
      ],
    );
  }

  /// 用系统浏览器打开 Release 页面
  Future<void> _openReleasePage(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    try {
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('无法打开下载页面'),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('无法打开下载页面'),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
