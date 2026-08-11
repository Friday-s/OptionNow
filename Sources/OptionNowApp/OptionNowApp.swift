import AppKit
import SwiftUI

@main
struct OptionNowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

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

        workspaceController = workspace
        settingsWindowController = settingsWindow
        self.executor = executor
        overlayController = overlay

        let hotKey = HotKeyManager { [weak self] in self?.toggleLauncher() }
        hotKey.register()
        hotKeyManager = hotKey

        overlay.show()
    }

    func toggleLauncher() {
        overlayController?.toggle()
    }

    func showSettings() {
        overlayController?.hide()
        settingsWindowController?.show()
    }
}
