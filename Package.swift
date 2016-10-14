import PackageDescription

let package = Package(
  name: "SwiftPhoenixClient", 
  dependencies: [
    .Package(url: "https://github.com/daltoniam/Starscream.git",
             majorVersion: 2)
  ]
)
