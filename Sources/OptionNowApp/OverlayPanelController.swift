import AppKit
import Carbon
import SwiftUI

private final class LauncherPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class OverlayPanelController: NSObject, NSWindowDelegate {
    private let panel: NSPanel
    private let settings: SettingsStore
    private let executor: ActionExecutor
    private let interaction = LauncherInteractionState()
    private var clickMonitor: Any?
    private var keyMonitor: Any?
    private var scrollMonitor: Any?
    private weak var previousApplication: NSRunningApplication?
    private var lastPageChange = Date.distantPast

    init(settings: SettingsStore, executor: ActionExecutor) {
        self.settings = settings
        self.executor = executor
        panel = LauncherPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 320),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        super.init()

        panel.level = .popUpMenu
        panel.isFloatingPanel = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.hidesOnDeactivate = false
        panel.delegate = self
        panel.contentView = NSHostingView(
            rootView: LauncherView(settings: settings, interaction: interaction) { [weak executor] item in
                executor?.execute(item)
            }
        )

        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                guard self?.settings.closeOnDeactivate == true else { return }
                self?.hide()
            }
        }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.panel.isVisible else { return event }
            let keyCode = Int(event.keyCode)
            let handled = MainActor.assumeIsolated { self.handleKeyDown(keyCode) }
            return handled ? nil : event
        }
        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self, self.panel.isVisible else { return event }
            let deltaY = event.scrollingDeltaY
            MainActor.assumeIsolated { self.handleScroll(deltaY: deltaY) }
            return event
        }
    }

    func toggle() {
        panel.isVisible ? hide() : show()
    }

    func show() {
        previousApplication = NSWorkspace.shared.frontmostApplication
        positionNearPointer()
        interaction.resetHighlight()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel.orderOut(nil)
        previousApplication?.activate(options: [.activateAllWindows])
    }

    func executeHighlightedOrHide() {
        guard let id = interaction.highlightedID,
              let item = settings.enabledItems.first(where: { $0.id == id }) else {
            hide()
            return
        }
        executor.execute(item)
    }

    private func positionNearPointer() {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) ?? NSScreen.main
        let visible = screen?.visibleFrame ?? .zero
        let size = panel.frame.size
        var origin: NSPoint
        if settings.launcherPosition == .screenCenter {
            origin = NSPoint(x: visible.midX - size.width / 2, y: visible.midY - size.height / 2)
        } else {
            origin = NSPoint(x: mouse.x - size.width / 2, y: mouse.y - size.height / 2)
        }
        origin.x = min(max(origin.x, visible.minX + 8), visible.maxX - size.width - 8)
        origin.y = min(max(origin.y, visible.minY + 8), visible.maxY - size.height - 8)
        panel.setFrameOrigin(origin)
    }

    private func handleKeyDown(_ keyCode: Int) -> Bool {
        switch keyCode {
        case kVK_Escape:
            hide()
        case kVK_Return, kVK_ANSI_KeypadEnter:
            executeHighlightedOrHide()
        case kVK_LeftArrow, kVK_UpArrow:
            interaction.moveSelection(in: settings.enabledItems, capacity: settings.sectorCount, delta: -1)
        case kVK_RightArrow, kVK_DownArrow:
            interaction.moveSelection(in: settings.enabledItems, capacity: settings.sectorCount, delta: 1)
        default:
            return false
        }
        return true
    }

    private func handleScroll(deltaY: CGFloat) {
        guard abs(deltaY) > 2,
              Date().timeIntervalSince(lastPageChange) > 0.25 else { return }
        lastPageChange = Date()
        interaction.changePage(
            in: settings.enabledItems,
            capacity: settings.sectorCount,
            delta: deltaY < 0 ? 1 : -1
        )
    }

    deinit {
        if let clickMonitor { NSEvent.removeMonitor(clickMonitor) }
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        if let scrollMonitor { NSEvent.removeMonitor(scrollMonitor) }
    }
}
