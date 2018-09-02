# CHANGELOG
All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](http://keepachangelog.com/)

This product uses [Semantic Versioning](https://semver.org/). 



## [Unreleased]
* Exposes security properties of the underlying `WebSocket`. This allows for things like SSL Pinning, custom encyption setups, etc. 
* Fixes leaks ([#109](https://github.com/davidstump/SwiftPhoenixClient/issues/109))

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


[Unreleased]: https://github.com/davidstump/SwiftPhoenixClient/compare/0.9.0...HEAD
[0.9.0]: https://github.com/davidstump/SwiftPhoenixClient/compare/0.8.1...0.9.0
[0.8.1]: https://github.com/davidstump/SwiftPhoenixClient/compare/0.8.0...0.8.1
[0.8.0]: https://github.com/davidstump/SwiftPhoenixClient/compare/0.6.0...0.8.0
[migration guide]: https://github.com/davidstump/SwiftPhoenixClient/wiki/Usage-Guide
