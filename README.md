<div align="center">

# 🪶 羽记 FeatherNote

**轻盈如羽，行云流水 —— 跨平台离线 Markdown 笔记与待办应用**

[![最新版本](https://img.shields.io/github/v/release/e69d8e/FeatherNote?label=%E6%9C%80%E6%96%B0%E7%89%88%E6%9C%AC&color=F4A9B8)](https://github.com/e69d8e/FeatherNote/releases/latest)
[![平台支持](https://img.shields.io/badge/%E5%B9%B3%E5%8F%B0-Android%20%C2%B7%20iOS%20%C2%B7%20Windows%20%C2%B7%20macOS%20%C2%B7%20Linux%20%C2%B7%20Web-A8C6A0)](https://github.com/e69d8e/FeatherNote/releases/latest)
[![基于 Flutter](https://img.shields.io/badge/Flutter-%E8%B7%A8%E5%B9%B3%E5%8F%B0-02569B?logo=flutter&logoColor=white)](https://flutter.dev)

</div>

羽记是一款追求极致轻盈书写体验的离线优先记事本：笔记、待办、标签、全文搜索都在一个应用里完成。无账号、无后端、无遥测，所有数据只存在于你自己的设备上。

## ✨ 功能特性

- **离线优先** —— 基于 SQLite 本地驱动，响应迅速，不登录、不联网也能完整使用
- **Markdown 编辑与预览** —— 支持标题、粗斜体、代码块、引用等常用语法，实时切换预览
- **待办清单** —— 在任意笔记中用 `- [ ]` 记录任务，首页自动聚合展示，随手勾选
- **即时搜索** —— 基于 FTS5 trigram 的全文检索，支持中文子串匹配，毫秒级定位灵感
- **标签体系** —— 一键筛选同类笔记，标签与笔记互为入口
- **柔和羽色** —— 6 款马卡龙卡片配色随心切换，瀑布流 / 网格 / 列表三种布局
- **主题与排版** —— 亮色 / 深色 / 跟随系统，全局字体大小四档可调
- **羽记书笺** —— 把笔记生成典雅的明信片卡片，与好友分享
- **数据自主** —— 一键导出 / 导入 JSON 备份；归档与回收站防止误删
- **检查更新** —— 应用内手动或自动检测 GitHub 新版本（自动检查可在设置中关闭）

## 📦 下载安装

前往 [Releases 页面](https://github.com/e69d8e/FeatherNote/releases/latest) 下载最新版本。发布流水线只构建以下三个 Android 安装包：

| 安装包 | 适用设备 | 说明 |
| --- | --- | --- |
| `FeatherNote-Android-arm64-v8a.apk` | 绝大多数现代 64 位 Android 手机 | **推荐**，体积最小 |
| `FeatherNote-Android-armeabi-v7a.apk` | 老旧 32 位 ARM 设备 | 兼容性优先 |
| `FeatherNote-Android-Universal.apk` | 全部架构（含 x86_64 模拟器） | 通用包，体积稍大 |

> iOS / Windows / macOS / Linux / Web 版本不再随 Releases 发布，如需使用请参考下方「从源码构建」在本地自行编译。

## 🚀 从源码构建

```sh
# 1. 安装依赖
flutter pub get

# 2. 生成 Drift 数据库代码 (schema 变更后需重新执行)
dart run build_runner build --delete-conflicting-outputs

# 3. 本地运行 (-d macos / windows / linux / chrome ...)
flutter run -d macos

# 4. 构建发布包
flutter build apk --release        # Android
flutter build macos --release      # macOS
flutter build web --release        # Web
```

质量检查：

```sh
flutter analyze    # 静态分析
flutter test       # 单元与组件测试
```

## 🏗️ 技术栈与架构

| 模块 | 选型 |
| --- | --- |
| 框架 | Flutter (Material 3) |
| 状态管理 | Riverpod |
| 本地存储 | Drift (SQLite) + FTS5 全文索引 |
| 路由 | go_router |
| Markdown 渲染 | flutter_markdown_plus |

采用 feature-first 分层架构：`lib/core/` 放置数据库、路由、主题等共享基础设施，`lib/features/<feature>/` 按功能域划分为 `domain`（模型与仓储接口）/ `data`（Drift 与偏好存储实现）/ `presentation`（页面、控制器、组件）。UI 只依赖领域抽象，仓储通过 Riverpod Provider 注入，便于替换存储实现与单元测试。

## 🔒 隐私说明

羽记不收集任何数据：笔记内容仅存储在本地 SQLite 数据库中，应用没有账号体系与分析上报。唯一的联网行为是可选的「检查更新」（请求 GitHub Releases API 查询最新版本号），你可以在「设置 → 关于羽记」中关闭自动检查，或完全不使用该功能。

## 📝 更新日志

查看 [Releases](https://github.com/e69d8e/FeatherNote/releases) 了解每个版本的更新内容。
