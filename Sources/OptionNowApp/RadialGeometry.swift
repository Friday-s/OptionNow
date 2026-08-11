import Darwin

enum RadialGeometry {
    static func itemIndex(
        x: Double,
        y: Double,
        size: Double,
        count: Int,
        innerRatio: Double = 0.43
    ) -> Int? {
        guard count > 0, size > 0 else { return nil }

        let center = size / 2
        let deltaX = x - center
        let deltaY = y - center
        let distance = hypot(deltaX, deltaY)
        let outerRadius = size / 2

        guard distance >= outerRadius * innerRatio,
              distance <= outerRadius else {
            return nil
        }

        let degrees = atan2(deltaY, deltaX) * 180 / Double.pi
        let normalized = (degrees + 90 + 360).truncatingRemainder(dividingBy: 360)
        let sectorSize = 360 / Double(count)
        return min(Int(normalized / sectorSize), count - 1)
    }
}
