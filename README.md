# Swift Phoenix Client

[![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg?style=flat)](https://swift.org/)
[![Version](https://img.shields.io/cocoapods/v/SwiftPhoenixClient.svg?style=flat)](http://cocoapods.org/pods/SwiftPhoenixClient)
[![License](https://img.shields.io/cocoapods/l/SwiftPhoenixClient.svg?style=flat)](http://cocoapods.org/pods/SwiftPhoenixClient)
[![Platform](https://img.shields.io/cocoapods/p/SwiftPhoenixClient.svg?style=flat)](http://cocoapods.org/pods/SwiftPhoenixClient)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Open Source Helpers](https://www.codetriage.com/davidstump/swiftphoenixclient/badges/users.svg)](https://www.codetriage.com/davidstump/swiftphoenixclient)


## About
SwiftPhoenixClient is a Swift port of phoenix.js, allowing your swift projects
to connect to a Phoenix Websocket backend.

We try out best to keep the library up to date with phoenix.js but if there is
something that is missing, please create an issue or, even better,  a PR to
address the change.

## Sample Projects

You can view the example of how to use SwiftPhoenixClient in the Example/ dir.
There are two primary classes, `BasicViewController` and `ChatRoomViewController`.
The `BasicViewController` is designed to test against a [local chat server](https://github.com/chrismccord/phoenix_chat_example)
where as `ChatRoomViewController` is a more "complete" example which targets
dwyl's [phoenix-chat-example](https://github.com/dwyl/phoenix-chat-example) Heroku app.


## Modules

SwiftPhoenixClient is broken into different modules which match different use cases

### SwiftPhoenixClient

The core module which provides the Phoenix Channels and Presence logic. It also
uses URLSession's default WebSocket implementation which has a minimum iOS target
of 13.0.

### SwiftPhoenixClient/Starscream

If you are targeting iOS < 13.0, or if you you prefer to use [Starscream](https://github.com/daltoniam/Starscream), then
you will need to also use the Starscream module to connect to your server.
Installation details can be found below.

```swift
import SwiftPhoenixClient
import StarscreamSwiftPhoenixClient

let socket = Socket(endPoint: "https://example.com/", transport: { StarscreamTransport(url: $0) })
```

### RxSwift

If you are also using RxSwift in your project, then this module provides
extensions for you to use to observe events on a channel. Installation details
can be found below.

```swift
import RxSwift
import SwiftPhoenixClient
import RxSwiftPhoenixClient

// Setup the Channel to receive and send messages
let channel = socket.channel(topic)
channel.rx
  .on("shout")
  .observeOn(MainScheduler.asyncInstance)
  .subscribe( onNext: { (message) in
    let payload = message.payload
    // Parse out your payload
  }).disposed(by: disposeBag)
```



## Installation

### CocoaPods

You can install SwiftPhoenix Client via CocoaPods by adding the following to your
Podfile. Keep in mind that in order to use Swift Phoenix Client, the minimum iOS
target must be '9.0'

```RUBY
pod "SwiftPhoenixClient", '~> 2.0'

# If using RxSwift extensions
pod "SwiftPhoenixClient/RxSwift", '~> 2.0'

# If targeting iOS < 13
pod "SwiftPhoenixClient/Starscream", '~> 2.0'
```

and running `pod install`. From there you will need to add `import SwiftPhoenixClient` in any class you want it to be used.

### Carthage

If you use Carthage to manage your dependencies, simply add
SwiftPhoenixClient to your `Cartfile`:

```
github "davidstump/SwiftPhoenixClient" ~> 2.0
```

Then run `carthage update`.

If this is your first time using Carthage in the project, you'll need to go through some additional steps as explained [over at Carthage](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application).

> NOTE: At this time, Carthage does not provide a way to build only specific repository submodules. All submodules and their dependencies will be built with the above command. However, you don't need to copy frameworks you aren't using into your project. For instance, if you aren't using `RxSwift`, feel free to delete that framework along with `RxSwiftPhoenixClient` from the Carthage Build directory after `carthage update` completes.


### SwiftPackageManager

_Note: Instructions below are for using **SwiftPM** without the Xcode UI. It's the easiest to go to your Project Settings -> Swift Packages and add SwiftPhoenixClient from there._

To integrate using Apple's Swift package manager, without Xcode integration, add the following as a dependency to your `Package.swift`:

```swift
.package(url: "https://github.com/davidstump/SwiftPhoenixClient.git", .upToNextMajor(from: "2.0.0"))
```

and then specify `"SwiftPhoenixClient"` as a dependency of the Target in which you wish to use SwiftPhoenixClient.
If you want to use one of the other module add-ons, add also `"RxSwiftPhoenixClient"` or `"StarscreamSwiftPhoenixClient"` as your Target dependency respectively.
Here's an example `PackageDescription`:

```swift
// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "MyPackage",
    products: [
        .library(
            name: "MyPackage",
            targets: ["MyPackage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/davidstump/SwiftPhoenixClient.git", .upToNextMajor(from: "2.0.0"))
    ],
    targets: [
        .target(
            name: "MyPackage",
            dependencies: ["StarscreamSwiftPhoenixClient"])
    ]
)
```


## Usage

Using the Swift Phoenix Client is extremely easy (and familiar if you have used the phoenix.js client).

See the [Usage Guide](https://github.com/davidstump/SwiftPhoenixClient/wiki/Usage-Guide) for details instructions. You can also check out the [documentation](http://davidstump.github.io/SwiftPhoenixClient/)


## Example

Check out the [ViewController](https://github.com/davidstump/SwiftPhoenixClient/blob/master/Example/ChatExample/ViewController.swift) in this repo for a brief example of a simple iOS chat application using the [Phoenix Chat Example](https://github.com/chrismccord/phoenix_chat_example)

Also check out both the Swift and Elixir channels on IRC.

## Development

Check out the wiki page for [getting started](https://github.com/davidstump/SwiftPhoenixClient/wiki/Contributing)


## Thanks

Many many thanks to [Daniel Rees](https://github.com/dsrees) for his many contributions and continued maintenance of this project!

## License

SwiftPhoenixClient is available under the MIT license. See the LICENSE file for more info.
