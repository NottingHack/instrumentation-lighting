import PackageDescription
 
let package = Package(
    name: "instrumentation-lighting",
    dependencies: [
        .Package(url: "https://github.com/PerfectlySoft/Perfect-HTTPServer.git", majorVersion: 2),
        .Package(url: "https://github.com/PerfectlySoft/Perfect-WebSockets.git", majorVersion: 2),
        .Package(url: "https://github.com/IBM-Swift/Aphid.git", majorVersion: 0),
        .Package(url: "https://github.com/PerfectlySoft/Perfect-MariaDB.git", majorVersion: 2, minor: 0),
        .Package(url: "https://github.com/IBM-Swift/BlueSignals.git", majorVersion: 0),
        .Package(url: "https://github.com/IBM-Swift/Configuration.git", majorVersion: 1, minor: 0)
    ]
)
