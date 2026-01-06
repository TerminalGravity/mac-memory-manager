// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MemoryManager",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MemoryManager", targets: ["MemoryManager"])
    ],
    targets: [
        .executableTarget(
            name: "MemoryManager",
            path: "Sources"
        )
    ]
)
