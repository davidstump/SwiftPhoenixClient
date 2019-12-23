//
//  SocketSpec.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 2/10/18.
//

import Quick
import Nimble
import Starscream
@testable import SwiftPhoenixClient

class SocketSpec: QuickSpec {
  
  let encode = Defaults.encode
  let decode = Defaults.decode
  
  override func spec() {
    
    describe("constructor") {
      it("sets defaults", closure: {
        let socket = Socket("wss://localhost:4000/socket")
        
        expect(socket.channels).to(haveCount(0))
        expect(socket.sendBuffer).to(haveCount(0))
        expect(socket.ref).to(equal(0))
        expect(socket.endPoint).to(equal("wss://localhost:4000/socket"))
        expect(socket.stateChangeCallbacks.open).to(beEmpty())
        expect(socket.stateChangeCallbacks.close).to(beEmpty())
        expect(socket.stateChangeCallbacks.error).to(beEmpty())
        expect(socket.stateChangeCallbacks.message).to(beEmpty())
        expect(socket.timeout).to(equal(Defaults.timeoutInterval))
        expect(socket.heartbeatInterval).to(equal(Defaults.heartbeatInterval))
        expect(socket.logger).to(beNil())
        expect(socket.reconnectAfter(1)).to(equal(0.010)) // 10ms
        expect(socket.reconnectAfter(2)).to(equal(0.050)) // 50ms
        expect(socket.reconnectAfter(3)).to(equal(0.100)) // 100ms
        expect(socket.reconnectAfter(4)).to(equal(0.150)) // 150ms
        expect(socket.reconnectAfter(5)).to(equal(0.200)) // 200ms
        expect(socket.reconnectAfter(6)).to(equal(0.250)) // 250ms
        expect(socket.reconnectAfter(7)).to(equal(0.500)) // 500ms
        expect(socket.reconnectAfter(8)).to(equal(1.000)) // 1_000ms (1s)
        expect(socket.reconnectAfter(9)).to(equal(2.000)) // 2_000ms (2s)
        expect(socket.reconnectAfter(10)).to(equal(5.00)) // 5_000ms (5s)
        expect(socket.reconnectAfter(11)).to(equal(5.00)) // 5_000ms (5s)
      })
      
      it("overrides some defaults", closure: {
        let socket = Socket("wss://localhost:4000/socket", paramsClosure: { ["one": 2] })
        socket.timeout = 40000
        socket.heartbeatInterval = 60000
        socket.logger = { _ in }
        socket.reconnectAfter = { _ in return 10 }
        
        expect(socket.timeout).to(equal(40000))
        expect(socket.heartbeatInterval).to(equal(60000))
        expect(socket.logger).toNot(beNil())
        expect(socket.reconnectAfter(1)).to(equal(10))
        expect(socket.reconnectAfter(2)).to(equal(10))
      })
      
      it("should construct a valid URL", closure: {
        
        // Test different schemes
        expect(Socket("http://localhost:4000/socket/websocket", paramsClosure: nil).endPointUrl.absoluteString)
          .to(equal("http://localhost:4000/socket/websocket"))
        
        expect(Socket("https://localhost:4000/socket/websocket", paramsClosure: nil).endPointUrl.absoluteString)
          .to(equal("https://localhost:4000/socket/websocket"))
        
        expect(Socket("ws://localhost:4000/socket/websocket", paramsClosure: nil).endPointUrl.absoluteString)
          .to(equal("ws://localhost:4000/socket/websocket"))
        
        expect(Socket("wss://localhost:4000/socket/websocket", paramsClosure: nil).endPointUrl.absoluteString)
          .to(equal("wss://localhost:4000/socket/websocket"))
        
        
        // test params
        expect(Socket("ws://localhost:4000/socket/websocket",
                      paramsClosure: { ["token": "abc123"] })
          .endPointUrl
          .absoluteString)
          .to(equal("ws://localhost:4000/socket/websocket?token=abc123"))
        
        expect(Socket("ws://localhost:4000/socket/websocket",
                      paramsClosure: { ["token": "abc123", "user_id": 1] })
          .endPointUrl
          .absoluteString)
          .to(satisfyAnyOf(
            // absoluteString does not seem to return a string with the params in a deterministic order
            equal("ws://localhost:4000/socket/websocket?token=abc123&user_id=1"),
            equal("ws://localhost:4000/socket/websocket?user_id=1&token=abc123")
            )
        )
        
        
        // test params with spaces
        expect(Socket("ws://localhost:4000/socket/websocket",
                      paramsClosure: { ["token": "abc 123", "user_id": 1] })
          .endPointUrl
          .absoluteString)
          .to(satisfyAnyOf(
            // absoluteString does not seem to return a string with the params in a deterministic order
            equal("ws://localhost:4000/socket/websocket?token=abc%20123&user_id=1"),
            equal("ws://localhost:4000/socket/websocket?user_id=1&token=abc%20123")
            )
        )
      })
      
      it("should not introduce any retain cycles", closure: {
        // Must remain as a weak var in order to deallocate the socket. This tests that the
        // reconnect timer does not old on to the Socket causing a memory leak.
        weak var socket = Socket("http://localhost:4000/socket/websocket")
        expect(socket).to(beNil())
      })
    }

    describe("params") {
      it("changes dynamically with a closure") {
        var authToken = "abc123"
        let socket = Socket("ws://localhost:4000/socket/websocket", paramsClosure: { ["token": authToken] })
        
        expect(socket.params?["token"] as? String).to(equal("abc123"))
        authToken = "xyz987"
        expect(socket.params?["token"] as? String).to(equal("xyz987"))
      }
    }

    describe("websocketProtocol") {
      it("returns wss when protocol is https", closure: {
        let socket = Socket("https://example.com/")
        expect(socket.websocketProtocol).to(equal("wss"))
      })
      
      it("returns wss when protocol is wss", closure: {
        let socket = Socket("wss://example.com/")
        expect(socket.websocketProtocol).to(equal("wss"))
      })
      
      it("returns ws when protocol is http", closure: {
        let socket = Socket("http://example.com/")
        expect(socket.websocketProtocol).to(equal("ws"))
      })
      
      it("returns ws when protocol is ws", closure: {
        let socket = Socket("ws://example.com/")
        expect(socket.websocketProtocol).to(equal("ws"))
      })
      
      it("returns empty if there is no scheme", closure: {
        let socket = Socket("example.com/")
        expect(socket.websocketProtocol).to(beEmpty())
      })
    }
    
//    describe("endPointUrl") {
//      it("does nothing with the url", closure: {
//        let socket = Socket("http://example.com/websocket")
//        expect(socket.endPointUrl.absoluteString).to(equal("http://example.com/websocket"))
//      })
//      
//      it("appends /websocket correctly", closure: {
//        let socketA = Socket("wss://example.org/chat/")
//        expect(socketA.endPointUrl.absoluteString).to(equal("wss://example.org/chat/websocket"))
//        
//        let socketB = Socket("ws://example.org/chat")
//        expect(socketB.endPointUrl.absoluteString).to(equal("ws://example.org/chat/websocket"))
//      })
//    }
    
    describe("connect with Websocket") {
      // Mocks
      var mockWebSocket: WebSocketClientMock!
      let mockWebSocketTransport: ((URL) -> WebSocketClient) = { _ in return mockWebSocket }
      
      // UUT
      var socket: Socket!
      
      beforeEach {
        mockWebSocket = WebSocketClientMock()
        socket = Socket(endPoint: "/socket", transport: mockWebSocketTransport)
        socket.skipHeartbeat = true
      }
      
      it("establishes websocket connection with endpoint", closure: {
        socket.connect()
        
        expect(socket.connection).toNot(beNil())
      })
      
      it("set callbacks for connection", closure: {
        var open = 0
        socket.onOpen { open += 1 }
        
        var close = 0
        socket.onClose { close += 1 }
        
        var lastError: Error?
        socket.onError(callback: { (error) in lastError = error })
        
        var lastMessage: Message?
        socket.onMessage(callback: { (message) in lastMessage = message })
        
        mockWebSocket.isConnected = false
        socket.connect()
        
        mockWebSocket.delegate?.websocketDidConnect(socket: mockWebSocket)
        expect(open).to(equal(1))
        
        mockWebSocket.delegate?.websocketDidDisconnect(socket: mockWebSocket, error: nil)
        expect(close).to(equal(1))
        
        mockWebSocket.delegate?.websocketDidDisconnect(socket: mockWebSocket, error: TestError.stub)
        expect(lastError).toNot(beNil())
        
        let data: [String: Any] = ["topic":"topic","event":"event","payload":["go": true],"status":"ok"]
        let text = toWebSocketText(data: data)
        mockWebSocket.delegate?.websocketDidReceiveMessage(socket: mockWebSocket, text: text)
        expect(lastMessage?.payload["go"] as? Bool).to(beTrue())
      })
      
      it("removes callbacks", closure: {
        var open = 0
        socket.onOpen { open += 1 }
        
        var close = 0
        socket.onClose { close += 1 }
        
        var lastError: Error?
        socket.onError(callback: { (error) in lastError = error })
        
        var lastMessage: Message?
        socket.onMessage(callback: { (message) in lastMessage = message })
        
        mockWebSocket.isConnected = false
        socket.releaseCallbacks()
        socket.connect()
        
        mockWebSocket.delegate?.websocketDidConnect(socket: mockWebSocket)
        expect(open).to(equal(0))
        
        mockWebSocket.delegate?.websocketDidDisconnect(socket: mockWebSocket, error: nil)
        expect(close).to(equal(0))
        
        mockWebSocket.delegate?.websocketDidDisconnect(socket: mockWebSocket, error: TestError.stub)
        expect(lastError).to(beNil())
        
        let data: [String: Any] = ["topic":"topic","event":"event","payload":["go": true],"status":"ok"]
        let text = toWebSocketText(data: data)
        mockWebSocket.delegate?.websocketDidReceiveMessage(socket: mockWebSocket, text: text)
        expect(lastMessage).to(beNil())
      })
      
      it("does not connect if already connected", closure: {
        mockWebSocket.isConnected = true
        
        socket.connect()
        socket.connect()
        
        expect(mockWebSocket.connectCallsCount).to(equal(1))
      })
    }
    
    
    describe("disconnect") {
      // Mocks
      var mockWebSocket: WebSocketClientMock!
      let mockWebSocketTransport: ((URL) -> WebSocketClient) = { _ in return mockWebSocket }
      
      // UUT
      var socket: Socket!
      
      beforeEach {
        mockWebSocket = WebSocketClientMock()
        socket = Socket(endPoint: "/socket", transport: mockWebSocketTransport)
      }
      
      it("removes existing connection", closure: {
        socket.connect()
        socket.disconnect()
        
        expect(socket.connection).to(beNil())
        expect(mockWebSocket.disconnectForceTimeoutCloseCodeReceivedArguments?.closeCode)
          .to(equal(CloseCode.normal.rawValue))
      })
      
      it("flags the socket as closed cleanly", closure: {
        expect(socket.closeWasClean).to(beFalse())
        
        socket.disconnect()
        expect(socket.closeWasClean).to(beTrue())
      })
      
      it("calls callback", closure: {
        var callCount = 0
        socket.connect()
        socket.disconnect(code: CloseCode.goingAway) {
          callCount += 1
        }
        
        expect(mockWebSocket.disconnectForceTimeoutCloseCodeCalled).to(beTrue())
        expect(mockWebSocket.disconnectForceTimeoutCloseCodeReceivedArguments?.forceTimeout).to(beNil())
        expect(mockWebSocket.disconnectForceTimeoutCloseCodeReceivedArguments?.closeCode)
          .to(equal(CloseCode.goingAway.rawValue))
        expect(callCount).to(equal(1))
        
      })
      
      it("calls onClose for all state callbacks", closure: {
        var callCount = 0
        socket.onClose {
          callCount += 1
        }
        
        socket.disconnect()
        expect(callCount).to(equal(1))
        
      })
      
      it("invalidates and releases the heartbeat timer", closure: {
        var timerCalled = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false, block: { (_) in
          timerCalled += 1
        })
        
        socket.heartbeatTimer = timer
        
        socket.disconnect()
        expect(socket.heartbeatTimer).to(beNil())
        timer.fire()
        expect(timerCalled).to(equal(0))
      })
      
      it("does nothing if not connected", closure: {
        socket.disconnect()
        expect(mockWebSocket.disconnectForceTimeoutCloseCodeCalled).to(beFalse())
      })
    }
    
    
    describe("channel") {
      var socket: Socket!
      
      beforeEach {
        socket = Socket("/socket")
      }
      
      it("returns channel with given topic and params", closure: {
        let channel = socket.channel("topic", params: ["one": "two"])
        socket.ref = 1006
        
        // No deep equal, so hack it
        expect(channel.socket?.ref).to(equal(socket.ref))
        expect(channel.topic).to(equal("topic"))
        expect(channel.params["one"] as? String).to(equal("two"))
      })
      
      it("adds channel to sockets channel list", closure: {
        expect(socket.channels).to(beEmpty())
        
        let channel = socket.channel("topic", params: ["one": "two"])
        
        expect(socket.channels).to(haveCount(1))
        expect(socket.channels[0].topic).to(equal(channel.topic))
      })
    }
    
