import PackageDescription

let package = Package(
  name: "SwiftPhoenixClient", 
  dependencies: [
    .package(url: "https://github.com/daltoniam/Starscream.git", majorVersion: 3)
  ]
)
