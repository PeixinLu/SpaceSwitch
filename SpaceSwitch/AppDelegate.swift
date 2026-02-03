import Cocoa
import ApplicationServices

class CustomButtonView: NSView {
    weak var target: AnyObject?
    var action: Selector?
    var menuToDisplay: NSMenu?
    var buttonImage: NSImage?

    init(target: AnyObject?, action: Selector?, image: NSImage?, menu: NSMenu?) {
        let height = NSStatusBar.system.thickness
        let width: CGFloat = 24.0
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: height))
        self.target = target
        self.action = action
        self.buttonImage = image
        self.menuToDisplay = menu
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if let image = buttonImage {
            let imageSize: CGFloat = 18.0
            let rect = NSMakeRect(
                (bounds.width - imageSize) / 2,
                (bounds.height - imageSize) / 2,
                imageSize,
                imageSize
            )
            image.draw(in: rect)
        }
    }

    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.control) {
            showMenu()
            return
        }
        if let target = target, let action = action {
            NSApp.sendAction(action, to: target, from: self)
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        showMenu()
    }

    func showMenu() {
        if let menu = menuToDisplay {
            menu.popUp(
                positioning: nil,
                at: NSPoint(x: 0, y: bounds.height),
                in: self
            )
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private enum DefaultsKey {
        static let showMenuBarButtons = "showMenuBarButtons"
        static let hoverShowDelay = "hoverShowDelay"
        static let hoverHideDelay = "hoverHideDelay"
    }

    private let statusBar = NSStatusBar.system

    var statusItemOne: NSStatusItem!
    var statusItemTwo: NSStatusItem!
    var statusItemThree: NSStatusItem!
    var notchCoordinator: NotchHoverCoordinator?
    var hoverDetector: HoverDetector?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        UserDefaults.standard.register(defaults: [
            DefaultsKey.showMenuBarButtons: false,
            DefaultsKey.hoverShowDelay: 0,
            DefaultsKey.hoverHideDelay: 0.08
        ])

        setupStatusItemTwo()
        setupStatusItemThree()
        setupStatusItemOne()
        setupNotchTrigger()

        applySettings()
        if !UserDefaults.standard.bool(forKey: DefaultsKey.showMenuBarButtons) {
            SettingsWindowController.shared.show()
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDefaultsChanged),
            name: .settingsDidChange,
            object: nil
        )

        print("注意: 脚本执行需要 '系统设置' -> '隐私与安全性' -> '辅助功能' 中授予本应用权限。")
    }

    func setupStatusItemOne() {
        statusItemOne = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        let quitMenu = setupQuitMenu()
        let image = NSImage(systemSymbolName: "arrow.left", accessibilityDescription: "Switch Left Desktop")
        let customView = CustomButtonView(
            target: self,
            action: #selector(switchToDesktopLeft),
            image: image,
            menu: quitMenu
        )
        statusItemOne.view = customView
    }

    func setupStatusItemTwo() {
        statusItemTwo = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        let quitMenu = setupQuitMenu()
        let image = NSImage(systemSymbolName: "arrow.right", accessibilityDescription: "Switch Right Desktop")
        let customView = CustomButtonView(
            target: self,
            action: #selector(switchToDesktopRight),
            image: image,
            menu: quitMenu
        )
        statusItemTwo.view = customView
    }

    func setupStatusItemThree() {
        statusItemThree = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        let quitMenu = setupQuitMenu()
        let image = NSImage(systemSymbolName: "rectangle.3.group", accessibilityDescription: "Show Mission Control")
        let customView = CustomButtonView(
            target: self,
            action: #selector(showMissionControl),
            image: image,
            menu: quitMenu
        )
        statusItemThree.view = customView
    }

    func setupQuitMenu() -> NSMenu {
        let menu = NSMenu()
        let settingsItem = NSMenuItem(title: "设置…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "退出应用", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        menu.addItem(quitItem)
        return menu
    }

    func setupNotchTrigger() {
        let defaults = UserDefaults.standard
        let coordinator = NotchHoverCoordinator(
            triggerWidthRatio: 0.15,
            showDelay: defaults.double(forKey: DefaultsKey.hoverShowDelay),
            hideDelay: defaults.double(forKey: DefaultsKey.hoverHideDelay),
            onLeft: { [weak self] in
                self?.switchToDesktopLeft()
            },
            onRight: { [weak self] in
                self?.switchToDesktopRight()
            },
            onMission: { [weak self] in
                self?.showMissionControl()
            }
        )
        notchCoordinator = coordinator
        hoverDetector = HoverDetector { [weak coordinator] point in
            coordinator?.handleMouseMoved(point)
        }
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }

    @objc private func handleDefaultsChanged() {
        applySettings()
    }

    private func applySettings() {
        let defaults = UserDefaults.standard
        let showButtons = defaults.bool(forKey: DefaultsKey.showMenuBarButtons)
        setMenuBarButtonsVisible(showButtons)
        notchCoordinator?.updateDelays(
            show: defaults.double(forKey: DefaultsKey.hoverShowDelay),
            hide: defaults.double(forKey: DefaultsKey.hoverHideDelay)
        )
    }

    private func setMenuBarButtonsVisible(_ visible: Bool) {
        if visible {
            if statusItemTwo == nil { setupStatusItemTwo() }
            if statusItemThree == nil { setupStatusItemThree() }
            if statusItemOne == nil { setupStatusItemOne() }
            statusItemOne?.isVisible = true
            statusItemTwo?.isVisible = true
            statusItemThree?.isVisible = true
        } else {
            if let item = statusItemOne {
                statusBar.removeStatusItem(item)
                statusItemOne = nil
            }
            if let item = statusItemTwo {
                statusBar.removeStatusItem(item)
                statusItemTwo = nil
            }
            if let item = statusItemThree {
                statusBar.removeStatusItem(item)
                statusItemThree = nil
            }
        }
    }

    @objc func switchToDesktopLeft() {
        print("尝试执行脚本：切换到左侧桌面 (Control + Left Arrow)")
        executeScript(keyCode: 123, modifier: "control")
    }

    @objc func switchToDesktopRight() {
        print("尝试执行脚本：切换到右侧桌面 (Control + Right Arrow)")
        executeScript(keyCode: 124, modifier: "control")
    }

    @objc func showMissionControl() {
        print("尝试执行脚本：显示 Mission Control (Control + Up Arrow)")
        executeScript(keyCode: 126, modifier: "control")
        notchCoordinator?.hideImmediately()
    }

    func checkAccessibilityPermission() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString: true]
        let isTrusted = AXIsProcessTrustedWithOptions(options)
        if isTrusted {
            print("辅助功能权限已授予。")
        } else {
            print("辅助功能权限缺失。已触发 macOS 系统原生申请弹窗。")
        }
        return isTrusted
    }

    func executeScript(keyCode: Int, modifier: String) {
        if !checkAccessibilityPermission() {
            print("脚本执行中止：缺少辅助功能权限。")
            return
        }

        let appleScript: String = """
            tell application "System Events"
                key code \(keyCode) using \(modifier) down
            end tell
            """

        var error: NSDictionary?
        if let script = NSAppleScript(source: appleScript) {
            script.executeAndReturnError(&error)
            if let error = error {
                print("脚本执行错误: \(error)")
                if error["NSAppleScriptErrorNumber"] as? Int == -600 {
                    print("--> 错误提示: 虽然权限已授予，但 System Events 仍无法响应。请确保您运行的是已构建且已授权的 .app 文件，而不是直接从 Xcode 临时目录启动。")
                } else if error["NSAppleScriptErrorNumber"] as? Int == -1743 {
                    print("--> 错误提示: 缺少自动化 (Automation) 权限。请在 Info.plist (Privacy - AppleEvents Sending Usage Description) 中添加描述并检查 '系统设置' -> '隐私与安全性' -> '自动化' 中是否已授权。")
                }
            } else {
                print("key code \(keyCode) using \(modifier) down 执行成功。")
            }
        }
    }
}
