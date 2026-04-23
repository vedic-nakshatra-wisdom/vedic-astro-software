// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "VedicAstro",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(name: "AstroCore", targets: ["AstroCore"]),
        .executable(name: "SpikeTest", targets: ["SpikeTest"]),
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

        // Tests (requires Xcode for XCTest)
        .testTarget(
            name: "AstroCoreTests",
            dependencies: ["AstroCore"],
            resources: [
                .copy("Resources"),
            ]
        ),
    ]
)
