Swift Phoenix Client
====================

While I stil check up on this project and its issues (and enjoy doing so), our family's new son leaves me with significantly less free time for maintenance than I would like. I would love to hear from one or a few people who are passionate and up-to-date on all things Swift if they have any interest in helping maintain this project. Thanks for any interest :) 

## Installation

### CocoaPods

You can install SwiftPhoenix Client via CocoaPods by adding the following to your Podfile

```
pod "SwiftPhoenixClient"
```

and running `pod install`. From there you will need to add `import SwiftPhoenixClient` in any ViewController you want it to be used.

## Usage

Using the Swift Phoenix Client is extremely easy (and familiar if have used the Phoenix JS client).

### Socket Connection/Setup

The first thing you will need is to specify your Phoenix channel endpoint:

```
let socket = Phoenix.Socket(domainAndPort: "localhost:4000", path: "socket", transport: "websocket")
```

To specify a specific protocol you can use the `prot` argument:

```
let socket = Phoenix.Socket(domainAndPort: "localhost:4000", path: "socket", transport: "websocket", prot: "https")
```

Additionally, you will want to identify the topic of the channel we are joining:

```
let topic: String? = "rooms:lobby"
```

### Joining Channel

Next we want to join our channel:

```
socket.join(topic: topic!, message: Phoenix.Message(subject: "status", body: "joining")) { channel in
  let chan = channel as! Phoenix.Channel

  chan.on("join") { message in
    // A new player has joined the game
  }
}
```

### New Messages

We will want to handle new messages (or events) on the channel:

```
chan.on("new:msg") { message in
  let msg = message as! Phoenix.Message
  // Fire ze missiles.
}
```

### Other Events

Just like above,  you can handle any events that your Phoenix app is handling/broadcasting.

```
chan.on("user:entered") { message in
  // A new user has entered the game.
}
```

```
chan.on("error") { message in
  // Nuts
}
```

## Example

Check out the [ViewController](https://github.com/davidstump/SwiftPhoenixClient/blob/master/Example/SwiftPhoenixClient/ViewController.swift) in this repo for a brief example of a simple iOS chat application using the [Phoenix Chat Example](https://github.com/chrismccord/phoenix_chat_example)

Also check out both the Swift and Elixir channels on IRC.

Read the `README_pods.md` file to include this pod from a local copy (of a cloned repo). This may be necessary if you want to use the latest features, but they haven't been tagged and released to CocoaPods yet.

## Note:

Currently works with Swift 2.0, Xcode 7.0, and Phoenix 1.0.1.

Tested with the [Phoenix Chat Server example](https://github.com/chrismccord/phoenix_chat_example), upgraded to Phoenix 1.0.1.

## License

SwiftPhoenixClient is available under the MIT license. See the LICENSE file for more info.