    describe("remove") {
      var socket: Socket!
      
      beforeEach {
        socket = Socket("/socket")
      }
      
      it("removes given channel from channels", closure: {
        let channel1 = socket.channel("topic-1")
        let channel2 = socket.channel("topic-2")
        
        channel1.joinPush.ref = "1"
        channel2.joinPush.ref = "2"
        
        socket.remove(channel1)
        expect(socket.channels).to(haveCount(1))
        expect(socket.channels[0].topic).to(equal(channel2.topic))
      })
    }
    
    
    describe("push") {
      // Mocks
      var mockWebSocket: WebSocketClientMock!
      let mockWebSocketTransport: ((URL) -> WebSocketClient) = { _ in return mockWebSocket }
      
      // UUT
      var socket: Socket!
      
      beforeEach {
        mockWebSocket = WebSocketClientMock()
        socket = Socket(endPoint: "/socket", transport: mockWebSocketTransport)
      }
      
      it("sends data to connection when connected", closure: {
        mockWebSocket.isConnected = true
        socket.connect()
        socket.push(topic: "topic", event: "event", payload: ["one": "two"], ref: "ref", joinRef: "joinref")
        
        expect(mockWebSocket.writeDataCompletionCalled).to(beTrue())
        let json = self.decode(mockWebSocket.writeDataCompletionReceivedArguments!.data)
        expect(json?["topic"] as? String).to(equal("topic"))
        expect(json?["event"] as? String).to(equal("event"))
        expect(json?["payload"] as? [String: String]).to(equal(["one": "two"]))
        expect(json?["ref"] as? String).to(equal("ref"))
        expect(json?["join_ref"] as? String).to(equal("joinref"))
      })
      
      it("excludes ref information if not passed", closure: {
        mockWebSocket.isConnected = true
        socket.connect()
        socket.push(topic: "topic", event: "event", payload: ["one": "two"])
        
        let json = self.decode(mockWebSocket.writeDataCompletionReceivedArguments!.data)
        expect(json?["ref"]).to(beNil())
        expect(json?["join_ref"]).to(beNil())
      })
      
      it("buffers data when not connected", closure: {
        mockWebSocket.isConnected = false
        socket.connect()
        
        expect(socket.sendBuffer).to(beEmpty())
        
        socket.push(topic: "topic1", event: "event1", payload: ["one": "two"])
        expect(mockWebSocket.writeDataCompletionCalled).to(beFalse())
        expect(socket.sendBuffer).to(haveCount(1))
        
        socket.push(topic: "topic2", event: "event2", payload: ["one": "two"])
        expect(mockWebSocket.writeDataCompletionCalled).to(beFalse())
        expect(socket.sendBuffer).to(haveCount(2))
        
        socket.sendBuffer.forEach( { try? $0() } )
        expect(mockWebSocket.writeDataCompletionCalled).to(beTrue())
        expect(mockWebSocket.writeDataCompletionCallsCount).to(equal(2))
      })
    }
    
