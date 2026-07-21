// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "CommuteKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "CommuteKit", targets: ["CommuteKit"])
    ],
    targets: [
        .target(name: "CommuteKit")
    ]
)
