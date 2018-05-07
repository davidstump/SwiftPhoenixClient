# CHANGELOG
All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](http://keepachangelog.com/)

This product uses [Semantic Versioning](https://semver.org/). 



## [Unreleased]
* Update project and dependencies to Swift 4.1
* Updated all callbacks to receive a `Message` object. The `Payload` can be accessed using `message.payload`
* `channel.join()` can now take optional params to override the ones set while creating the Channel
* Implemented timeouts
* Impletemted a rejoin timer which can be configured to attempt to rejoin given a function. Defaults to 1s, 2s, 5s, 10s and then retries every 10s
* Improved API to closer match the JS library's API
* Updated Socket and Channel `on` callbacks to be able to hold more than just a single callback



## [0.8.1]
* Bugfix when opening a channel, initial params are not sent through

## [0.8.0]
* Updated Starscream to 3.0.4
* Update officially to Swift 4
* Update library to mirror [Phoenix.js](https://hexdocs.pm/phoenix/js/) more closely


[Unreleased]: https://github.com/davidstump/SwiftPhoenixClient/compare/0.8.1...HEAD
[0.8.1]: https://github.com/davidstump/SwiftPhoenixClient/compare/0.8.0...0.8.1
[0.8.0]: https://github.com/davidstump/SwiftPhoenixClient/compare/0.6.0...0.8.0