    describe("makeRef") {
      var socket: Socket!
      
      beforeEach {
        socket = Socket("/socket")
      }
      
      it("returns next message ref", closure: {
        expect(socket.ref).to(equal(0))
        expect(socket.makeRef()).to(equal("1"))
        expect(socket.ref).to(equal(1))
        expect(socket.makeRef()).to(equal("2"))
        expect(socket.ref).to(equal(2))
      })
      
      it("resets to 0 if it hits max int", closure: {
        socket.ref = UInt64.max
        
        expect(socket.makeRef()).to(equal("0"))
        expect(socket.ref).to(equal(0))
      })
    }
    
    describe("sendHeartbeat") {
      // Mocks
      var mockWebSocket: WebSocketClientMock!
      
      // UUT
      var socket: Socket!
      
      beforeEach {
        mockWebSocket = WebSocketClientMock()
        socket = Socket("/socket")
        socket.connection = mockWebSocket
      }
      
      it("closes socket when heartbeat is not ack'd within heartbeat window", closure: {
        mockWebSocket.isConnected = true
        socket.sendHeartbeat()
        expect(mockWebSocket.disconnectForceTimeoutCloseCodeCalled).to(beFalse())
        expect(socket.pendingHeartbeatRef).toNot(beNil())
        
        socket.sendHeartbeat()
        expect(mockWebSocket.disconnectForceTimeoutCloseCodeCalled).to(beTrue())
        expect(socket.pendingHeartbeatRef).to(beNil())
      })
      
      it("pushes heartbeat data when connected", closure: {
        mockWebSocket.isConnected = true
        
        socket.sendHeartbeat()
        
        expect(socket.pendingHeartbeatRef).to(equal(String(socket.ref)))
        expect(mockWebSocket.writeDataCompletionCalled).to(beTrue())
        
        let json = self.decode(mockWebSocket.writeDataCompletionReceivedArguments!.data)
        expect(json?["topic"] as? String).to(equal("phoenix"))
        expect(json?["event"] as? String).to(equal("heartbeat"))
        expect(json?["payload"] as? [String: String]).to(beEmpty())
        expect(json?["ref"] as? String).to(equal(socket.pendingHeartbeatRef))
      })
      
      it("does nothing when not connected", closure: {
        mockWebSocket.isConnected = false
        socket.sendHeartbeat()
        
        expect(mockWebSocket.disconnectForceTimeoutCloseCodeCalled).to(beFalse())
        expect(mockWebSocket.writeDataCompletionCalled).to(beFalse())
      })
    }
    
    
    describe("flushSendBuffer") {
      // Mocks
      var mockWebSocket: WebSocketClientMock!
      
      // UUT
      var socket: Socket!
      
      beforeEach {
        mockWebSocket = WebSocketClientMock()
        socket = Socket("/socket")
        socket.connection = mockWebSocket
      }
      
      it("calls callbacks in buffer when connected", closure: {
        var oneCalled = 0
        socket.sendBuffer.append { oneCalled += 1 }
        var twoCalled = 0
        socket.sendBuffer.append { twoCalled += 1 }
        let threeCalled = 0
        
        mockWebSocket.isConnected = true
        socket.flushSendBuffer()
        expect(oneCalled).to(equal(1))
        expect(twoCalled).to(equal(1))
        expect(threeCalled).to(equal(0))
      })
      
      it("empties send buffer", closure: {
        socket.sendBuffer.append { }
        mockWebSocket.isConnected = true
        socket.flushSendBuffer()
        
        expect(socket.sendBuffer).to(beEmpty())
      })
    }
    
