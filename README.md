# Swift Phoenix Client

[![Swift](https://img.shields.io/badge/Swift-4.2-orange.svg?style=flat)](https://swift.org/)
[![Version](https://img.shields.io/cocoapods/v/SwiftPhoenixClient.svg?style=flat)](http://cocoapods.org/pods/SwiftPhoenixClient)
[![License](https://img.shields.io/cocoapods/l/SwiftPhoenixClient.svg?style=flat)](http://cocoapods.org/pods/SwiftPhoenixClient)
[![Platform](https://img.shields.io/cocoapods/p/SwiftPhoenixClient.svg?style=flat)](http://cocoapods.org/pods/SwiftPhoenixClient)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Open Source Helpers](https://www.codetriage.com/davidstump/swiftphoenixclient/badges/users.svg)](https://www.codetriage.com/davidstump/swiftphoenixclient)

## About
Swift Phoenix Client is an extension of Starscream websocket client library
that makes it easy to connect to Phoenix sockets in a similar manner to the
phoenix.js client.

The client is currently updated to mirror phoenix.js 1.4.


## Installation

### CocoaPods

You can install SwiftPhoenix Client via CocoaPods by adding the following to your
Podfile. Keep in mind that in order to use Swift Phoenix Client, the minimum iOS
target must be '9.0'

```RUBY
platform :ios, '9.0'
use_frameworks!

pod "SwiftPhoenixClient", '~> 1.0'
```

and running `pod install`. From there you will need to add `import SwiftPhoenixClient` in any class you want it to be used.

### Carthage

If you use Carthage to manage your dependencies, simply add
SwiftPhoenixClient to your `Cartfile`:

```
github "davidstump/SwiftPhoenixClient" ~> 1.0
```

Make sure you have added `SwiftPhoenixClient.framework`, and `Starscream.framework` to the "_Linked Frameworks and Libraries_" section of your target, and have included them in your Carthage framework copying build phase.

## Usage

Using the Swift Phoenix Client is extremely easy (and familiar if have used the phoenix.s client).

See the [Usage Guide](https://github.com/davidstump/SwiftPhoenixClient/wiki/Usage-Guide) for details instructions. You can also check out the [documentation](http://davidstump.github.io/SwiftPhoenixClient/)


## Example

Check out the [ViewController](https://github.com/davidstump/SwiftPhoenixClient/blob/master/Example/ChatExample/ViewController.swift) in this repo for a brief example of a simple iOS chat application using the [Phoenix Chat Example](https://github.com/chrismccord/phoenix_chat_example)

Also check out both the Swift and Elixir channels on IRC.

## Development

Check out the wiki page for [getting started](https://github.com/davidstump/SwiftPhoenixClient/wiki/Contributing)

Tested with the [Phoenix Chat Server example](https://github.com/chrismccord/phoenix_chat_example), upgraded to Phoenix 1.2.

## Thanks

Many many thanks to [Daniel Rees](https://github.com/dsrees) for his many contributions and continued maintenance of this project!

## License

SwiftPhoenixClient is available under the MIT license. See the LICENSE file for more info.
