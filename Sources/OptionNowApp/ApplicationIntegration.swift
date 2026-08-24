import AppKit
import CoreGraphics
import Foundation

struct ApplicationIntegration: Equatable {
    let id: String
    let displayName: String
    let bundleIdentifier: String
    let standardApplicationName: String
    let showPanelNotification: Notification.Name?
    let hidePanelNotification: Notification.Name?
    let terminateWhenClosing: Bool

    static let known: [ApplicationIntegration] = [
        ApplicationIntegration(
            id: "orbit",
            displayName: "Orbit",
            bundleIdentifier: "com.ivor.workbench-orbit",
            standardApplicationName: "Orbit",
            showPanelNotification: Notification.Name("com.ivor.workbench-orbit.show-panel"),
            hidePanelNotification: Notification.Name("com.ivor.workbench-orbit.hide-panel"),
            terminateWhenClosing: false
        ),
        ApplicationIntegration(
            id: "sendlingo",
            displayName: "SendLingo",
            bundleIdentifier: "com.ivor.sendlingo",
            standardApplicationName: "SendLingo",
            showPanelNotification: Notification.Name("com.ivor.sendlingo.show-panel"),
            hidePanelNotification: Notification.Name("com.ivor.sendlingo.hide-panel"),
            terminateWhenClosing: false
        ),
        ApplicationIntegration(
            id: "clipmate",
            displayName: "ClipMate",
            bundleIdentifier: "com.ivor.clipmate",
            standardApplicationName: "ClipMate",
            showPanelNotification: nil,
            hidePanelNotification: nil,
            terminateWhenClosing: true
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

    var isPanelVisible: Bool {
        guard let runningApplication else { return false }
        return Self.hasVisibleWindow(for: runningApplication)
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

    func hidePanel() {
        if terminateWhenClosing {
            runningApplication?.terminate()
        } else if let hidePanelNotification {
            DistributedNotificationCenter.default().postNotificationName(
                hidePanelNotification,
                object: nil,
                userInfo: nil,
                deliverImmediately: true
            )
        } else {
            runningApplication?.hide()
        }
    }

    func terminateHiddenInstance() async {
        guard terminateWhenClosing else { return }
        for application in NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier) {
            application.terminate()
        }
        if await waitUntilTerminated(timeout: 2) { return }
        for application in NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier) {
            application.forceTerminate()
        }
        _ = await waitUntilTerminated(timeout: 1)
    }

    private func waitUntilTerminated(timeout: TimeInterval) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if runningApplication == nil { return true }
            try? await Task.sleep(for: .milliseconds(100))
        }
        return runningApplication == nil
    }

    static func hasVisibleWindow(for application: NSRunningApplication) -> Bool {
        guard let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else {
            return false
        }
        return windows.contains { window in
            guard let ownerPID = window[kCGWindowOwnerPID as String] as? NSNumber,
                  ownerPID.int32Value == application.processIdentifier,
                  let bounds = window[kCGWindowBounds as String] as? [String: Any],
                  let width = bounds["Width"] as? NSNumber,
                  let height = bounds["Height"] as? NSNumber,
                  let alpha = window[kCGWindowAlpha as String] as? NSNumber else { return false }
            return width.doubleValue > 100 && height.doubleValue > 100 && alpha.doubleValue > 0
        }
    }
}
