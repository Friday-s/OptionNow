import AppKit
import Combine
import SwiftUI

@main
struct OptionNowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        if CommandLine.arguments.contains("--selftest") {
            exit(OptionNowSelfTest.run())
        }
    }

    var body: some Scene {
        MenuBarExtra("OptionNow", systemImage: "circle.grid.cross") {
            Button("打开 OptionNow") { appDelegate.toggleLauncher() }
                .keyboardShortcut(" ", modifiers: .option)
            Divider()
            Button("设置…") { appDelegate.showSettings() }
            Divider()
            Button("退出 OptionNow") { NSApp.terminate(nil) }
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotKeyManager: HotKeyManager?
    private var overlayController: OverlayPanelController?
    private var workspaceController: WorkspaceWindowController?
    private var settingsWindowController: SettingsWindowController?
    private var executor: ActionExecutor?
    private var hotKeyCancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let settings = SettingsStore.shared
        let workspace = WorkspaceWindowController(settings: settings)
        let settingsWindow = SettingsWindowController(settings: settings)
        let executor = ActionExecutor(
            settings: settings,
            workspaceController: workspace,
            settingsWindowController: settingsWindow
        )
        let overlay = OverlayPanelController(settings: settings, executor: executor)
        executor.overlayController = overlay
        workspace.onSelectRecent = { [weak executor] item in executor?.execute(item) }

        workspaceController = workspace
        settingsWindowController = settingsWindow
        self.executor = executor
        overlayController = overlay

        let hotKey = HotKeyManager(
            onPressed: { [weak overlay, weak settings] in
                if settings?.releaseToSelect == true {
                    overlay?.show()
                } else {
                    overlay?.toggle()
                }
            },
            onReleased: { [weak overlay, weak settings] in
                if settings?.releaseToSelect == true {
                    overlay?.executeHighlightedOrHide()
                }
            }
        )
        settings.hotKeyConflict = !hotKey.register(settings.hotKey)
        hotKeyManager = hotKey
        hotKeyCancellable = settings.$hotKey.dropFirst().sink { [weak hotKey, weak settings] newValue in
            let succeeded = hotKey?.register(newValue) ?? false
            settings?.hotKeyConflict = !succeeded
            if !succeeded {
                settings?.configurationMessage = "快捷键 \(newValue.displayName) 已被其他应用占用，原快捷键仍然有效。"
            }
        }

        if CommandLine.arguments.contains("--show") {
            overlay.show()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        overlayController?.show()
        return true
    }

    func toggleLauncher() {
        overlayController?.toggle()
    }

    func showSettings() {
        overlayController?.hide()
        settingsWindowController?.show()
    }
}