    describe("onConnectionOpen") {
      // Mocks
      var mockWebSocket: WebSocketClientMock!
      var mockTimeoutTimer:TimeoutTimerMock!
      let mockWebSocketTransport: ((URL) -> WebSocketClient) = { _ in return mockWebSocket }
      
      // UUT
      var socket: Socket!
      
      beforeEach {
        mockWebSocket = WebSocketClientMock()
        mockTimeoutTimer = TimeoutTimerMock()
        socket = Socket(endPoint: "/socket", transport: mockWebSocketTransport)
        socket.reconnectAfter = { _ in return 10 }
        socket.reconnectTimer = mockTimeoutTimer
        socket.skipHeartbeat = true
        
        mockWebSocket.isConnected = true
        socket.connect()
      }
      
      it("flushes the send buffer", closure: {
        var oneCalled = 0
        socket.sendBuffer.append { oneCalled += 1 }
        
        socket.onConnectionOpen()
        expect(oneCalled).to(equal(1))
        expect(socket.sendBuffer).to(beEmpty())
      })
      
      it("resets reconnectTimer", closure: {
        socket.onConnectionOpen()
        expect(mockTimeoutTimer.resetCalled).to(beTrue())
      })
      
      it("triggers onOpen callbacks", closure: {
        var oneCalled = 0
        socket.onOpen { oneCalled += 1 }
        var twoCalled = 0
        socket.onOpen { twoCalled += 1 }
        var threeCalled = 0
        socket.onClose { threeCalled += 1 }
        
        socket.onConnectionOpen()
        expect(oneCalled).to(equal(1))
        expect(twoCalled).to(equal(1))
        expect(threeCalled).to(equal(0))
      })
    }
    
