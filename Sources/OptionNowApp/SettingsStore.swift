import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    @Published var sectorCount: Int {
        didSet { save() }
    }

    @Published var toolItems: [ToolItem] {
        didSet { save() }
    }

    @Published var recentActions: [RecentAction] = []
    @Published var configurationMessage: String?

    private let defaults = UserDefaults.standard
    private let itemsKey = "optionnow.toolItems"
    private let sectorKey = "optionnow.sectorCount"
    private var isLoading = true

    private init() {
        let savedCount = defaults.integer(forKey: sectorKey)
        sectorCount = [4, 6, 8].contains(savedCount) ? savedCount : 6

        if let data = defaults.data(forKey: itemsKey),
           let decoded = try? JSONDecoder().decode([ToolItem].self, from: data) {
            toolItems = decoded
        } else {
            toolItems = ToolItem.defaults
        }
        normalizeBuiltInItems()
        configureKnownApplications()
        isLoading = false
        save()
    }

    var enabledItems: [ToolItem] {
        toolItems.filter(\.isEnabled)
    }

    func chooseApplication(for itemID: UUID) {
        let panel = NSOpenPanel()
        panel.title = "选择应用"
        panel.prompt = "选择"
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.application]

        guard panel.runModal() == .OK, let url = panel.url,
              let index = toolItems.firstIndex(where: { $0.id == itemID }) else { return }
        toolItems[index].applicationPath = url.path
    }

    func record(_ item: ToolItem) {
        guard item.kind != .recents, item.kind != .settings else { return }
        recentActions.insert(RecentAction(name: item.name, date: Date()), at: 0)
        recentActions = Array(recentActions.prefix(12))
    }

    func applicationStatus(for item: ToolItem) -> String {
        guard item.kind == .externalApplication else {
            return item.kind == .files ? "系统访达" : "OptionNow"
        }
        guard let path = item.applicationPath,
              FileManager.default.fileExists(atPath: path) else {
            return "未绑定"
        }
        return URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
    }

    private func normalizeBuiltInItems() {
        for index in toolItems.indices where toolItems[index].kind == .files {
            toolItems[index].name = "访达"
            toolItems[index].symbol = "folder"
            toolItems[index].applicationPath = nil
        }
    }

    private func configureKnownApplications() {
        for index in toolItems.indices where toolItems[index].kind == .externalApplication {
            if let path = toolItems[index].applicationPath,
               FileManager.default.fileExists(atPath: path) {
                continue
            }

            let item = toolItems[index]
            let candidates: [String]
            if item.name.localizedCaseInsensitiveContains("clipmate") || item.symbol == "doc.on.clipboard" {
                candidates = [
                    NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.ivor.clipmate")?.path,
                    "/Applications/ClipMate.app"
                ].compactMap { $0 }
            } else if item.name.localizedCaseInsensitiveContains("orbit") {
                candidates = [
                    NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.ivor.workbench-orbit")?.path,
                    "/Applications/Orbit.app"
                ].compactMap { $0 }
            } else {
                candidates = []
            }

            toolItems[index].applicationPath = candidates.first(where: {
                FileManager.default.fileExists(atPath: $0)
            })
        }
    }

    private func save() {
        guard !isLoading else { return }
        defaults.set(sectorCount, forKey: sectorKey)
        if let data = try? JSONEncoder().encode(toolItems) {
            defaults.set(data, forKey: itemsKey)
        }
    }
}
