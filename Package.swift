// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Osoko",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Osoko", targets: ["Osoko"])
    ],
    targets: [
        .target(
            name: "OsokoKit",
            swiftSettings: [
                .enableUpcomingFeature("NonisolatedNonsendingByDefault")
            ]
        ),
        .executableTarget(
            name: "Osoko",
            dependencies: ["OsokoKit"]
        ),
        .testTarget(
            name: "OsokoKitTests",
            dependencies: ["OsokoKit"]
        )
    ],
    swiftLanguageModes: [.v6]
)
