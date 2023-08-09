// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "Homepage",
    platforms: [.macOS(.v13)],
    products: [
        .executable(
            name: "Homepage",
            targets: ["Homepage"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/kamik423/publish.git", branch: "master")
        // Sundell Swift has been removed since my version does not name the main page ``index''
        // .package(url: "https://github.com/JohnSundell/Publish", from: "0.8.0")
    ],
    targets: [
        .executableTarget(
            name: "Homepage",
            dependencies: [.product(name: "Publish", package: "publish")]
        )
    ]
)

//for target in package.targets {
//    target.swiftSettings = target.swiftSettings ?? []
//    target.swiftSettings?.append(
//        .unsafeFlags([
//            "-enable-bare-slash-regex",
//        ]
//    )
//  )
//}
