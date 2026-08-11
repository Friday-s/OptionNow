import AppKit
import Foundation

struct ApplicationIntegration: Equatable {
    let id: String
    let displayName: String
    let bundleIdentifier: String
    let standardApplicationName: String
    let showPanelNotification: Notification.Name?

    static let known: [ApplicationIntegration] = [
        ApplicationIntegration(
            id: "orbit",
            displayName: "Orbit",
            bundleIdentifier: "com.ivor.workbench-orbit",
            standardApplicationName: "Orbit",
            showPanelNotification: Notification.Name("com.ivor.workbench-orbit.show-panel")
        ),
        ApplicationIntegration(
            id: "sendlingo",
            displayName: "SendLingo",
            bundleIdentifier: "com.ivor.sendlingo",
            standardApplicationName: "SendLingo",
            showPanelNotification: Notification.Name("com.ivor.sendlingo.show-panel")
        ),
        ApplicationIntegration(
            id: "clipmate",
            displayName: "ClipMate",
            bundleIdentifier: "com.ivor.clipmate",
            standardApplicationName: "ClipMate",
            showPanelNotification: nil
        )
    ]

    static func matching(_ item: ToolItem) -> ApplicationIntegration? {
        if let integrationID = item.integrationID,
           let match = known.first(where: { $0.id == integrationID }) {
            return match
        }
        return known.first {
            item.name.localizedCaseInsensitiveContains($0.displayName)
        }
    }

    func resolveURL(savedPath: String?) -> URL? {
        if let savedPath, FileManager.default.fileExists(atPath: savedPath) {
            return URL(fileURLWithPath: savedPath)
        }
        if let located = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            return located
        }
        let standard = URL(fileURLWithPath: "/Applications/\(standardApplicationName).app")
        return FileManager.default.fileExists(atPath: standard.path) ? standard : nil
    }

    var runningApplication: NSRunningApplication? {
        NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first
    }

    func revealPanel() {
        if let showPanelNotification {
            for delay in [0.15, 0.55] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    DistributedNotificationCenter.default().postNotificationName(
                        showPanelNotification,
                        object: nil,
                        userInfo: nil,
                        deliverImmediately: true
                    )
                }
            }
        } else {
            runningApplication?.activate(options: [.activateAllWindows])
        }
    }
}