    describe("resetHeartbeat") {
      // Mocks
      var mockWebSocket: WebSocketClientMock!
      let mockWebSocketTransport: ((URL) -> WebSocketClient) = { _ in return mockWebSocket }
      
      // UUT
      var socket: Socket!
      
      beforeEach {
        mockWebSocket = WebSocketClientMock()
        socket = Socket(endPoint: "/socket", transport: mockWebSocketTransport)
        
      }
      
      it("clears any pending heartbeat", closure: {
        socket.pendingHeartbeatRef = "1"
        socket.resetHeartbeat()
        
        expect(socket.pendingHeartbeatRef).to(beNil())
      })
      
      it("does not schedule heartbeat if skipHeartbeat == true", closure: {
        socket.skipHeartbeat = true
        socket.resetHeartbeat()
        
        expect(socket.heartbeatTimer).to(beNil())
      })
      
      it("creates a timer and sends a heartbeat", closure: {
        mockWebSocket.isConnected = true
        socket.connect()
        socket.heartbeatInterval = 1
        
        expect(socket.heartbeatTimer).to(beNil())
        socket.resetHeartbeat()
        
        expect(socket.heartbeatTimer).toNot(beNil())
        expect(socket.heartbeatTimer?.timeInterval).to(equal(1))
        
        // Fire the timer
        socket.heartbeatTimer?.fire()
        expect(mockWebSocket.writeDataCompletionCalled).to(beTrue())
        let json = self.decode(mockWebSocket.writeDataCompletionReceivedArguments!.data)
        expect(json?["topic"] as? String).to(equal("phoenix"))
        expect(json?["event"] as? String).to(equal(ChannelEvent.heartbeat))
        expect(json?["payload"] as? [String: Any]).to(beEmpty())
        expect(json?["ref"] as? String).to(equal(String(socket.ref)))
      })
      
      it("should invalidate an old timer and create a new one", closure: {
        mockWebSocket.isConnected = true
        
        let timer = Timer.scheduledTimer(withTimeInterval: 1000, repeats: true) { (_) in  }
        socket.heartbeatTimer = timer
        
        expect(timer.isValid).to(beTrue())
        socket.resetHeartbeat()
        
        expect(timer.isValid).to(beFalse())
        expect(socket.heartbeatTimer).toNot(equal(timer))
      })
    }
    
