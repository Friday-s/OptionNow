import Foundation

@main
struct RadialGeometryValidation {
    static func main() {
        let points: [(Double, Double, Int)] = [
            (205, 55, 0),   // top-right: Orbit
            (260, 150, 1),  // right: Translate
            (205, 245, 2),  // bottom-right: ClipMate
            (95, 245, 3),   // bottom-left: Finder
            (40, 150, 4),   // left: Recents
            (95, 55, 5)     // top-left: Settings
        ]

        for (x, y, expected) in points {
            let actual = RadialGeometry.itemIndex(x: x, y: y, size: 300, count: 6)
            precondition(actual == expected, "Expected sector \(expected), got \(String(describing: actual))")
        }

        precondition(RadialGeometry.itemIndex(x: 150, y: 150, size: 300, count: 6) == nil)
        precondition(RadialGeometry.itemIndex(x: 0, y: 0, size: 300, count: 6) == nil)
        print("PASS: radial hover maps all six directions correctly")
    }
}
