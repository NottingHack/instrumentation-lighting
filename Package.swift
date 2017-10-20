// swift-tools-version:4.0
// Generated automatically by Perfect Assistant 2
// Date: 2017-10-20 21:06:05 +0000
import PackageDescription

let package = Package(
	name: "nh-lighting",
	dependencies: [
		.package(url: "https://github.com/PerfectlySoft/Perfect-HTTPServer.git", "3.0.0"..<"4.0.0"),
		.package(url: "https://github.com/PerfectlySoft/Perfect-WebSockets.git", "3.0.0"..<"4.0.0"),
		.package(url: "https://github.com/PerfectlySoft/Perfect-Mosquitto", "3.0.0"..<"4.0.0"),
		.package(url: "https://github.com/PerfectlySoft/Perfect-MariaDB.git", "3.0.0"..<"4.0.0"),
		.package(url: "https://github.com/IBM-Swift/BlueSignals.git", "0.0.0"..<"1.0.0"),
		.package(url: "https://github.com/IBM-Swift/Configuration.git", "1.0.0"..<"2.0.0")
	],
	targets: [
		.target(name: "nh-lighting", dependencies: ["PerfectMosquitto", "Signals", "PerfectHTTPServer", "PerfectWebSockets", "MariaDB", "Configuration"])
	]
)