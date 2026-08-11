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

    @Published var hotKey: HotKeyConfiguration {
        didSet { save() }
    }
    @Published var launchAtLogin: Bool {
        didSet { updateLaunchAtLogin() }
    }
    @Published var closeOnDeactivate: Bool {
        didSet { save() }
    }
    @Published var releaseToSelect: Bool {
        didSet { save() }
    }
    @Published var showRecents: Bool {
        didSet { save() }
    }
    @Published var launcherTheme: LauncherTheme {
        didSet { save() }
    }
    @Published var launcherAccent: LauncherAccent {
        didSet { save() }
    }
    @Published var launcherPosition: LauncherPosition {
        didSet { save() }
    }
    @Published var panelOpacity: Double {
        didSet { save() }
    }
    @Published var iconSize: Double {
        didSet { save() }
    }
    @Published var recentActions: [RecentAction] {
        didSet { saveRecents() }
    }
    @Published var configurationMessage: String?
    @Published var hotKeyConflict = false

    private let defaults = UserDefaults.standard
    private let itemsKey = "optionnow.toolItems"
    private let sectorKey = "optionnow.sectorCount"
    private let hotKeyKey = "optionnow.hotKey"
    private let recentsKey = "optionnow.recents"
    private var isLoading = true
    private var isUpdatingLaunchAtLogin = false

    private init() {
        let savedCount = defaults.integer(forKey: sectorKey)
        sectorCount = [4, 6, 8].contains(savedCount) ? savedCount : 6
        hotKey = Self.decode(HotKeyConfiguration.self, from: defaults.data(forKey: hotKeyKey)) ?? .defaultValue
        launchAtLogin = LoginItemManager.isEnabled
        closeOnDeactivate = defaults.object(forKey: "optionnow.closeOnDeactivate") as? Bool ?? true
        releaseToSelect = defaults.bool(forKey: "optionnow.releaseToSelect")
        showRecents = defaults.object(forKey: "optionnow.showRecents") as? Bool ?? true
        launcherTheme = LauncherTheme(rawValue: defaults.string(forKey: "optionnow.theme") ?? "") ?? .system
        launcherAccent = LauncherAccent(rawValue: defaults.string(forKey: "optionnow.accent") ?? "") ?? .purple
        launcherPosition = LauncherPosition(rawValue: defaults.string(forKey: "optionnow.position") ?? "") ?? .pointer
        panelOpacity = defaults.object(forKey: "optionnow.panelOpacity") as? Double ?? 1
        iconSize = defaults.object(forKey: "optionnow.iconSize") as? Double ?? 20
        recentActions = Self.decode([RecentAction].self, from: defaults.data(forKey: recentsKey)) ?? []

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
        toolItems.filter { item in
            item.isEnabled && (item.kind != .recents || showRecents)
        }
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

    func chooseFolder(for itemID: UUID) {
        let panel = NSOpenPanel()
        panel.title = "选择文件夹"
        panel.prompt = "选择"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url,
              let index = toolItems.firstIndex(where: { $0.id == itemID }) else { return }
        toolItems[index].applicationPath = url.path
    }

    func addTool(kind: ToolKind) {
        let template: ToolItem
        switch kind {
        case .externalApplication:
            template = ToolItem(id: UUID(), name: "新应用", symbol: "app", kind: kind, applicationPath: nil, isEnabled: true, integrationID: nil)
        case .folder:
            template = ToolItem(id: UUID(), name: "新文件夹", symbol: "folder", kind: kind, applicationPath: nil, isEnabled: true, integrationID: nil)
        case .url:
            template = ToolItem(id: UUID(), name: "新网页", symbol: "link", kind: kind, applicationPath: "https://", isEnabled: true, integrationID: nil)
        default:
            return
        }
        toolItems.append(template)
    }

    func removeTool(id: UUID) {
        toolItems.removeAll { $0.id == id && $0.kind != .settings }
    }

    func moveTool(id: UUID, offset: Int) {
        guard let source = toolItems.firstIndex(where: { $0.id == id }) else { return }
        let destination = source + offset
        guard toolItems.indices.contains(destination) else { return }
        let item = toolItems.remove(at: source)
        toolItems.insert(item, at: destination)
    }

    func record(_ item: ToolItem) {
        guard item.kind != .recents, item.kind != .settings else { return }
        recentActions.removeAll { $0.item.id == item.id }
        recentActions.insert(RecentAction(item: item), at: 0)
        recentActions = Array(recentActions.prefix(12))
    }

    func clearRecents() {
        recentActions.removeAll()
    }

    func applicationStatus(for item: ToolItem) -> String {
        switch item.kind {
        case .files: return "系统访达"
        case .recents, .settings: return "OptionNow"
        case .url:
            return URL(string: item.applicationPath ?? "") == nil ? "链接无效" : (item.applicationPath ?? "未设置")
        case .folder, .externalApplication: break
        }
        guard let path = item.applicationPath,
              FileManager.default.fileExists(atPath: path) else {
            return "未绑定"
        }
        return URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
    }

    private func normalizeBuiltInItems() {
        for index in toolItems.indices {
            if toolItems[index].kind == .files {
                toolItems[index].name = "访达"
                toolItems[index].symbol = "folder"
                toolItems[index].applicationPath = nil
                toolItems[index].integrationID = "finder"
            } else if toolItems[index].symbol == "character.bubble" {
                toolItems[index].name = "SendLingo"
                toolItems[index].integrationID = "sendlingo"
            } else if toolItems[index].name.localizedCaseInsensitiveContains("orbit") {
                toolItems[index].integrationID = "orbit"
            } else if toolItems[index].name.localizedCaseInsensitiveContains("clipmate") {
                toolItems[index].integrationID = "clipmate"
            } else if toolItems[index].kind == .recents {
                toolItems[index].integrationID = "recents"
            } else if toolItems[index].kind == .settings {
                toolItems[index].integrationID = "settings"
            }
        }
    }

    private func configureKnownApplications() {
        for index in toolItems.indices where toolItems[index].kind == .externalApplication {
            let item = toolItems[index]
            guard let integration = ApplicationIntegration.matching(item),
                  let resolved = integration.resolveURL(savedPath: item.applicationPath) else { continue }
            toolItems[index].applicationPath = resolved.path
        }
    }

    private func updateLaunchAtLogin() {
        guard !isLoading, !isUpdatingLaunchAtLogin else { return }
        isUpdatingLaunchAtLogin = true
        defer { isUpdatingLaunchAtLogin = false }
        do {
            try LoginItemManager.setEnabled(launchAtLogin)
        } catch {
            configurationMessage = "无法更新开机启动：\(error.localizedDescription)"
            let actualValue = LoginItemManager.isEnabled
            if launchAtLogin != actualValue { launchAtLogin = actualValue }
        }
    }

    private func save() {
        guard !isLoading else { return }
        defaults.set(sectorCount, forKey: sectorKey)
        defaults.set(try? JSONEncoder().encode(hotKey), forKey: hotKeyKey)
        defaults.set(closeOnDeactivate, forKey: "optionnow.closeOnDeactivate")
        defaults.set(releaseToSelect, forKey: "optionnow.releaseToSelect")
        defaults.set(showRecents, forKey: "optionnow.showRecents")
        defaults.set(launcherTheme.rawValue, forKey: "optionnow.theme")
        defaults.set(launcherAccent.rawValue, forKey: "optionnow.accent")
        defaults.set(launcherPosition.rawValue, forKey: "optionnow.position")
        defaults.set(panelOpacity, forKey: "optionnow.panelOpacity")
        defaults.set(iconSize, forKey: "optionnow.iconSize")
        if let data = try? JSONEncoder().encode(toolItems) {
            defaults.set(data, forKey: itemsKey)
        }
    }

    private func saveRecents() {
        guard !isLoading else { return }
        defaults.set(try? JSONEncoder().encode(recentActions), forKey: recentsKey)
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
