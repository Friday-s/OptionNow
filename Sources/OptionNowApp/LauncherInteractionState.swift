import Foundation

@MainActor
final class LauncherInteractionState: ObservableObject {
    @Published var highlightedID: UUID?
    @Published var currentPage = 0

    func visibleItems(from items: [ToolItem], capacity: Int) -> [ToolItem] {
        guard capacity > 0, !items.isEmpty else { return items }
        let pageCount = max(1, Int(ceil(Double(items.count) / Double(capacity))))
        currentPage = min(max(0, currentPage), pageCount - 1)
        let start = currentPage * capacity
        return Array(items[start..<min(start + capacity, items.count)])
    }

    func moveSelection(in items: [ToolItem], capacity: Int, delta: Int) {
        let visible = visibleItems(from: items, capacity: capacity)
        guard !visible.isEmpty else { highlightedID = nil; return }
        let current = visible.firstIndex(where: { $0.id == highlightedID }) ?? (delta > 0 ? -1 : 0)
        let next = (current + delta + visible.count) % visible.count
        highlightedID = visible[next].id
    }

    func changePage(in items: [ToolItem], capacity: Int, delta: Int) {
        guard capacity > 0 else { return }
        let pageCount = max(1, Int(ceil(Double(items.count) / Double(capacity))))
        currentPage = min(max(0, currentPage + delta), pageCount - 1)
        highlightedID = nil
    }

    func resetHighlight() {
        highlightedID = nil
    }
}
