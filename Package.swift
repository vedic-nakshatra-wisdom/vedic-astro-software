// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "VedicAstro",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
    ],
    products: [
        .library(name: "AstroCore", targets: ["AstroCore"]),
        .executable(name: "SpikeTest", targets: ["SpikeTest"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-testing.git", exact: "6.1.0"),
    ],
    targets: [
        // Layer 0: Vendored Swiss Ephemeris C library
        .target(
            name: "CSwissEph",
            path: "Sources/CSwissEph",
            exclude: ["swevents.c"],          // Standalone utility with its own main()
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),       // Internal headers (sweph.h, etc.)
                .headerSearchPath("include"), // Public headers (swephexp.h, sweodef.h)
            ]
        ),

        // Layer 1: Pure Swift calculation engine
        .target(
            name: "AstroCore",
            dependencies: ["CSwissEph"],
            path: "Sources/AstroCore"
        ),

        // Spike test executable (works without Xcode/XCTest)
        .executableTarget(
            name: "SpikeTest",
            dependencies: ["AstroCore"],
            path: "Sources/SpikeTest"
        ),

        // Tests
        .testTarget(
            name: "AstroCoreTests",
            dependencies: [
                "AstroCore",
                .product(name: "Testing", package: "swift-testing"),
            ],
            resources: [
                .copy("Resources"),
            ]
        ),
    ]
)
