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


### SwiftPhoenixClient

The core module which provides the Phoenix Channels and Presence logic. It also
uses URLSession's default WebSocket implementation which has a minimum iOS target
of 13.0.


## Installation

As of version 6.x, SwiftPhoenixClient is only available via SwiftPackageManager.

```swift
.package(url: "https://github.com/davidstump/SwiftPhoenixClient.git", .upToNextMajor(from: "6.0.0"))
```

and then specify `"SwiftPhoenixClient"` as a dependency of the Target in which you wish to use SwiftPhoenixClient.


## Usage

Using the Swift Phoenix Client is extremely easy (and familiar if you have used the phoenix.js client).

See the [Usage Guide](https://github.com/davidstump/SwiftPhoenixClient/wiki/Usage-Guide) for details instructions. You can also check out the [documentation](http://davidstump.github.io/SwiftPhoenixClient/)


## Example

Check out the [ViewController](https://github.com/davidstump/SwiftPhoenixClient/blob/master/Examples/Basic/chatroom/ChatRoomViewController.swift) in this repo for a brief example of a simple iOS chat application using the [Phoenix Chat Example](https://github.com/dwyl/phoenix-chat-example)

Also check out both the Swift and Elixir channels on IRC.

## Development

Check out the wiki page for [getting started](https://github.com/davidstump/SwiftPhoenixClient/wiki/Contributing)


## Thanks

Many many thanks to [Daniel Rees](https://github.com/dsrees) for his many contributions and continued maintenance of this project!

## License

SwiftPhoenixClient is available under the MIT license. See the LICENSE file for more info.
