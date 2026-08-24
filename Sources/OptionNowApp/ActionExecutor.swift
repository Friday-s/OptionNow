import AppKit
import Foundation

@MainActor
final class ActionExecutor {
    weak var overlayController: OverlayPanelController?
    let workspaceController: WorkspaceWindowController
    let settingsWindowController: SettingsWindowController
    let settings: SettingsStore

    init(
        settings: SettingsStore,
        workspaceController: WorkspaceWindowController,
        settingsWindowController: SettingsWindowController
    ) {
        self.settings = settings
        self.workspaceController = workspaceController
        self.settingsWindowController = settingsWindowController
    }

    func execute(_ item: ToolItem) {
        overlayController?.hide()

        switch item.kind {
        case .externalApplication:
            openExternalApplication(item)
        case .files:
            openFinder(item)
        case .folder:
            openFolder(item)
        case .url:
            openURL(item)
        case .recents:
            workspaceController.showRecents()
        case .settings:
            settingsWindowController.show()
        }
    }

    private func openFinder(_ item: ToolItem) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        if NSWorkspace.shared.open(home) {
            settings.record(item)
        } else {
            presentError("无法打开访达")
        }
    }

    private func openFolder(_ item: ToolItem) {
        guard let path = item.applicationPath,
              FileManager.default.fileExists(atPath: path),
              NSWorkspace.shared.open(URL(fileURLWithPath: path)) else {
            presentMissingTarget(for: item)
            return
        }
        settings.record(item)
    }

    private func openURL(_ item: ToolItem) {
        guard let value = item.applicationPath,
              let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              NSWorkspace.shared.open(url) else {
            presentError("无法打开链接")
            return
        }
        settings.record(item)
    }

    private func openExternalApplication(_ item: ToolItem) {
        let integration = ApplicationIntegration.matching(item)
        let resolvedURL = integration?.resolveURL(savedPath: item.applicationPath)
            ?? item.applicationPath.map(URL.init(fileURLWithPath:))

        guard let url = resolvedURL else {
            presentMissingTarget(for: item)
            return
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            presentMissingTarget(for: item)
            return
        }

        if let integration, integration.isPanelVisible {
            integration.hidePanel()
            return
        }
        if integration == nil,
           let bundleIdentifier = Bundle(url: url)?.bundleIdentifier,
           let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first,
           ApplicationIntegration.hasVisibleWindow(for: running) {
            running.hide()
            return
        }

        if let integration,
           integration.terminateWhenClosing,
           integration.runningApplication != nil {
            Task { [weak self] in
                await integration.terminateHiddenInstance()
                self?.launchApplication(at: url, item: item, integration: integration)
            }
            return
        }

        launchApplication(at: url, item: item, integration: integration)
    }

    private func launchApplication(
        at url: URL,
        item: ToolItem,
        integration: ApplicationIntegration?
    ) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { [weak self] _, error in
            Task { @MainActor in
                if error == nil {
                    self?.settings.record(item)
                    integration?.revealPanel()
                } else {
                    self?.presentError("无法打开 \(item.name)")
                }
            }
        }
    }

    private func presentMissingTarget(for item: ToolItem) {
        settings.configurationMessage = "尚未绑定 \(item.name)。请选择它的 .app 文件后再试。"
        settingsWindowController.show()
    }

    private func presentError(_ message: String) {
        settings.configurationMessage = "\(message)。请重新选择应用后再试。"
        settingsWindowController.show()
    }
}
