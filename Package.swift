// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Dvsk",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "Dvsk", targets: ["Dvsk"])
    ],
    targets: [
        .target(name: "DvskCore"),
        .executableTarget(
            name: "Dvsk",
            dependencies: ["DvskCore"]
        ),
        .testTarget(
            name: "DvskCoreTests",
            dependencies: ["DvskCore"]
        )
    ],
    swiftLanguageModes: [.v5]
)
