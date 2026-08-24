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
                ContentUnavailableView {
                    Label("暂无最近使用", systemImage: "clock")
                } description: {
                    Text("打开过的工具会出现在这里。")
                        .font(DS.Font.body())
                        .foregroundStyle(DS.Color.textSecondary)
                }
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Text("最近使用")
                            .font(DS.Font.h3())
                            .foregroundStyle(DS.Color.textPrimary)
                        Spacer(minLength: DS.Space.sm)
                        Button("清空") { settings.clearRecents() }
                            .buttonStyle(DSSecondaryButtonStyle())
                            .fixedSize()
                    }
                    .padding(.horizontal, DS.Space.lg)
                    .padding(.vertical, DS.Space.md)

                    ScrollView {
                        VStack(spacing: DS.Space.xs) {
                            ForEach(settings.recentActions) { action in
                                RecentRow(action: action) { onSelect(action.item) }
                            }
                        }
                        .padding(.horizontal, DS.Space.lg)
                        .padding(.bottom, DS.Space.lg)
                    }
                }
            }
        }
        .frame(minWidth: 520, minHeight: 360)
        .background(DS.Color.bg)
    }
}

private struct RecentRow: View {
    let action: RecentAction
    let onSelect: () -> Void

    @State private var hovering = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: DS.Space.md) {
                Image(systemName: action.item.symbol)
                    .font(DS.Font.body())
                    .foregroundStyle(DS.Color.accent)
                    .frame(width: 20)
                Text(action.name)
                    .font(DS.Font.body())
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: DS.Space.sm)
                Text(action.date, style: .relative)
                    .font(DS.Font.caption())
                    .foregroundStyle(DS.Color.textSecondary)
                    .lineLimit(1)
                    .fixedSize()
            }
            .padding(.horizontal, DS.Space.md)
            .padding(.vertical, DS.Space.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dsCard(hovering ? DS.Color.cardElevated : DS.Color.card)
            .contentShape(DS.cardShape)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: hovering)
    }
}
