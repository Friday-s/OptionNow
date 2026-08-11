// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OptionNow",
    platforms: [.macOS("26.0")],
    products: [
        .executable(name: "OptionNowApp", targets: ["OptionNowApp"])
    ],
    targets: [
        .executableTarget(
            name: "OptionNowApp",
            path: "Sources/OptionNowApp"
        )
    ],
    swiftLanguageModes: [.v5]
)
