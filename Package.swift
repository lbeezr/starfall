// swift-tools-version: 5.9
import PackageDescription
// Core's test host needs Swift concurrency and a current supported macOS SDK floor.
let package = Package(name: "Starfall", platforms: [.iOS(.v17), .macOS(.v12)], products: [.library(name: "StarfallCore", targets: ["StarfallCore"])], targets: [.target(name: "StarfallCore"), .testTarget(name: "StarfallCoreTests", dependencies: ["StarfallCore"])])
