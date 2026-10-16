// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "Starfall", platforms: [.iOS(.v17)], products: [.library(name: "StarfallCore", targets: ["StarfallCore"])], targets: [.target(name: "StarfallCore"), .testTarget(name: "StarfallCoreTests", dependencies: ["StarfallCore"])])
