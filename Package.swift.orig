// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "nh-lighting",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/PerfectlySoft/Perfect-HTTPServer.git", from: "2.0.0"),
        .package(url: "https://github.com/PerfectlySoft/Perfect-WebSockets.git", from: "2.0.0"),
        .package(url: "https://github.com/PerfectlySoft/Perfect-Mosquitto", from: "1.0.0"),
        .package(url: "https://github.com/PerfectlySoft/Perfect-MariaDB.git", from: "2.0.0"),
        .package(url: "https://github.com/IBM-Swift/BlueSignals.git", from: "0.0.0"),
        .package(url: "https://github.com/IBM-Swift/Configuration.git", from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "nh-lighting",
            dependencies: ["PerfectMosquitto", "Signals", "PerfectHTTPServer", "PerfectWebSockets", "MariaDB", "Configuration"]),
    ]
)
