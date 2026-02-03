import Cocoa
import SwiftUI
import NotchNotification

final class HoverDetector {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private let handler: (NSPoint) -> Void

    init(handler: @escaping (NSPoint) -> Void) {
        self.handler = handler
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { _ in
            handler(NSEvent.mouseLocation)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { event in
            handler(NSEvent.mouseLocation)
            return event
        }
    }

    deinit {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
    }
}

struct NotchSwitchView: View {
    let onLeft: () -> Void
    let onRight: () -> Void
    let onMission: () -> Void

    var body: some View {
        ZStack {
            HStack(spacing: 18) {
                Button(action: onLeft) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Button(action: onMission) {
                    Image(systemName: "rectangle.3.group")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Button(action: onRight) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .contextMenu {
            Button("设置…") {
                SettingsWindowController.shared.show()
            }
            Divider()
            Button("退出应用") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

final class NotchHoverCoordinator {
    private let controller: NotchHoverController
    private let triggerWidthRatio: CGFloat
    private var showDelay: TimeInterval
    private var hideDelay: TimeInterval
    private var showWorkItem: DispatchWorkItem?
    private var hideWorkItem: DispatchWorkItem?

    private let onLeft: () -> Void
    private let onRight: () -> Void
    private let onMission: () -> Void

    init(
        triggerWidthRatio: CGFloat,
        showDelay: TimeInterval,
        hideDelay: TimeInterval,
        onLeft: @escaping () -> Void,
        onRight: @escaping () -> Void,
        onMission: @escaping () -> Void
    ) {
        self.triggerWidthRatio = triggerWidthRatio
        self.showDelay = max(0, showDelay)
        self.hideDelay = max(0, hideDelay)
        self.onLeft = onLeft
        self.onRight = onRight
        self.onMission = onMission
        self.controller = NotchHoverController(
            configuration: .init(
                minWidth: 260,
                minWidthExtra: 80,
                heightMultiplier: 2,
                animated: true
            )
        )
    }

    func handleMouseMoved(_ point: NSPoint) {
        guard let screen = screenContaining(point) else { return }
        let menuBarHeight = screen.frame.maxY - screen.visibleFrame.maxY
        let menuBarYMin = screen.frame.maxY - menuBarHeight

        let inMenuBar = point.y >= menuBarYMin && point.y <= screen.frame.maxY
        let centerHalfWidth = (screen.frame.width * triggerWidthRatio) / 2
        let inCenter = abs(point.x - screen.frame.midX) <= centerHalfWidth
        let inTrigger = inMenuBar && inCenter
        let inNotch = controller.contains(point)

        if inTrigger || inNotch {
            scheduleShow(on: screen)
        } else {
            scheduleHide()
        }
    }

    func updateDelays(show: TimeInterval, hide: TimeInterval) {
        showDelay = max(0, show)
        hideDelay = max(0, hide)
    }

    func hideImmediately() {
        showWorkItem?.cancel()
        hideWorkItem?.cancel()
        controller.hide()
    }

    func showOnce(duration: TimeInterval = 1.2, on screen: NSScreen? = NSScreen.main) {
        guard let screen else { return }
        hideWorkItem?.cancel()
        showWorkItem?.cancel()
        show(on: screen)
        let workItem = DispatchWorkItem { [weak self] in
            self?.controller.hide()
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }

    private func scheduleShow(on screen: NSScreen) {
        hideWorkItem?.cancel()
        showWorkItem?.cancel()

        if controller.isVisible {
            controller.updateScreenIfNeeded(screen)
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.show(on: screen)
        }
        showWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + showDelay, execute: workItem)
    }

    private func scheduleHide() {
        showWorkItem?.cancel()
        hideWorkItem?.cancel()

        if !controller.isVisible {
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.controller.hide()
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + hideDelay, execute: workItem)
    }

    private func show(on screen: NSScreen) {
        let contentView = NotchSwitchView(onLeft: onLeft, onRight: onRight, onMission: onMission)
        controller.show(
            on: screen,
            leadingView: EmptyView(),
            trailingView: EmptyView(),
            bodyView: contentView
        )
    }

    private func screenContaining(_ point: NSPoint) -> NSScreen? {
        for screen in NSScreen.screens where screen.frame.contains(point) {
            return screen
        }
        return NSScreen.main
    }
}
