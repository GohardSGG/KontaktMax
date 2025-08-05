# CLAUDE.md

此文件为 Claude Code (claude.ai/code) 在此代码库中工作时提供指导。

## 项目概述

KontaktMax 是一个基于 Tauri 的桌面应用程序，用于管理 Native Instruments Kontakt 音色库。它通过读取 Windows 注册表项来提供查看、管理和组织 Kontakt 音色库的图形界面。

## 架构

**前端**: TypeScript + Vite + HTML/CSS
- 主入口: `src/main.ts` - 处理 UI 交互、音色库列表和详情显示
- 样式: `src/styles.css` - 应用程序界面的自定义 CSS
- HTML: `index.html` - 单页应用程序布局

**后端**: Rust (Tauri)
- 主逻辑: `src-tauri/src/lib.rs` - 核心应用逻辑、注册表访问和 Tauri 命令
- 入口点: `src-tauri/src/main.rs` - 简单入口点，调用 lib.rs::run()
- 配置: Native Instruments 音色库的注册表读取逻辑
- 黑名单过滤: `src-tauri/blacklist.json` - 排除插件和不需要的注册表项

**关键组件**:
- **音色库扫描器**: 读取 Windows 注册表 (HKLM/HKCU) 中的 Native Instruments 音色库
- **系统托盘应用**: 具有自动启动功能的系统托盘
- **注册表详情**: 显示音色库路径和内容目录

## 开发命令

```bash
# 开发模式（同时启动前端和后端）
npm run dev

# 构建应用程序
npm run build

# 构建 TypeScript
tsc

# 预览构建的应用程序
npm run preview

# Tauri 命令
npm run tauri dev    # 开发模式
npm run tauri build  # 生产构建
```

## 关键数据结构

- `LibraryInfo`: 基本音色库信息（名称、类型、注册状态）
- `LibraryDetails`: 详细音色库信息，包括路径和内容目录
- `LibraryQueryResult`: 音色库集合及计数
- `AppConfig`: 应用程序设置（auto_start、silent_start）

## 注册表集成

应用程序从以下 Windows 注册表路径读取：
- `HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Native Instruments`
- `HKEY_LOCAL_MACHINE\SOFTWARE\Native Instruments`
- `HKEY_CURRENT_USER\SOFTWARE\Native Instruments`

通过存在 `ContentDir` 值且不存在特定插件注册表项（通过 blacklist.json 过滤）来检测音色库。

## 前后端通信

Tauri 命令（从 TypeScript 调用）:
- `get_installed_libraries()`: 返回所有检测到的音色库
- `get_library_details(name: string)`: 返回特定音色库的详细信息
- `get_config()`: 返回应用程序配置
- `set_auto_start(enabled: bool)`: 切换自动启动
- `set_silent_start(enabled: bool)`: 切换静默启动
- `save_config()`: 持久化配置

## 构建和分发

应用程序面向 Windows 平台，使用 Tauri 的打包系统。图标存储在 `src-tauri/icons/` 目录中。构建过程编译 Rust 后端并将其与 Vite 构建的前端打包在一起。