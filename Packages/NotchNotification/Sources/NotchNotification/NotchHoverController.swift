import Cocoa
import SwiftUI

public struct NotchHoverConfiguration: Sendable {
    public var minWidth: CGFloat
    public var minWidthExtra: CGFloat
    public var heightMultiplier: CGFloat
    public var animated: Bool

    public init(
        minWidth: CGFloat = 220,
        minWidthExtra: CGFloat = 40,
        heightMultiplier: CGFloat = 2,
        animated: Bool = true
    ) {
        self.minWidth = minWidth
        self.minWidthExtra = minWidthExtra
        self.heightMultiplier = heightMultiplier
        self.animated = animated
    }
}

public final class NotchHoverController {
    private let configuration: NotchHoverConfiguration
    private var viewModel: NotchViewModel?
    private var windowController: NotchWindowController?
    private var screen: NSScreen?

    public init(configuration: NotchHoverConfiguration = .init()) {
        self.configuration = configuration
    }

    public var isVisible: Bool {
        viewModel?.status == .opened
    }

    public func show(
        on screen: NSScreen,
        leadingView: some View = EmptyView(),
        trailingView: some View = EmptyView(),
        bodyView: some View
    ) {
        if let currentScreen = self.screen, currentScreen == screen, isVisible {
            return
        }

        destroyCurrent()
        self.screen = screen

        let headerHeight = screen.headerHeight
        let menuBarHeight = NSStatusBar.system.thickness
        let targetHeight = max(menuBarHeight * configuration.heightMultiplier, headerHeight)

        let notchWidth = screen.notchSize.width
        let widenedNotchWidth = notchWidth * 1.25
        let minWidth = max(configuration.minWidth, notchWidth + configuration.minWidthExtra, widenedNotchWidth)
        let bodyMinWidth = max(minWidth - 32, 0)
        let bodyMinHeight = max(targetHeight - headerHeight - 16, 0)

        let wrappedBody = NotchHoverBodyView(
            minWidth: bodyMinWidth,
            minHeight: bodyMinHeight,
            content: bodyView
        )

        let viewModel = NotchViewModel(
            screen: screen,
            headerLeadingView: AnyView(leadingView),
            headerTrailingView: AnyView(trailingView),
            bodyView: AnyView(wrappedBody),
            animated: configuration.animated
        )

        let view = NotchView(vm: viewModel)
        let viewController = NotchViewController(view)
        let windowController = NotchWindowController(screen: screen)
        windowController.contentViewController = viewController

        let shadowInset: CGFloat = 50
        let topRect = CGRect(
            x: screen.frame.origin.x,
            y: screen.frame.origin.y + screen.frame.height - viewModel.notchOpenedSize.height - shadowInset,
            width: screen.frame.width,
            height: viewModel.notchOpenedSize.height + shadowInset
        )
        windowController.window?.setFrameOrigin(topRect.origin)
        windowController.window?.setContentSize(topRect.size)
        windowController.window?.orderFront(nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            viewModel.open()
        }

        viewModel.referencedWindow = windowController

        self.viewModel = viewModel
        self.windowController = windowController
    }

    public func hide() {
        guard let viewModel else { return }
        viewModel.close()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak viewModel] in
            viewModel?.destroyMemory()
        }
        self.viewModel = nil
        self.windowController = nil
        self.screen = nil
    }

    public func updateScreenIfNeeded(_ screen: NSScreen) {
        guard let currentScreen = self.screen else { return }
        if currentScreen != screen {
            hide()
        }
    }

    public func contains(_ point: NSPoint) -> Bool {
        guard let frame = notchFrame else { return false }
        return frame.contains(point)
    }

    public var notchFrame: NSRect? {
        guard let screen, let viewModel else { return nil }
        let notchWidth = viewModel.notchOpenedSize.width + viewModel.cornerRadius * 2
        let notchHeight = viewModel.notchOpenedSize.height
        let originX = screen.frame.midX - (notchWidth / 2)
        let originY = screen.frame.maxY - notchHeight
        return NSRect(x: originX, y: originY, width: notchWidth, height: notchHeight)
    }

    private func destroyCurrent() {
        viewModel?.destroyMemory()
        viewModel = nil
        windowController = nil
        screen = nil
    }
}

private struct NotchHoverBodyView<Content: View>: View {
    let minWidth: CGFloat
    let minHeight: CGFloat
    let content: Content

    init(minWidth: CGFloat, minHeight: CGFloat, content: Content) {
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.content = content
    }

    var body: some View {
        content
            .frame(minWidth: minWidth, minHeight: minHeight, alignment: .center)
    }
}
