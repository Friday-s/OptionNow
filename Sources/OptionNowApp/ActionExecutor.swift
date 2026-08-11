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

    private func openExternalApplication(_ item: ToolItem) {
        guard let path = item.applicationPath, !path.isEmpty else {
            presentMissingTarget(for: item)
            return
        }

        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: path) else {
            presentMissingTarget(for: item)
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { [weak self] _, error in
            Task { @MainActor in
                if error == nil {
                    self?.settings.record(item)
                    self?.showExternalPanelIfSupported(item)
                } else {
                    self?.presentError("无法打开 \(item.name)")
                }
            }
        }
    }

    private func showExternalPanelIfSupported(_ item: ToolItem) {
        guard item.name.localizedCaseInsensitiveContains("orbit") else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            DistributedNotificationCenter.default().postNotificationName(
                Notification.Name("com.ivor.workbench-orbit.show-panel"),
                object: nil,
                userInfo: nil,
                deliverImmediately: true
            )
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
