// swift-tools-version:4.2

import PackageDescription

let package = Package(
  name: "SwiftPhoenixClient", 
  dependencies: [
    .package(url: "https://github.com/daltoniam/Starscream.git", from: "3.0.6"),
  ],
  targets: [
    .target(
      name: "SwiftPhoenixClient",
      dependencies: ["Starscream"],
      path: "Sources"
    ),
  ]
)
