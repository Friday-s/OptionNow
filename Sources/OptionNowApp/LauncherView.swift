import SwiftUI

struct LauncherView: View {
    @ObservedObject var settings: SettingsStore
    let onSelect: (ToolItem) -> Void

    var body: some View {
        RadialLauncherView(
            items: settings.enabledItems,
            capacity: settings.sectorCount,
            onSelect: onSelect
        )
        .frame(width: 320, height: 320)
    }
}

private struct RadialLauncherView: View {
    let items: [ToolItem]
    let capacity: Int
    let onSelect: (ToolItem) -> Void
    @State private var highlightedID: UUID?
    @State private var currentPage = 0

    private var pages: [[ToolItem]] {
        guard capacity > 0 else { return [items] }
        return stride(from: 0, to: items.count, by: capacity).map {
            Array(items[$0..<min($0 + capacity, items.count)])
        }
    }

    private var visibleItems: [ToolItem] {
        guard !pages.isEmpty else { return [] }
        return pages[min(currentPage, pages.count - 1)]
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.22), radius: 18, y: 8)

            ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
                let count = max(visibleItems.count, 1)
                let start = Angle.degrees(-90 + Double(index) * 360 / Double(count))
                let end = Angle.degrees(-90 + Double(index + 1) * 360 / Double(count))
                Wedge(startAngle: start, endAngle: end, innerRatio: 0.43)
                    .fill(highlightedID == item.id ? Color.purple : Color.primary.opacity(0.07))
                    .overlay {
                        Wedge(startAngle: start, endAngle: end, innerRatio: 0.43)
                            .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                    }
                    .allowsHitTesting(false)

                RadialItemLabel(item: item, index: index, count: count, highlighted: highlightedID == item.id)
            }

            Circle()
                .fill(.regularMaterial)
                .frame(width: 116, height: 116)
                .overlay { centerContent }

            Circle()
                .stroke(Color.primary.opacity(0.15), lineWidth: 1)
        }
        .frame(width: 300, height: 300)
        .contentShape(Circle())
        .onContinuousHover { phase in
            switch phase {
            case .active(let location):
                updateHighlight(at: location, size: 300)
            case .ended:
                highlightedID = nil
            }
        }
        .onTapGesture {
            guard let highlightedItem else { return }
            onSelect(highlightedItem)
        }
        .padding(10)
    }

    private var highlightedItem: ToolItem? {
        visibleItems.first(where: { $0.id == highlightedID })
    }

    private func updateHighlight(at location: CGPoint, size: CGFloat) {
        guard let index = RadialGeometry.itemIndex(
            x: Double(location.x),
            y: Double(location.y),
            size: Double(size),
            count: visibleItems.count
        ) else {
            highlightedID = nil
            return
        }
        highlightedID = visibleItems[index].id
    }

    @ViewBuilder
    private var centerContent: some View {
        VStack(spacing: 4) {
            Text(highlightedItem?.name ?? "OPTIONNOW")
                .font(.system(size: highlightedItem == nil ? 14 : 16, weight: .semibold, design: .rounded))
            if pages.count > 1, highlightedItem == nil {
                HStack(spacing: 8) {
                    Button { currentPage = max(0, currentPage - 1) } label: { Image(systemName: "chevron.left") }
                        .disabled(currentPage == 0)
                    Text("\(currentPage + 1)/\(pages.count)")
                        .font(.caption.monospacedDigit())
                    Button { currentPage = min(pages.count - 1, currentPage + 1) } label: { Image(systemName: "chevron.right") }
                        .disabled(currentPage == pages.count - 1)
                }
                .buttonStyle(.plain)
            } else {
                Text(highlightedItem == nil ? "⌥ Space" : "点击打开")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct RadialItemLabel: View {
    let item: ToolItem
    let index: Int
    let count: Int
    let highlighted: Bool

    var body: some View {
        let angle = -90 + (Double(index) + 0.5) * 360 / Double(max(count, 1))
        let radians = angle * .pi / 180
        let radius = 112.0
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: item.symbol)
                    .font(.system(size: 20, weight: .medium))
                if isMissingExternalApplication {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange)
                        .offset(x: 7, y: -5)
                }
            }
            Text(item.name)
                .font(.caption2)
                .lineLimit(1)
        }
        .foregroundStyle(highlighted ? Color.white : Color.primary)
        .frame(width: 72)
        .offset(x: cos(radians) * radius, y: sin(radians) * radius)
        .allowsHitTesting(false)
    }

    private var isMissingExternalApplication: Bool {
        guard item.kind == .externalApplication else { return false }
        guard let path = item.applicationPath else { return true }
        return !FileManager.default.fileExists(atPath: path)
    }
}

private struct Wedge: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let innerRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * innerRatio
        var path = Path()
        path.addArc(center: center, radius: outerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addArc(center: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.closeSubpath()
        return path
    }
}
