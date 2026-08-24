import SwiftUI

struct LauncherView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var interaction: LauncherInteractionState
    let onSelect: (ToolItem) -> Void

    var body: some View {
        RadialLauncherView(
            items: settings.enabledItems,
            capacity: settings.sectorCount,
            settings: settings,
            interaction: interaction,
            onSelect: onSelect
        )
        .frame(width: 320, height: 320)
        .preferredColorScheme(preferredColorScheme)
    }

    private var preferredColorScheme: ColorScheme? {
        switch settings.launcherTheme {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

private struct RadialLauncherView: View {
    let items: [ToolItem]
    let capacity: Int
    @ObservedObject var settings: SettingsStore
    @ObservedObject var interaction: LauncherInteractionState
    let onSelect: (ToolItem) -> Void

    private var pages: [[ToolItem]] {
        guard capacity > 0 else { return [items] }
        return stride(from: 0, to: items.count, by: capacity).map {
            Array(items[$0..<min($0 + capacity, items.count)])
        }
    }

    private var visibleItems: [ToolItem] {
        guard !pages.isEmpty else { return [] }
        return pages[min(interaction.currentPage, pages.count - 1)]
    }

    var body: some View {
        ZStack {
            // The dial is the family's reference surface: native glass, a hairline
            // edge and one diffuse shadow — the same recipe `dsPanel()` applies to
            // every other window in the family.
            Circle()
                .fill(DS.reduceTransparency ? AnyShapeStyle(DS.Color.bg) : AnyShapeStyle(.ultraThinMaterial))
                .opacity(settings.panelOpacity)
                .background(Circle().fill(DS.Color.surface).opacity(settings.panelOpacity))
                .shadow(color: .black.opacity(0.22), radius: 18, y: 8)

            ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
                let count = max(visibleItems.count, 1)
                let start = Angle.degrees(-90 + Double(index) * 360 / Double(count))
                let end = Angle.degrees(-90 + Double(index + 1) * 360 / Double(count))
                let highlighted = interaction.highlightedID == item.id
                Wedge(startAngle: start, endAngle: end, innerRatio: 0.43)
                    .fill(highlighted ? accentColor : DS.Color.card)
                    .overlay {
                        Wedge(startAngle: start, endAngle: end, innerRatio: 0.43)
                            .stroke(
                                highlighted ? accentColor.opacity(0.4) : DS.Color.stroke,
                                lineWidth: DS.Stroke.border
                            )
                    }
                    .allowsHitTesting(false)

                RadialItemLabel(
                    item: item,
                    index: index,
                    count: count,
                    highlighted: highlighted,
                    iconSize: settings.iconSize
                )
            }

            Circle()
                .fill(DS.reduceTransparency ? AnyShapeStyle(DS.Color.bg) : AnyShapeStyle(.regularMaterial))
                .frame(width: 116, height: 116)
                .overlay { Circle().strokeBorder(DS.Color.stroke, lineWidth: DS.Stroke.hairline) }
                .overlay { centerContent }

            Circle()
                .strokeBorder(DS.Color.stroke, lineWidth: DS.Stroke.border)
        }
        .frame(width: 300, height: 300)
        .contentShape(Circle())
        .onContinuousHover { phase in
            switch phase {
            case .active(let location):
                updateHighlight(at: location, size: 300)
            case .ended:
                if !settings.releaseToSelect { interaction.highlightedID = nil }
            }
        }
        .onTapGesture {
            guard let highlightedItem else { return }
            onSelect(highlightedItem)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 32).onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                interaction.changePage(
                    in: items,
                    capacity: capacity,
                    delta: value.translation.width < 0 ? 1 : -1
                )
            }
        )
        .padding(10)
    }

    private var highlightedItem: ToolItem? {
        visibleItems.first(where: { $0.id == interaction.highlightedID })
    }

    private func updateHighlight(at location: CGPoint, size: CGFloat) {
        guard let index = RadialGeometry.itemIndex(
            x: Double(location.x),
            y: Double(location.y),
            size: Double(size),
            count: visibleItems.count
        ) else {
            interaction.highlightedID = nil
            return
        }
        interaction.highlightedID = visibleItems[index].id
    }

    @ViewBuilder
    private var centerContent: some View {
        VStack(spacing: DS.Space.xs) {
            Text(highlightedItem?.name ?? "OptionNow")
                .font(highlightedItem == nil ? DS.Font.h4() : DS.Font.h3())
                .foregroundStyle(DS.Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, DS.Space.sm)
            if pages.count > 1, highlightedItem == nil {
                HStack(spacing: DS.Space.sm) {
                    Button { interaction.changePage(in: items, capacity: capacity, delta: -1) } label: { Image(systemName: "chevron.left") }
                        .disabled(interaction.currentPage == 0)
                    Text("\(interaction.currentPage + 1)/\(pages.count)")
                        .font(DS.Font.caption().monospacedDigit())
                        .foregroundStyle(DS.Color.textSecondary)
                    Button { interaction.changePage(in: items, capacity: capacity, delta: 1) } label: { Image(systemName: "chevron.right") }
                        .disabled(interaction.currentPage == pages.count - 1)
                }
                .buttonStyle(DSIconButtonStyle(size: 20))
            } else {
                Text(highlightedItem == nil ? "⌥ Space" : "点击打开")
                    .font(DS.Font.caption())
                    .foregroundStyle(DS.Color.textSecondary)
            }
        }
    }

    private var accentColor: Color {
        switch settings.launcherAccent {
        case .purple: DS.Color.accent
        case .blue: DS.Color.accentBlue
        case .pink: DS.Color.accentPink
        case .orange: DS.Color.accentOrange
        }
    }
}

private struct RadialItemLabel: View {
    let item: ToolItem
    let index: Int
    let count: Int
    let highlighted: Bool
    let iconSize: Double

    var body: some View {
        let angle = -90 + (Double(index) + 0.5) * 360 / Double(max(count, 1))
        let radians = angle * .pi / 180
        let radius = 112.0
        VStack(spacing: DS.Space.xs) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: item.symbol)
                    .font(.system(size: iconSize, weight: .medium))
                if isMissingExternalApplication {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(highlighted ? DS.Color.onAccent : DS.Color.warning)
                        .offset(x: 7, y: -5)
                }
            }
            Text(item.name)
                .font(DS.Font.caption())
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(highlighted ? DS.Color.onAccent : DS.Color.textPrimary)
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