    describe("onConnectionClosed") {
      // Mocks
      var mockWebSocket: WebSocketClientMock!
      var mockTimeoutTimer: TimeoutTimerMock!
      let mockWebSocketTransport: ((URL) -> WebSocketClient) = { _ in return mockWebSocket }
      
      // UUT
      var socket: Socket!
      
      beforeEach {
        mockWebSocket = WebSocketClientMock()
        mockTimeoutTimer = TimeoutTimerMock()
        socket = Socket(endPoint: "/socket", transport: mockWebSocketTransport)
//        socket.reconnectAfter = { _ in return 10 }
        socket.reconnectTimer = mockTimeoutTimer
//        socket.skipHeartbeat = true
      }
      
      it("schedules reconnectTimer timeout if normal close", closure: {
        socket.onConnectionClosed(code: Int(CloseCode.normal.rawValue))
        expect(mockTimeoutTimer.scheduleTimeoutCalled).to(beTrue())
      })
      
      
      it("does not schedule reconnectTimer timeout if normal close after explicit disconnect", closure: {
        socket.disconnect()
        expect(mockTimeoutTimer.scheduleTimeoutCalled).to(beFalse())
      })
      
      it("schedules reconnectTimer timeout if not normal close", closure: {
        socket.onConnectionClosed(code: 1001)
        expect(mockTimeoutTimer.scheduleTimeoutCalled).to(beTrue())
      })
      
      it("schedules reconnectTimer timeout if connection cannot be made after a previous clean disconnect", closure: {
        socket.disconnect()
        socket.connect()
        
        socket.onConnectionClosed(code: 1001)
        expect(mockTimeoutTimer.scheduleTimeoutCalled).to(beTrue())
      })
      
      it("triggers channel error if joining", closure: {
        let channel = socket.channel("topic")
        var errorCalled = false
        channel.on(ChannelEvent.error, callback: { _ in
          errorCalled = true
        })
        
        channel.join()
        expect(channel.state).to(equal(.joining))

        socket.onConnectionClosed(code: 1001)
        expect(errorCalled).to(beTrue())
      })
      
      it("triggers channel error if joined", closure: {
        let channel = socket.channel("topic")
        var errorCalled = false
        channel.on(ChannelEvent.error, callback: { _ in
          errorCalled = true
        })
        
        channel.join().trigger("ok", payload: [:])
        expect(channel.state).to(equal(.joined))
        
        socket.onConnectionClosed(code: 1001)
        expect(errorCalled).to(beTrue())
      })
      
      it("does not trigger channel error after leave", closure: {
        let channel = socket.channel("topic")
        var errorCalled = false
        channel.on(ChannelEvent.error, callback: { _ in
          errorCalled = true
        })
        
        channel.join().trigger("ok", payload: [:])
        channel.leave()
        expect(channel.state).to(equal(.closed))
        
        socket.onConnectionClosed(code: 1001)
        expect(errorCalled).to(beFalse())
      })
      
      
      it("triggers onClose callbacks", closure: {
        var oneCalled = 0
        socket.onClose { oneCalled += 1 }
        var twoCalled = 0
        socket.onClose { twoCalled += 1 }
        var threeCalled = 0
        socket.onOpen { threeCalled += 1 }
        
        socket.onConnectionClosed(code: 1000)
        expect(oneCalled).to(equal(1))
        expect(twoCalled).to(equal(1))
        expect(threeCalled).to(equal(0))
      })
    }
    
