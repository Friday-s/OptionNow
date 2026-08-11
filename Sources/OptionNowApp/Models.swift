import Carbon
import Foundation

enum ToolKind: String, Codable, CaseIterable {
    case externalApplication
    case files
    case folder
    case url
    case recents
    case settings

    var displayName: String {
        switch self {
        case .externalApplication: "应用"
        case .files: "访达"
        case .folder: "文件夹"
        case .url: "网页"
        case .recents: "最近使用"
        case .settings: "设置"
        }
    }
}

struct ToolItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var symbol: String
    var kind: ToolKind
    var applicationPath: String?
    var isEnabled: Bool
    var integrationID: String?

    static let defaults: [ToolItem] = [
        ToolItem(id: UUID(), name: "Orbit", symbol: "checklist", kind: .externalApplication, applicationPath: nil, isEnabled: true, integrationID: "orbit"),
        ToolItem(id: UUID(), name: "SendLingo", symbol: "character.bubble", kind: .externalApplication, applicationPath: nil, isEnabled: true, integrationID: "sendlingo"),
        ToolItem(id: UUID(), name: "ClipMate", symbol: "doc.on.clipboard", kind: .externalApplication, applicationPath: nil, isEnabled: true, integrationID: "clipmate"),
        ToolItem(id: UUID(), name: "访达", symbol: "folder", kind: .files, applicationPath: nil, isEnabled: true, integrationID: "finder"),
        ToolItem(id: UUID(), name: "最近使用", symbol: "clock.arrow.circlepath", kind: .recents, applicationPath: nil, isEnabled: true, integrationID: "recents"),
        ToolItem(id: UUID(), name: "设置", symbol: "gearshape", kind: .settings, applicationPath: nil, isEnabled: true, integrationID: "settings")
    ]
}

struct RecentAction: Identifiable, Codable {
    let id: UUID
    let item: ToolItem
    let name: String
    let date: Date

    init(item: ToolItem, date: Date = Date()) {
        id = UUID()
        self.item = item
        name = item.name
        self.date = date
    }
}

struct HotKeyConfiguration: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32

    static let defaultValue = HotKeyConfiguration(
        keyCode: UInt32(kVK_Space),
        modifiers: UInt32(optionKey)
    )

    var displayName: String {
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        parts.append(Self.keyName(for: keyCode))
        return parts.joined(separator: " ")
    }

    private static func keyName(for code: UInt32) -> String {
        let names: [Int: String] = [
            kVK_ANSI_A: "A", kVK_ANSI_B: "B", kVK_ANSI_C: "C", kVK_ANSI_D: "D",
            kVK_ANSI_E: "E", kVK_ANSI_F: "F", kVK_ANSI_G: "G", kVK_ANSI_H: "H",
            kVK_ANSI_I: "I", kVK_ANSI_J: "J", kVK_ANSI_K: "K", kVK_ANSI_L: "L",
            kVK_ANSI_M: "M", kVK_ANSI_N: "N", kVK_ANSI_O: "O", kVK_ANSI_P: "P",
            kVK_ANSI_Q: "Q", kVK_ANSI_R: "R", kVK_ANSI_S: "S", kVK_ANSI_T: "T",
            kVK_ANSI_U: "U", kVK_ANSI_V: "V", kVK_ANSI_W: "W", kVK_ANSI_X: "X",
            kVK_ANSI_Y: "Y", kVK_ANSI_Z: "Z"
        ]
        if let name = names[Int(code)] { return name }
        switch Int(code) {
        case kVK_Space: return "Space"
        case kVK_Return: return "Return"
        case kVK_Tab: return "Tab"
        default: return "Key " + String(code)
        }
    }
}

enum LauncherTheme: String, Codable, CaseIterable {
    case system, light, dark

    var displayName: String {
        switch self { case .system: "跟随系统"; case .light: "浅色"; case .dark: "深色" }
    }
}

enum LauncherAccent: String, Codable, CaseIterable {
    case purple, blue, pink, orange

    var displayName: String {
        switch self { case .purple: "紫色"; case .blue: "蓝色"; case .pink: "粉色"; case .orange: "橙色" }
    }
}

enum LauncherPosition: String, Codable, CaseIterable {
    case pointer, screenCenter

    var displayName: String { self == .pointer ? "鼠标附近" : "当前屏幕中央" }
}
