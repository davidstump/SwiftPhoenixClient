# Swift Phoenix Client

[![Version](https://img.shields.io/cocoapods/v/SwiftPhoenixClient.svg?style=flat)](http://cocoapods.org/pods/SwiftPhoenixClient)
[![License](https://img.shields.io/cocoapods/l/SwiftPhoenixClient.svg?style=flat)](http://cocoapods.org/pods/SwiftPhoenixClient)
[![Platform](https://img.shields.io/cocoapods/p/SwiftPhoenixClient.svg?style=flat)](http://cocoapods.org/pods/SwiftPhoenixClient)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

## About
Swift Phoenix Client is an extension of Starscream websocket client library
that makes it easy to connect to Phoenix sockets in a similar manner to the
Phoenix Socket Javascript library.

## Installation

### CocoaPods

You can install SwiftPhoenix Client via CocoaPods by adding the following to your
Podfile. Keep in mind that in order to use Swift Phoenix Client, the minimum iOS
target must be '9.0'

```
platform :ios, '9.0'
use_frameworks!

pod "SwiftPhoenixClient"
```

and running `pod install`. From there you will need to add `import SwiftPhoenixClient` in any ViewController you want it to be used.

## Usage

Using the Swift Phoenix Client is extremely easy (and familiar if have used the Phoenix JS client).

### Socket Connection/Setup

The first thing you will need is to specify your Phoenix channel endpoint.
To do so, you must separate a url into its domainAndPort, path, transport, and
protocol. For example:

```
http://localhost:4000/socket
domainAndPort: loocalhost:4000
path: socket
transport: websocket
protocol: http

```
So, to create this socket, you'd write:

```
let socket = Socket(domainAndPort: "localhost:4000", path: "socket", transport: "websocket")
```

A couple of things to note: first, the default protocol is http, so you can omit
it in the creation of the websocket. Second, the 'traditional' transport is websocket.

Another example:

```
ws://myphoenixserver.com/socket
domainAndPort: myphoenixserver.com
path: socket
transport: websocket
protocol: ws
```

So, the socket would be created with:

```
let socket = Socket(domainAndPort: "myphoenixserver.com", path: "socket", transport: "websocket")
```

### Joining Channel

In order to join a channel you must call the function `socket.join`, which takes
four arguments:

* Topic: The topic to join, for instance `"rooms:lobby"`
* Message: A Message object that is sent to the server when the socket joins the channel.
* Callback: A closure that receives a AnyObject and returns void. This AnyObject can be cast to
a Channel object to add callbacks.

For example, let's say we're joining the channel `"rooms:lobby"`, we want to
send a message indicating that we're joining and we don't want to do anything
with the channel we're joining (we'll get into details about sending and
retrieving data from a channel in the next section). You'd do something as follows.


```
socket.join(topic: "rooms:lobby", message: Message(subject: "status", body: "joining")) { channel in
  let channel = channel as! Channel
}
```

### Channel callbacks

The Channel has one main method to specify callbacks: `on`, which takes two parameters:

* Event: A String object indicating what kind of event you're listening for.
* Callback: A closure that receives AnyObject and returns void. This AnyObject can be
cast to Message to retrieve data from the message.

Some examples:

```
  channel.on("join") { message in
    debugPrint("You joined the room")
  }
```

```
  channel.on("error") { message in
    let message = message as! Message

    // data is a dictionary with keys that indicate the name of the field
    // and a value of type AnyObject
    let data = message.message as! Dictionary<String, SwiftPhoenixClient.JSON>

    // Let's say that our data has a "error_type" key
    let errorType = (data["error_type"].asString)!

    debugPrint(errorType)
  }
```

### Sending data to channel

In contrast to Phoenix.Socket javascript library, in Swift Phoenix Client you
don't use a channel object to send data to a channel, you send the data through
a Socket object directly using the `send` method, which receives one
parameter:

* data: A Payload object with the data to send.

For example:

```
  let message = Message(message: ["user": "Muhammad Ali", "body": "I am gonna show you how great I am"]
  )
  let topic = "rooms:lobby"
  let event = "new:message"
  let payload = Payload(topic: topic, event: event, message: message)
  socket.send(payload)

```

## Example

Check out the [ViewController](https://github.com/davidstump/SwiftPhoenixClient/blob/master/Example/SwiftPhoenixClient/ViewController.swift) in this repo for a brief example of a simple iOS chat application using the [Phoenix Chat Example](https://github.com/chrismccord/phoenix_chat_example)

Also check out both the Swift and Elixir channels on IRC.

## Note:

Currently works with Swift 3.0, Xcode 8.0, and Phoenix 1.2.

Tested with the [Phoenix Chat Server example](https://github.com/chrismccord/phoenix_chat_example), upgraded to Phoenix 1.2.

## Development

To set up your environment to work on `SwiftPhoenixClient` itself, clone the repo and then run `$ git submodule update --init` to check out the appropriate version of `Starscream`. You can then open `SwiftPhoenixClient.xcworkspace` in Xcode.

## License

SwiftPhoenixClient is available under the MIT license. See the LICENSE file for more info.
