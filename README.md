# Swift Phoenix Client

[![Version](https://img.shields.io/cocoapods/v/SwiftPhoenixClient.svg?style=flat)](http://cocoapods.org/pods/SwiftPhoenixClient)
[![License](https://img.shields.io/cocoapods/l/SwiftPhoenixClient.svg?style=flat)](http://cocoapods.org/pods/SwiftPhoenixClient)
[![Platform](https://img.shields.io/cocoapods/p/SwiftPhoenixClient.svg?style=flat)](http://cocoapods.org/pods/SwiftPhoenixClient)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

## About
Swift Phoenix Client is an extension of Starscream websocket client library
that makes it easy to connect to Phoenix sockets in a similar manner to the
Phoenix Socket Javascript library.


## Latest Version

0.6.0 Is the latest release and supports Swift 3

The `master` branch has been updated for Swift 4 along with heavy API changes. See the [CHANGELOG](https://github.com/davidstump/SwiftPhoenixClient/blob/master/CHANGELOG.md) to see what's new since the latest release. 


## Installation

### CocoaPods

You can install SwiftPhoenix Client via CocoaPods by adding the following to your
Podfile. Keep in mind that in order to use Swift Phoenix Client, the minimum iOS
target must be '9.0'

```RUBY
platform :ios, '9.0'
use_frameworks!

pod "SwiftPhoenixClient"
```

and running `pod install`. From there you will need to add `import SwiftPhoenixClient` in any ViewController you want it to be used.

## Usage

Using the Swift Phoenix Client is extremely easy (and familiar if have used the Phoenix JS client).

See the [Usage Guide](https://github.com/davidstump/SwiftPhoenixClient/wiki/Usage-Guide) for details instructions


## Example

Check out the [ViewController](https://github.com/davidstump/SwiftPhoenixClient/blob/master/Example/ChatExample/ViewController.swift) in this repo for a brief example of a simple iOS chat application using the [Phoenix Chat Example](https://github.com/chrismccord/phoenix_chat_example)

Also check out both the Swift and Elixir channels on IRC.

## Note:

Currently works with Swift 3.0, Xcode 8.0, and Phoenix 1.2.

Tested with the [Phoenix Chat Server example](https://github.com/chrismccord/phoenix_chat_example), upgraded to Phoenix 1.2.

## Development

Check out the wiki page for [getting started](https://github.com/davidstump/SwiftPhoenixClient/wiki/Contributing)

## License

SwiftPhoenixClient is available under the MIT license. See the LICENSE file for more info.