    describe("onConnectionError") {
      // Mocks
      var mockWebSocket: WebSocketClientMock!
      var mockTimeoutTimer: TimeoutTimerMock!
      let mockWebSocketTransport: ((URL) -> WebSocketClient) = { _ in return mockWebSocket }
      
      // UUT
      var socket: Socket!
      
      beforeEach {
        mockWebSocket = WebSocketClientMock()
        mockTimeoutTimer = TimeoutTimerMock()
        socket = Socket(endPoint: "/socket", transport: mockWebSocketTransport)
        socket.reconnectAfter = { _ in return 10 }
        socket.reconnectTimer = mockTimeoutTimer
        socket.skipHeartbeat = true
        
        mockWebSocket.isConnected = true
        socket.connect()
      }
      
      it("triggers onClose callbacks", closure: {
        var lastError: Error?
        socket.onError(callback: { (error) in lastError = error })
        
        socket.onConnectionError(TestError.stub)
        expect(lastError).toNot(beNil())
      })
      
      
      it("triggers channel error if joining", closure: {
        let channel = socket.channel("topic")
        var errorCalled = false
        channel.on(ChannelEvent.error, callback: { _ in
          errorCalled = true
        })
        
        channel.join()
        expect(channel.state).to(equal(.joining))
        
        socket.onConnectionError(TestError.stub)
        expect(errorCalled).to(beTrue())
      })
      
      it("triggers channel error if joined", closure: {
        let channel = socket.channel("topic")
        var errorCalled = false
        channel.on(ChannelEvent.error, callback: { _ in
          errorCalled = true
        })
        
        channel.join().trigger("ok", payload: [:])
        expect(channel.state).to(equal(.joined))
        
        socket.onConnectionError(TestError.stub)
        expect(errorCalled).to(beTrue())
      })
      
      it("does not trigger channel error after leave", closure: {
        let channel = socket.channel("topic")
        var errorCalled = false
        channel.on(ChannelEvent.error, callback: { _ in
          errorCalled = true
        })
        
        channel.join().trigger("ok", payload: [:])
        channel.leave()
        expect(channel.state).to(equal(.closed))
        
        socket.onConnectionError(TestError.stub)
        expect(errorCalled).to(beFalse())
      })
    }
    
