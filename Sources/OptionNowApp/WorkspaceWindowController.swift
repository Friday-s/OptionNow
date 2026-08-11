import AppKit
import SwiftUI

@MainActor
final class WorkspaceWindowController: NSWindowController {
    private let settings: SettingsStore
    var onSelectRecent: ((ToolItem) -> Void)?

    init(settings: SettingsStore) {
        self.settings = settings
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "OptionNow"
        window.minSize = NSSize(width: 620, height: 420)
        window.center()
        super.init(window: window)
    }

    required init?(coder: NSCoder) { nil }

    func showRecents() {
        guard let window else { return }
        window.title = "OptionNow — 最近使用"
        window.contentView = NSHostingView(
            rootView: RecentsView(
                settings: settings,
                onSelect: { [weak self] item in
                    self?.window?.orderOut(nil)
                    self?.onSelectRecent?(item)
                }
            )
        )
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}

private struct RecentsView: View {
    @ObservedObject var settings: SettingsStore
    let onSelect: (ToolItem) -> Void

    var body: some View {
        Group {
            if settings.recentActions.isEmpty {
                ContentUnavailableView("暂无最近使用", systemImage: "clock")
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button("清空") { settings.clearRecents() }
                    }
                    .padding(.horizontal)
                    List(settings.recentActions) { action in
                        Button { onSelect(action.item) } label: {
                            HStack {
                                Image(systemName: action.item.symbol)
                                Text(action.name)
                                Spacer()
                                Text(action.date, style: .relative)
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(minWidth: 520, minHeight: 360)
    }
}
