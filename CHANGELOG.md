# CHANGELOG
All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](http://keepachangelog.com/)

This product uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.2.0](https://github.com/davidstump/SwiftPhoenixClient/compare/1.1.2...1.2.0)
* [#153](https://github.com/davidstump/SwiftPhoenixClient/pull/153): Added ability to pass a closure when initializing a `Socket` to dynamically change `params` when reconnecting
* Fixed Package.swift and updated it to use latest Starscream

## [1.1.2](https://github.com/davidstump/SwiftPhoenixClient/compare/1.1.1...1.1.2)
* [#151](https://github.com/davidstump/SwiftPhoenixClient/pull/151): Made isJoined, isJoining, etc methods on Channel public

## [1.1.1](https://github.com/davidstump/SwiftPhoenixClient/compare/1.1.0...1.1.1)
* [#141](https://github.com/davidstump/SwiftPhoenixClient/pull/141): tvOS support
* [#145](https://github.com/davidstump/SwiftPhoenixClient/pull/145): Refactored Socket reconnect strategy
* [#146](https://github.com/davidstump/SwiftPhoenixClient/pull/146): Refactored Channel rejoin strategy

## [1.1.0]
* Swift 5

## [1.0.1]
* Fixed issue with Carthage installs

## [1.0.0]
* Rewrite of large parts of the Socket and Channel classes
* Optional API for automatic retain cycle handling
* Presence support

## [0.9.3]

## Added
* [#119](https://github.com/davidstump/SwiftPhoenixClient/pull/119): A working implementation of Presence


## Changed
* [#120](https://github.com/davidstump/SwiftPhoenixClient/pull/120): Xcode 10 and Swift 4.2



## [0.9.2]

## Fixed
* [#111](https://github.com/davidstump/SwiftPhoenixClient/pull/111): Strong memory cycles between Socket, Channel and Timers
* [#112](https://github.com/davidstump/SwiftPhoenixClient/pull/112): Leak when Socket disconnects and properly call `onClose()`
* [#114](https://github.com/davidstump/SwiftPhoenixClient/pull/114): Carthage failing on builds and app store uploads

## Changed
* [#116](https://github.com/davidstump/SwiftPhoenixClient/pull/116): A Channel's `topic` is now exposed as `public`


## [0.9.1]

### Added
* Added security configuration to the underlying WebSocket.


## [0.9.0]
Continue to improve the API and behavior of the library to behave similar to the JS library. This release introduces
some breaking changes in the API that will require updates to your code. See the [usage guide] for help.

### Updated
* Swift 4.1

### Changed
* All callbacks now receive a `Message` object. The `Payload` can be accessed using `message.payload`

### Added
* `channel.join()` can now take optional params to override the ones set while creating the Channel
* Timeouts when sending messages
* Rejoin timer which can be configured to attempt to rejoin given a function. Defaults to 1s, 2s, 5s, 10s and then retries every 10s
* Socket and Channel `on` callbacks are able to hold more than just a single callback


Thanks to @murphb52 and @ALucasVanDongen for helping with some of the development and testing of this release!


## [0.8.1]

### Fixed
* Initial params are not sent through when opening a channel

## [0.8.0]

### Updated
* Starscream to 3.0.4
* Swift 4
* Mirror [Phoenix.js](https://hexdocs.pm/phoenix/js/) more closely


[Unreleased]: https://github.com/davidstump/SwiftPhoenixClient/compare/0.9.3...HEAD
[0.9.3]: https://github.com/davidstump/SwiftPhoenixClient/compare/0.9.2...0.9.3
[0.9.2]: https://github.com/davidstump/SwiftPhoenixClient/compare/0.9.1...0.9.2
[0.9.1]: https://github.com/davidstump/SwiftPhoenixClient/compare/0.9.0...0.9.1
[0.9.0]: https://github.com/davidstump/SwiftPhoenixClient/compare/0.8.1...0.9.0
[0.8.1]: https://github.com/davidstump/SwiftPhoenixClient/compare/0.8.0...0.8.1
[0.8.0]: https://github.com/davidstump/SwiftPhoenixClient/compare/0.6.0...0.8.0
[migration guide]: https://github.com/davidstump/SwiftPhoenixClient/wiki/Usage-Guide
