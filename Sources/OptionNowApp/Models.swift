import Foundation

enum ToolKind: String, Codable {
    case externalApplication
    case files
    case recents
    case settings
}

struct ToolItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var symbol: String
    var kind: ToolKind
    var applicationPath: String?
    var isEnabled: Bool

    static let defaults: [ToolItem] = [
        ToolItem(id: UUID(), name: "Orbit", symbol: "checklist", kind: .externalApplication, applicationPath: nil, isEnabled: true),
        ToolItem(id: UUID(), name: "翻译", symbol: "character.bubble", kind: .externalApplication, applicationPath: nil, isEnabled: true),
        ToolItem(id: UUID(), name: "ClipMate", symbol: "doc.on.clipboard", kind: .externalApplication, applicationPath: nil, isEnabled: true),
        ToolItem(id: UUID(), name: "访达", symbol: "folder", kind: .files, applicationPath: nil, isEnabled: true),
        ToolItem(id: UUID(), name: "最近使用", symbol: "clock.arrow.circlepath", kind: .recents, applicationPath: nil, isEnabled: true),
        ToolItem(id: UUID(), name: "设置", symbol: "gearshape", kind: .settings, applicationPath: nil, isEnabled: true)
    ]
}

struct RecentAction: Identifiable {
    let id = UUID()
    let name: String
    let date: Date
}