    describe("onConnectionMessage") {
      // Mocks
      var mockWebSocket: WebSocketClientMock!
      var mockTimeoutTimer: TimeoutTimerMock!
      let mockWebSocketTransport: ((URL) -> WebSocketClient) = { _ in return mockWebSocket }
      
      // UUT
      var socket: Socket!
      
      beforeEach {
        mockWebSocket = WebSocketClientMock()
        mockTimeoutTimer = TimeoutTimerMock()
        socket = Socket(endPoint: "/socket", transport: mockWebSocketTransport)
        socket.reconnectAfter = { _ in return 10 }
        socket.reconnectTimer = mockTimeoutTimer
        socket.skipHeartbeat = true
        
        mockWebSocket.isConnected = true
        socket.connect()
      }
      
      it("parses raw message and triggers channel event", closure: {
        let targetChannel = socket.channel("topic")
        let otherChannel = socket.channel("off-topic")
        
        var targetMessage: Message?
        targetChannel.on("event", callback: { (msg) in targetMessage = msg })
        
        var otherMessage: Message?
        otherChannel.on("event", callback: { (msg) in otherMessage = msg })
        
        
        let data: [String: Any] = ["topic":"topic","event":"event","payload":["one": "two"],"status":"ok"]
        let rawMessage = toWebSocketText(data: data)
        
        socket.onConnectionMessage(rawMessage)
        expect(targetMessage?.topic).to(equal("topic"))
        expect(targetMessage?.event).to(equal("event"))
        expect(targetMessage?.payload["one"] as? String).to(equal("two"))
        expect(otherMessage).to(beNil())
      })
      
      it("triggers onMessage callbacks", closure: {
        var message: Message?
        socket.onMessage(callback: { (msg) in message = msg })
        
        let data: [String: Any] = ["topic":"topic","event":"event","payload":["one": "two"],"status":"ok"]
        let rawMessage = toWebSocketText(data: data)
        
        socket.onConnectionMessage(rawMessage)
        expect(message?.topic).to(equal("topic"))
        expect(message?.event).to(equal("event"))
        expect(message?.payload["one"] as? String).to(equal("two"))
      })
      
      it("clears pending heartbeat", closure: {
        socket.pendingHeartbeatRef = "5"
        let data: [String: Any] = ["topic":"topic","event":"event","payload":["one": "two"],"status":"ok", "ref": "5"]
        let rawMessage = toWebSocketText(data: data)
        socket.onConnectionMessage(rawMessage)
        expect(socket.pendingHeartbeatRef).to(beNil())
      })
    }
  }
}

