// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "BongWallpaper",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "BongWallpaper", targets: ["BongWallpaper"])
    ],
    targets: [
        .executableTarget(
            name: "BongWallpaper",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
