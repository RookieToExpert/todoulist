// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TudouList",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "TudouList",
            targets: ["TudouList"]
        )
    ],
    targets: [
        .executableTarget(
            name: "TudouList",
            path: "Sources/TudouList"
        )
    ]
)
