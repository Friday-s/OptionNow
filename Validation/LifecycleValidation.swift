import AppKit
import CoreGraphics
import Foundation

private struct ApplicationSpec {
    let name: String
    let bundleIdentifier: String
    let showNotification: Notification.Name?
    let hideNotification: Notification.Name?
    let terminateWhenHiding: Bool
}

@main
struct LifecycleValidation {
    private static let specs = [
        ApplicationSpec(
            name: "Orbit",
            bundleIdentifier: "com.ivor.workbench-orbit",
            showNotification: Notification.Name("com.ivor.workbench-orbit.show-panel"),
            hideNotification: Notification.Name("com.ivor.workbench-orbit.hide-panel"),
            terminateWhenHiding: false
        ),
        ApplicationSpec(
            name: "SendLingo",
            bundleIdentifier: "com.ivor.sendlingo",
            showNotification: Notification.Name("com.ivor.sendlingo.show-panel"),
            hideNotification: Notification.Name("com.ivor.sendlingo.hide-panel"),
            terminateWhenHiding: false
        ),
        ApplicationSpec(
            name: "ClipMate",
            bundleIdentifier: "com.ivor.clipmate",
            showNotification: nil,
            hideNotification: nil,
            terminateWhenHiding: true
        )
    ]

    static func main() async {
        var failures = 0
        for spec in specs {
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: spec.bundleIdentifier) else {
                print("FAIL: \(spec.name) 未安装或未注册")
                failures += 1
                continue
            }

            await terminate(spec)
            if running(spec) != nil {
                print("FAIL: \(spec.name) 无法关闭")
                failures += 1
                continue
            }
            print("PASS: \(spec.name) 已关闭")

            do {
                try await launch(url)
            } catch {
                print("FAIL: \(spec.name) 冷启动失败 — \(error.localizedDescription)")
                failures += 1
                continue
            }
            guard await waitUntil({ running(spec) != nil }) else {
                print("FAIL: \(spec.name) 冷启动后没有进程")
                failures += 1
                continue
            }
            print("PASS: \(spec.name) 冷启动成功")

            NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first?
                .activate(options: [.activateAllWindows])
            await reveal(spec)
            let visible = await waitUntil { hasVisibleWindow(spec) }
            print("\(visible ? "PASS" : "FAIL"): \(spec.name) 从其他窗口切回并显示")
            if !visible { failures += 1 }

            await hide(spec)
            let hidden = if spec.terminateWhenHiding {
                await waitUntil { running(spec) == nil }
            } else {
                await waitUntil { !hasVisibleWindow(spec) }
            }
            print("\(hidden ? "PASS" : "FAIL"): \(spec.name) 再次点击后关闭窗口")
            if !hidden { failures += 1 }

            if running(spec) == nil {
                do { try await launch(url) }
                catch {
                    print("FAIL: \(spec.name) 关闭后再次启动失败 — \(error.localizedDescription)")
                    failures += 1
                }
            }
            await reveal(spec)
            let shownAgain = await waitUntil { hasVisibleWindow(spec) }
            print("\(shownAgain ? "PASS" : "FAIL"): \(spec.name) 关闭后再次显示")
            if !shownAgain { failures += 1 }

            await terminate(spec)
            do {
                try await launch(url)
                await reveal(spec)
            } catch {
                print("FAIL: \(spec.name) 关闭后重开失败 — \(error.localizedDescription)")
                failures += 1
                continue
            }
            let reopened = await waitUntil { running(spec) != nil && hasVisibleWindow(spec) }
            print("\(reopened ? "PASS" : "FAIL"): \(spec.name) 关闭后重开")
            if !reopened { failures += 1 }
        }

        print("LIFECYCLE RESULT: \(failures == 0 ? "PASS" : "FAIL") (\(failures) failures)")
        exit(failures == 0 ? 0 : 1)
    }

    private static func running(_ spec: ApplicationSpec) -> NSRunningApplication? {
        NSRunningApplication.runningApplications(withBundleIdentifier: spec.bundleIdentifier).first
    }

    private static func terminate(_ spec: ApplicationSpec) async {
        for app in NSRunningApplication.runningApplications(withBundleIdentifier: spec.bundleIdentifier) {
            app.terminate()
        }
        if await waitUntil({ running(spec) == nil }, timeout: 3) { return }
        for app in NSRunningApplication.runningApplications(withBundleIdentifier: spec.bundleIdentifier) {
            app.forceTerminate()
        }
        _ = await waitUntil({ running(spec) == nil }, timeout: 2)
    }

    private static func launch(_ url: URL) async throws {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: ()) }
            }
        }
    }

    private static func reveal(_ spec: ApplicationSpec) async {
        if let notification = spec.showNotification {
            for delay in [150_000_000, 550_000_000] as [UInt64] {
                try? await Task.sleep(nanoseconds: delay)
                DistributedNotificationCenter.default().postNotificationName(
                    notification,
                    object: nil,
                    userInfo: nil,
                    deliverImmediately: true
                )
            }
        } else {
            running(spec)?.activate(options: [.activateAllWindows])
        }
    }

    private static func hide(_ spec: ApplicationSpec) async {
        if spec.terminateWhenHiding {
            running(spec)?.terminate()
        } else if let notification = spec.hideNotification {
            DistributedNotificationCenter.default().postNotificationName(
                notification,
                object: nil,
                userInfo: nil,
                deliverImmediately: true
            )
        } else {
            running(spec)?.hide()
        }
    }

    private static func hasVisibleWindow(_ spec: ApplicationSpec) -> Bool {
        guard let pid = running(spec)?.processIdentifier,
              let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else {
            return false
        }
        return windows.contains { window in
            guard let ownerPID = window[kCGWindowOwnerPID as String] as? NSNumber,
                  ownerPID.int32Value == pid,
                  let bounds = window[kCGWindowBounds as String] as? [String: Any],
                  let width = bounds["Width"] as? NSNumber,
                  let height = bounds["Height"] as? NSNumber,
                  let alpha = window[kCGWindowAlpha as String] as? NSNumber else { return false }
            return width.doubleValue > 100 && height.doubleValue > 100 && alpha.doubleValue > 0
        }
    }

    private static func waitUntil(
        _ condition: @escaping () -> Bool,
        timeout: TimeInterval = 6
    ) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        return condition()
    }
}
