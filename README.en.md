<p align="center">
  <img src="SpaceSwitch/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width="96" height="96" alt="SpaceSwitch">
</p>
<h1 align="center">SpaceSwitch</h1>
<p align="center"><a href="README.md">中文</a></p>

## Purpose
SpaceSwitch is a menu bar and notch-triggered desktop switcher for macOS:
- Switch to the left/right desktop
- Open Mission Control
- Notch hover panel for quick actions

## How It Works
- Uses macOS Accessibility permission and AppleScript to send keyboard events via System Events
- Provides NSStatusItem buttons in the menu bar
- Uses NotchNotification to render a notch hover panel

## Compatibility
- Recommended macOS 12 or later (depends on NotchNotification and LaunchAtLogin-Modern)

## Install
1. Download the latest DMG from [GitHub Releases](https://github.com/PeixinLu/SpaceSwitch/releases)
2. Open the DMG and drag SpaceSwitch to Applications
3. On first launch, allow it in “System Settings → Privacy & Security” if prompted
4. Grant Accessibility permission to enable desktop switching

## Build From Source
1. Clone the repository
2. Open `SpaceSwitch.xcodeproj` in Xcode
3. Select the `SpaceSwitch` scheme and build

To build a DMG:
```bash
brew install create-dmg
./scripts/build_dmg.sh
```

## Acknowledgements
- NotchNotification: https://github.com/Lakr233/NotchNotification
- LaunchAtLogin-Modern: https://github.com/sindresorhus/LaunchAtLogin-Modern
- create-dmg: https://github.com/create-dmg/create-dmg

## License
This project is licensed under the MIT License. See `LICENSE`. Third-party libraries follow their own licenses.
