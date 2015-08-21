Swift Phoenix Client
====================

## Installation

SwiftPhoenixClient is not available yet via CocoaPods (In Progress - PRs always welcome). For the time being, to install this in a new or existing project simply copy over the contents of the [Phoenix](https://github.com/davidstump/SwiftPhoenixClient/tree/master/SwiftPhoenix/Phoenix) directory into your application.

## Usage

Using the Swift Phoenix Client is extremely easy (and familiar if have used the Phoenix JS client).

### Socket Connection/Setup

The first thing you will need is to specify your Phoenix channel endpoint:

```
let socket = Phoenix.Socket(endPoint: "http://localhost:4000/socket/websocket")
```

Additionally, you will want to identify the topic of the channel we are joining:

```
let topic: String? = "your:topic"
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

## Example

Check out the [ViewController](https://github.com/davidstump/SwiftPhoenixClient/blob/master/SwiftPhoenix/ViewController.swift) in this repo for a brief example of a simple iOS chat application using the [Phoenix Chat Example](https://github.com/chrismccord/phoenix_chat_example)

Also check out both the Swift and Elixir channels on IRC.

## Note:

Currently works with Swift 1.2, Xcode 6.4, and Phoenix 0.17.

Tested with the [Phoenix Chat Server example](https://github.com/chrismccord/phoenix_chat_example) at commit [8c8c4bd](https://github.com/chrismccord/phoenix_chat_example/commit/8c8c4bd265e0519077344c942fb870a15aaac7d0) at a point where it was working with Phoenix 0.17.

## License

SwiftPhoenixClient is available under the MIT license. See the LICENSE file for more info.