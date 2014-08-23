SwiftPhoenixChannels
===================

## Goal/Status

**Phoenix Socket Client in Swift (WIP)**

Very WIP - Building a Swift client for easily connecting to the WebSocket channels on your Phoenix project. For more 
information on setting up Phoenix Channels check out [the repo](https://github.com/phoenixframework/phoenix).

**Working on Beta6 Compatibility**

**Update**: It's Alive!
![PhoenixChat](http://cl.ly/image/0G2I2Z1p2l1x/Image%202014-07-19%20at%202.42.36%20PM.png)


## Installation
For the monent, until the Swift support in Cocoapods gets shored up, you can download the `Phoenix.Socket.swift` file from the main `PhoenixChat` directory of this project and include it in your application. 

### Dependencies
This relies on the Square teams [SocketRocket](https://github.com/square/SocketRocket) which I added via CocoaPods. 

## Usage
The syntax is very similar to the Phoenix Channels syntax demonstrated on the main [Phoenix Repo](https://github.com/phoenixframework/phoenix). 

1. You will need to instantiate the Phoenix::Socket class (inside of the ViewController in my example)
	
		let socket = Phoenix.Socket(endPoint: "ws://localhost:4000/ws")

2. You can then join the socket with the `socket.join` method as such:

		socket.join("YOUR CHANNEL", topic: "YOUR TOPIC", message: YOUR_MESSAGE_DICTIONARY) { channel in 
			// do stuffs 
		}

3. Once joined, you can handle a variety of listeners such as your initial join, new messages and new users entering the channel. 

		chan.on("join") { message in
       		// say hello
		}

		chan.on("new:message") { message in
       		// display new message
		}

		chan.on("user:entered") { message in
       		// welcome the new user
      	}

4. Do awesome things.
