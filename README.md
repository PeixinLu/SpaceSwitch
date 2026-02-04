<p align="center">
  <img src="SpaceSwitch/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width="96" height="96" alt="SpaceSwitch">
</p>
<h1 align="center">SpaceSwitch</h1>
<p align="center"><a href="README.en.md">English</a></p>

## 用途
SpaceSwitch 是一个菜单栏与刘海触发结合的桌面切换工具，提供以下能力：
- 一键切换到左/右侧桌面
- 一键打开 Mission Control
- 支持在刘海区域悬停触发面板

## 实现原理
- 使用 macOS Accessibility 权限调用 AppleScript，通过 System Events 发送键盘事件
- 通过 NSStatusItem 在菜单栏提供按钮
- 通过 NotchNotification 在刘海区域显示悬浮按钮

## 兼容性
- 推荐 macOS 12 或更高版本（依赖 NotchNotification 与 LaunchAtLogin-Modern）

## 下载安装
1. 前往 [GitHub Releases](https://github.com/PeixinLu/SpaceSwitch/releases) 下载最新的 DMG
2. 打开 DMG，将 SpaceSwitch 拖动到 Applications
3. 首次打开可能会被系统拦截，需在“系统设置 → 隐私与安全性”中允许打开
4. 首次使用会触发辅助功能权限弹窗，请授予权限以启用桌面切换

## 从源码构建
1. 克隆仓库
2. 使用 Xcode 打开 `SpaceSwitch.xcodeproj`
3. 选择 `SpaceSwitch` scheme，构建运行

如需生成 DMG：
```bash
brew install create-dmg
./scripts/build_dmg.sh
```

## 鸣谢
- NotchNotification：https://github.com/Lakr233/NotchNotification
- LaunchAtLogin-Modern：https://github.com/sindresorhus/LaunchAtLogin-Modern
- create-dmg：https://github.com/create-dmg/create-dmg

## 许可
本项目使用 MIT 协议，详见 `LICENSE`。第三方库遵循其各自许可证。
