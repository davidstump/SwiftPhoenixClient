//
//  ChannelSpec.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 5/18/18.
//

import Quick
import Nimble
@testable import SwiftPhoenixClient


class ChannelSpec: QuickSpec {
  
  override func spec() {
    
    // Mocks
    var mockClient: PhoenixTransportMock!
    var mockSocket: SocketMock!
    
    // Constants
    let kDefaultRef = "1"
    let kDefaultTimeout: TimeInterval = 10.0
    
    // Clock
    var fakeClock: FakeTimerQueue!
    
    // UUT
    var channel: Channel!
    
    
    /// Utility method to easily filter the bindings for a channel by their event
    func getBindings(_ event: String) -> [Binding]? {
      return channel.syncBindingsDel.filter({ $0.event == event })
    }
    
    
    beforeEach {
      // Any TimeoutTimer that is created will receive the fake clock
      // when scheduling work items
      fakeClock = FakeTimerQueue()
      TimerQueue.main = fakeClock
      
      mockClient = PhoenixTransportMock()
      
      mockSocket = SocketMock(endPoint: "/socket", transport: { _ in mockClient })
      mockSocket.connection = mockClient
      mockSocket.timeout = kDefaultTimeout
      mockSocket.makeRefReturnValue = kDefaultRef
      mockSocket.reconnectAfter = { tries -> TimeInterval in
        return tries > 3 ? 10 : [1, 2, 5, 10][tries - 1]
      }
    
      mockSocket.rejoinAfter = Defaults.rejoinSteppedBackOff
        
      
      channel = Channel(topic: "topic", params: ["one": "two"], socket: mockSocket)
      mockSocket.channelParamsReturnValue = channel
    }
    
    afterEach {
      fakeClock.reset()
    }
    
    describe("constructor") {
      it("sets defaults", closure: {
        channel = Channel(topic: "topic", params: ["one": "two"], socket: mockSocket)
        
        expect(channel.state).to(equal(ChannelState.closed))
        expect(channel.topic).to(equal("topic"))
        expect(channel.params["one"] as? String).to(equal("two"))
        expect(channel.socket === mockSocket).to(beTrue())
        expect(channel.timeout).to(equal(10))
        expect(channel.joinedOnce).to(beFalse())
        expect(channel.joinPush).toNot(beNil())
        expect(channel.pushBuffer).to(beEmpty())
      })
      
      it("sets up joinPush with literal params", closure: {
        channel = Channel(topic: "topic", params: ["one": "two"], socket: mockSocket)
        let joinPush = channel.joinPush
        
        expect(joinPush?.channel === channel).to(beTrue())
        expect(joinPush?.payload["one"] as? String).to(equal("two"))
        expect(joinPush?.event).to(equal("phx_join"))
        expect(joinPush?.timeout).to(equal(10))
      })
      
      it("should not introduce any retain cycles", closure: {
        weak var weakChannel = Channel(topic: "topic",
                                       params: ["one": 2],
                                       socket: mockSocket)
        expect(weakChannel).to(beNil())
      })
    }
    
    describe("onMessage") {
      it("returns message by default", closure: {
        let message = channel.onMessage(Message(ref: "original"))
        expect(message.ref).to(equal("original"))
      })
      
      it("can be overridden", closure: {
        channel.onMessage = { message in
          return Message(ref: "modified")
        }
        
        let message = channel.onMessage(Message(ref: "original"))
        expect(message.ref).to(equal("modified"))
      })
    }
    
    describe("updating join params") {
      it("can update join params", closure: {
        let params: Payload = ["value": 1]
        let change: Payload = ["value": 2]
        
        channel = Channel(topic: "topic", params: params, socket: mockSocket)
        let joinPush = channel.joinPush
        
        expect(joinPush?.channel === channel).to(beTrue())
        expect(joinPush?.payload["value"] as? Int).to(equal(1))
        expect(joinPush?.event).to(equal(ChannelEvent.join))
        expect(joinPush?.timeout).to(equal(10))
        
        channel.params = change
        
        expect(joinPush?.channel === channel).to(beTrue())
        expect(joinPush?.payload["value"] as? Int).to(equal(2))
        expect(channel?.params["value"] as? Int).to(equal(2))
        expect(joinPush?.event).to(equal(ChannelEvent.join))
        expect(joinPush?.timeout).to(equal(10))
      })
    }
    
    
    describe("join") {
      it("sets state to joining", closure: {
        channel.join()
        expect(channel.state.rawValue).to(equal("joining"))
      })
      
      it("sets joinedOnce to true", closure: {
        expect(channel.joinedOnce).to(beFalse())
        
        channel.join()
        expect(channel.joinedOnce).to(beTrue())
      })
      
      it("throws if attempting to join multiple times", closure: {
        channel.join()
        
        // Method is not marked to throw
        expect { channel.join() }.to(throwAssertion())
      })
      
      it("triggers socket push with channel params", closure: {
        channel.join()
        
        expect(mockSocket.pushTopicEventPayloadRefJoinRefCalled).to(beTrue())
        
        let args = mockSocket.pushTopicEventPayloadRefJoinRefReceivedArguments
        expect(args?.topic).to(equal("topic"))
        expect(args?.event).to(equal("phx_join"))
        expect(args?.payload["one"] as? String).to(equal("two"))
        expect(args?.ref).to(equal(kDefaultRef))
        expect(args?.joinRef).to(equal(channel.joinRef))
      })
      
      it("can set timeout on joinPush", closure: {
        let newTimeout: TimeInterval = 2.0
        let joinPush = channel.joinPush
        
        expect(joinPush?.timeout).to(equal(kDefaultTimeout))
        
        let _ = channel.join(timeout: newTimeout)
        expect(joinPush?.timeout).to(equal(newTimeout))
      })
      
      it("leaves existing duplicate topic on new join") {
        let transport: ((URL) -> PhoenixTransport) = { _ in return mockClient }
        let spySocket = SocketSpy(endPoint: "/socket", transport: transport)
        let channel = spySocket.channel("topic", params: ["one": "two"])
        
        mockClient.readyState = .open
        spySocket.onConnectionOpen()
        
        channel.join()
          .receive("ok") { (message) in
            let newChannel = spySocket.channel("topic")
            expect(channel.isJoined).to(beTrue())
            newChannel.join()
            
            expect(channel.isJoined).to(beFalse())
          }
        
        channel.joinPush.trigger("ok", payload: [:])
      }
    }
    
    
    describe("timeout behavior") {
      
      var spySocket: SocketSpy!
      var joinPush: Push!
      var timeout: TimeInterval!
      
      func receiveSocketOpen() {
        mockClient.readyState = .open
        spySocket.onConnectionOpen()
      }
      
      beforeEach {
        mockClient.readyState = .closed
        let transport: ((URL) -> PhoenixTransport) = { _ in return mockClient }
        spySocket = SocketSpy(endPoint: "/socket", transport: transport)
        channel = Channel(topic: "topic", params: ["one": "two"], socket: spySocket)
        
        joinPush = channel.joinPush
        timeout = joinPush.timeout
      }
      
      it("succeeds before timeout", closure: {
        spySocket.connect()
        receiveSocketOpen()
        
        channel.join()
        expect(spySocket.pushCalled).to(beTrue())
        expect(channel.timeout).to(equal(10.0))

        fakeClock.tick(0.100)
        joinPush.trigger("ok", payload: [:])
        expect(channel.state).to(equal(.joined))
        
        fakeClock.tick(timeout)
        expect(spySocket.pushCallCount).to(equal(1))
      })
      
      it("retries with backoff after timeout", closure: {
        spySocket.connect()
        receiveSocketOpen()
        
        var timeoutCallCount = 0
        channel.join().receive("timeout", callback: { (_) in
          timeoutCallCount += 1
        })
        
        expect(spySocket.pushCallCount).to(equal(1))
        expect(spySocket.pushArgs[1]?.event).to(equal("phx_join"))
        expect(timeoutCallCount).to(equal(0))
        
        fakeClock.tick(timeout) // leave pushed to server
        expect(spySocket.pushCallCount).to(equal(2))
        expect(spySocket.pushArgs[2]?.event).to(equal("phx_leave"))
        expect(timeoutCallCount).to(equal(1))
        
        fakeClock.tick(timeout + 1) // rejoin
        expect(spySocket.pushCallCount).to(equal(4))
        expect(spySocket.pushArgs[3]?.event).to(equal("phx_join"))
        expect(spySocket.pushArgs[4]?.event).to(equal("phx_leave"))
        expect(timeoutCallCount).to(equal(2))
        
        fakeClock.tick(10)
        joinPush.trigger("ok", payload: [:])
        expect(spySocket.pushCallCount).to(equal(5))
        expect(spySocket.pushArgs[5]?.event).to(equal("phx_join"))
        expect(channel.state).to(equal(.joined))
      })

      it("with socket and join delay", closure: {
        channel.join()
        expect(spySocket.pushCallCount).to(equal(1))

        // Open the socket after a delay
        fakeClock.tick(9.0)
        expect(spySocket.pushCallCount).to(equal(1))
        
        // join request returns between timeouts
        fakeClock.tick(1.0)
        spySocket.connect()
        
        expect(channel.state).to(equal(.errored))
        receiveSocketOpen()
        joinPush.trigger("ok", payload: [:])
        
        fakeClock.tick(1.0)
        expect(channel.state).to(equal(.joined))
        expect(spySocket.pushCallCount).to(equal(3))
      })

      it("with socket delay only", closure: {
        channel.join()
        expect(channel.state).to(equal(.joining))
        
        // connect socket after a delay
        fakeClock.tick(6.0)
        spySocket.connect()
        
        // open Socket after delay
        fakeClock.tick(5.0)
        receiveSocketOpen()
        joinPush.trigger("ok", payload: [:])
        
        joinPush.trigger("ok", payload: [:])
        expect(channel.state).to(equal(.joined))
      })
    }
    
    describe("joinPush") {
      var spySocket: SocketSpy!
      var joinPush: Push!
      
      beforeEach {
        mockClient.readyState = .open
        spySocket = SocketSpy(endPoint: "/socket",
                              transport: { _ in return mockClient })
        spySocket.connect()
        
        channel = Channel(topic: "topic", params: ["one": "two"], socket: spySocket)
        joinPush = channel.joinPush
        
        channel.join()
      }
      
      func receivesOk() {
        fakeClock.tick(joinPush.timeout / 2)
        joinPush.trigger("ok", payload: ["a": "b"])
      }
      
      func receivesTimeout() {
        fakeClock.tick(joinPush.timeout * 2)
      }
      
      func receiveError() {
        fakeClock.tick(joinPush.timeout / 2)
        joinPush.trigger("error", payload: ["a": "b"])
      }
      
      
      describe("receives 'ok'", {
        it("sets channel state to joined", closure: {
          expect(channel.state).toNot(equal(.joined))
          
          receivesOk()
          expect(channel.state).to(equal(.joined))
        })
        
        it("triggers receive(ok) callback after ok response", closure: {
          var callbackCallCount: Int = 0
          joinPush.receive("ok", callback: {_ in callbackCallCount += 1})
          
          receivesOk()
          expect(callbackCallCount).to(equal(1))
        })
        
        it("triggers receive('ok') callback if ok response already received", closure: {
          receivesOk()
          
          var callbackCallCount: Int = 0
          joinPush.receive("ok", callback: {_ in callbackCallCount += 1})
          
          expect(callbackCallCount).to(equal(1))
        })
        
        it("does not trigger other receive callbacks after ok response", closure: {
          var callbackCallCount: Int = 0
          joinPush
            .receive("error", callback: {_ in callbackCallCount += 1})
            .receive("timeout", callback: {_ in callbackCallCount += 1})
          
          receivesOk()
          receivesTimeout()
          
          expect(callbackCallCount).to(equal(0))
          
        })
        
        it("clears timeoutTimer workItem", closure: {
          expect(joinPush.timeoutWorkItem).toNot(beNil())
          
          receivesOk()
          expect(joinPush.timeoutWorkItem).to(beNil())
        })
        
        it("sets receivedMessage", closure: {
          expect(joinPush.receivedMessage).to(beNil())
          
          receivesOk()
          expect(joinPush.receivedMessage).toNot(beNil())
          expect(joinPush.receivedMessage?.status).to(equal("ok"))
          expect(joinPush.receivedMessage?.payload["a"] as? String).to(equal("b"))
        })
        
        it("removes channel binding", closure: {
          var bindings = getBindings("chan_reply_3")
          expect(bindings).to(haveCount(1))
          
          receivesOk()
          bindings = getBindings("chan_reply_3")
          expect(bindings).to(haveCount(0))
        })
        
        it("sets channel state to joined", closure: {
          receivesOk()
          expect(channel.state).to(equal(.joined))
        })
        
        it("resets channel rejoinTimer", closure: {
          let mockRejoinTimer = TimeoutTimerMock()
          channel.rejoinTimer = mockRejoinTimer
          
          receivesOk()
          expect(mockRejoinTimer.resetCallsCount).to(equal(1))
        })
        
        it("sends and empties channel's buffered pushEvents", closure: {
          let mockPush = PushMock(channel: channel, event: "new:msg")
          channel.pushBuffer.append(mockPush)
          
          receivesOk()
          expect(mockPush.sendCalled).to(beTrue())
          expect(channel.pushBuffer).to(haveCount(0))
        })
      })
      
      describe("receives 'timeout'", {
        it("sets channel state to errored", closure: {
          var timeoutReceived = false
          joinPush.receive("timeout", callback: { (_) in
            timeoutReceived = true
            expect(channel.state).to(equal(.errored))
          })
        
          receivesTimeout()
          expect(timeoutReceived).to(beTrue())
        })
        
        it("triggers receive('timeout') callback after ok response", closure: {
          var receiveTimeoutCallCount = 0
          joinPush.receive("timeout", callback: { (_) in
            receiveTimeoutCallCount += 1
          })
          
          receivesTimeout()
          expect(receiveTimeoutCallCount).to(equal(1))
        })
        
        it("does not trigger other receive callbacks after timeout response", closure: {
          var receiveOkCallCount = 0
          var receiveErrorCallCount = 0
          var timeoutReceived = false
          
          joinPush
            .receive("ok") {_ in receiveOkCallCount += 1 }
            .receive("error") {_ in receiveErrorCallCount += 1 }
            .receive("timeout", callback: { (_) in
              expect(receiveOkCallCount).to(equal(0))
              expect(receiveErrorCallCount).to(equal(0))
              timeoutReceived = true
            })
          
          receivesTimeout()
          receivesOk()
          
          expect(timeoutReceived).to(beTrue())
        })
        
        it("schedules rejoinTimer timeout", closure: {
          let mockRejoinTimer = TimeoutTimerMock()
          channel.rejoinTimer = mockRejoinTimer
          
          receivesTimeout()
          expect(mockRejoinTimer.scheduleTimeoutCalled).to(beTrue())
        })
      })
      
      describe("receives `error`", {
        it("triggers receive('error') callback after error response", closure: {
          expect(channel.state).to(equal(.joining))

          var errorCallsCount = 0
          joinPush.receive("error") { (_) in errorCallsCount += 1 }
          
          receiveError()
          joinPush.trigger("error", payload: [:])
          expect(errorCallsCount).to(equal(1))
        })
        
        it("triggers receive('error') callback if error response already received", closure: {
          receiveError()
          
          var errorCallsCount = 0
          joinPush.receive("error") { (_) in errorCallsCount += 1 }
          
          expect(errorCallsCount).to(equal(1))
        })
        
        it("does not trigger other receive callbacks after ok response", closure: {
          var receiveOkCallCount = 0
          var receiveTimeoutCallCount = 0
          var receiveErrorCallCount = 0
          joinPush
            .receive("ok") {_ in receiveOkCallCount += 1 }
            .receive("error", callback: { (_) in
              receiveErrorCallCount += 1
              channel.leave()
            })
            .receive("timeout") {_ in receiveTimeoutCallCount += 1 }
          
          receiveError()
          receivesTimeout()
          
          expect(receiveErrorCallCount).to(equal(1))
          expect(receiveOkCallCount).to(equal(0))
          expect(receiveTimeoutCallCount).to(equal(0))
        })
        
        it("clears timeoutTimer workItem", closure: {
          expect(joinPush.timeoutWorkItem).toNot(beNil())
          
          receiveError()
          expect(joinPush.timeoutWorkItem).to(beNil())
        })
        
        it("sets receivedMessage", closure: {
          expect(joinPush.receivedMessage).to(beNil())
          
          receiveError()
          expect(joinPush.receivedMessage).toNot(beNil())
          expect(joinPush.receivedMessage?.status).to(equal("error"))
          expect(joinPush.receivedMessage?.payload["a"] as? String).to(equal("b"))
        })
        
        it("removes channel binding", closure: {
          var bindings = getBindings("chan_reply_3")
          expect(bindings).to(haveCount(1))
          
          receiveError()
          bindings = getBindings("chan_reply_3")
          expect(bindings).to(haveCount(0))
        })
        
        it("does not sets channel state to joined", closure: {
          receiveError()
          expect(channel.state).toNot(equal(.joined))
        })
        
        it("does not trigger channel's buffered pushEvents", closure: {
          let mockPush = PushMock(channel: channel, event: "new:msg")
          channel.pushBuffer.append(mockPush)
          
          receiveError()
          expect(mockPush.sendCalled).to(beFalse())
          expect(channel.pushBuffer).to(haveCount(1))
        })
      })
    }
    
    describe("onError") {
      
      var spySocket: SocketSpy!
      var joinPush: Push!
      
      beforeEach {
        mockClient.readyState = .open
        spySocket = SocketSpy(endPoint: "/socket",
                              transport: { _ in return mockClient })
        spySocket.connect()
        
        channel = Channel(topic: "topic", params: ["one": "two"], socket: spySocket)
        joinPush = channel.joinPush
        
        channel.join()
        joinPush.trigger("ok", payload: [:])
      }
      
      
      
      it("does not trigger redundant errors during backoff", closure: {
        // Spy the channel's Join Push
        let mockPush = PushMock(channel: channel, event: "event")
        channel.joinPush = mockPush
        
        expect(mockPush.resendCalled).to(beFalse())
        channel.trigger(event: ChannelEvent.error)
        
        fakeClock.tick(1.0)
        expect(mockPush.resendCalled).to(beTrue())
        expect(mockPush.resendCallsCount).to(equal(1))

        channel.trigger(event: "error")
        fakeClock.tick(1.0)
        expect(mockPush.resendCallsCount).to(equal(1))
      })
      
      describe("while joining") {
        
        var mockPush: PushMock!
        
        beforeEach {
          channel = Channel(topic: "topic", params: ["one": "two"], socket: mockSocket)
          
          // Spy the channel's Join Push
          mockPush = PushMock(channel: channel, event: "event")
          mockPush.ref = "10"
          channel.joinPush = mockPush
          channel.state = .joining
        }
        
        it("removes the joinPush message from send buffer") {
          channel.trigger(event: ChannelEvent.error)
          expect(mockSocket.removeFromSendBufferRefCalled).to(beTrue())
          expect(mockSocket.removeFromSendBufferRefReceivedRef).to(equal("10"))
        }
        
        it("resets the joinPush") {
          channel.trigger(event: ChannelEvent.error)
          expect(mockPush.resetCalled).to(beTrue())
        }
      }
      
      it("sets channel state to .errored", closure: {
        expect(channel.state).toNot(equal(.errored))
        
        channel.trigger(event: ChannelEvent.error)
        expect(channel.state).to(equal(.errored))
      })
      
      it("tries to rejoin with backoff", closure: {
        let mockRejoinTimer = TimeoutTimerMock()
        channel.rejoinTimer = mockRejoinTimer
        
        channel.trigger(event: ChannelEvent.error)
        expect(mockRejoinTimer.scheduleTimeoutCalled).to(beTrue())
      })
      
      it("does not rejoin if channel leaving", closure: {
        channel.state = .leaving
        
        let mockPush = PushMock(channel: channel, event: "event")
        channel.joinPush = mockPush
        
        spySocket.onConnectionError(TestError.stub, response: nil)
        
        fakeClock.tick(1.0)
        expect(mockPush.sendCallsCount).to(equal(0))
        
        fakeClock.tick(2.0)
        expect(mockPush.sendCallsCount).to(equal(0))
        
        expect(channel.state).to(equal(.leaving))
      })
      
      it("does nothing if channel is closed", closure: {
        channel.state = .closed
        
        let mockPush = PushMock(channel: channel, event: "event")
        channel.joinPush = mockPush
        
        spySocket.onConnectionError(TestError.stub, response: nil)
        
        fakeClock.tick(1.0)
        expect(mockPush.sendCallsCount).to(equal(0))
        
        fakeClock.tick(2.0)
        expect(mockPush.sendCallsCount).to(equal(0))
        
        expect(channel.state).to(equal(.closed))
      })
      
      it("triggers additional callbacks", closure: {
        var onErrorCallCount = 0
        channel.onError({ (_) in onErrorCallCount += 1 })
        joinPush.trigger("ok", payload: [:])
        
        expect(channel.state).to(equal(.joined))
        expect(onErrorCallCount).to(equal(0))

        channel.trigger(event: ChannelEvent.error)
        expect(onErrorCallCount).to(equal(1))
      })
    }
    
    describe("onClose") {
      
      beforeEach {
        mockClient.readyState = .open
        channel.join()
      }
      
      it("sets state to closed", closure: {
        expect(channel.state).toNot(equal(.closed))
        channel.trigger(event: ChannelEvent.close)
        expect(channel.state).to(equal(.closed))
      })
      
      it("does not rejoin", closure: {
        let mockJoinPush = PushMock(channel: channel, event: "phx_join")
        channel.joinPush = mockJoinPush
        
        channel.trigger(event: ChannelEvent.close)
        
        fakeClock.tick(1.0)
        expect(mockJoinPush.sendCalled).to(beFalse())
        
        fakeClock.tick(2.0)
        expect(mockJoinPush.sendCalled).to(beFalse())
      })
      
      it("resets the rejoin timer", closure: {
        let mockRejoinTimer = TimeoutTimerMock()
        channel.rejoinTimer = mockRejoinTimer
        
        channel.trigger(event: ChannelEvent.close)
        expect(mockRejoinTimer.resetCalled).to(beTrue())
      })
      
      it("removes self from socket", closure: {
        channel.trigger(event: ChannelEvent.close)
        expect(mockSocket.removeCalled).to(beTrue())
        
        let removedChannel = mockSocket.removeReceivedChannel
        expect(removedChannel === channel).to(beTrue())
      })
      
      it("triggers additional callbacks", closure: {
        var onCloseCallCount = 0
        channel.onClose({ (_) in
          onCloseCallCount += 1
        })
        
        channel.trigger(event: ChannelEvent.close)
        expect(onCloseCallCount).to(equal(1))
      })
    }
    
    describe("canPush") {
      it("returns true when socket connected and channel joined", closure: {
        channel.state = .joined
        mockClient.readyState = .open
        expect(channel.canPush).to(beTrue())
      })
      
      it("otherwise returns false", closure: {
        channel.state = .joined
        mockClient.readyState = .closed
        expect(channel.canPush).to(beFalse())
        
        channel.state = .joining
        mockClient.readyState = .open
        expect(channel.canPush).to(beFalse())
        
        channel.state = .joining
        mockClient.readyState = .closed
        expect(channel.canPush).to(beFalse())
      })
    }
    
    describe("on") {
      beforeEach {
        mockSocket.makeRefClosure = nil
        mockSocket.makeRefReturnValue = kDefaultRef
      }
      
      it("sets up callback for event", closure: {
        var onCallCount = 0
        
        channel.trigger(event: "event", ref: kDefaultRef)
        expect(onCallCount).to(equal(0))
        
        channel.on("event", callback: { (_) in
          onCallCount += 1
        })
        
        channel.trigger(event: "event", ref: kDefaultRef)
        expect(onCallCount).to(equal(1))
      })
      
      it("other event callbacks are ignored", closure: {
        var onCallCount = 0
        let ignoredOnCallCount = 0
        
        channel.trigger(event: "event", ref: kDefaultRef)
        expect(ignoredOnCallCount).to(equal(0))
        
        channel.on("event", callback: { (_) in
          onCallCount += 1
        })
        
        channel.trigger(event: "event", ref: kDefaultRef)
        expect(ignoredOnCallCount).to(equal(0))
      })
      
      it("generates unique refs for callbacks ", closure: {
        let ref1 = channel.on("event1", callback: { _ in })
        let ref2 = channel.on("event2", callback: { _ in })
        expect(ref1).toNot(equal(ref2))
        expect(ref1 + 1).to(equal(ref2))
        
      })
    }
    
    describe("off") {
      beforeEach {
        mockSocket.makeRefClosure = nil
        mockSocket.makeRefReturnValue = kDefaultRef
      }
      
      it("removes all callbacks for event", closure: {
        var callCount1 = 0
        var callCount2 = 0
        var callCount3 = 0
        
        channel.on("event", callback: { _ in callCount1 += 1})
        channel.on("event", callback: { _ in callCount2 += 1})
        channel.on("other", callback: { _ in callCount3 += 1})
        
        channel.off("event")
        channel.trigger(event: "event", ref: kDefaultRef)
        channel.trigger(event: "other", ref: kDefaultRef)
        
        expect(callCount1).to(equal(0))
        expect(callCount2).to(equal(0))
        expect(callCount3).to(equal(1))
      })
      
      it("removes callback by ref", closure: {
        var callCount1 = 0
        var callCount2 = 0
        
        let ref1 = channel.on("event", callback: { _ in callCount1 += 1})
        let _ = channel.on("event", callback: { _ in callCount2 += 1})
        
        channel.off("event", ref: ref1)
        channel.trigger(event: "event", ref: kDefaultRef)
        
        expect(callCount1).to(equal(0))
        expect(callCount2).to(equal(1))
      })
    }
    
    describe("push") {
      
      beforeEach {
        mockSocket.makeRefClosure = nil
        mockSocket.makeRefReturnValue = kDefaultRef
        mockClient.readyState = .open
      }
      
      it("sends push event when successfully joined", closure: {
        channel.join().trigger("ok", payload: [:])
        channel.push("event", payload: ["foo": "bar"])
        
        expect(mockSocket.pushTopicEventPayloadRefJoinRefCalled).to(beTrue())
        let args = mockSocket.pushTopicEventPayloadRefJoinRefReceivedArguments
        expect(args?.topic).to(equal("topic"))
        expect(args?.event).to(equal("event"))
        expect(args?.payload["foo"] as? String).to(equal("bar"))
        expect(args?.joinRef).to(equal(channel.joinRef))
        expect(args?.ref).to(equal(kDefaultRef))
      })
      
      it("enqueues push event to be sent once join has succeeded", closure: {
        let joinPush = channel.join()
        channel.push("event", payload: ["foo": "bar"])
        
        let args = mockSocket.pushTopicEventPayloadRefJoinRefReceivedArguments
        expect(args?.payload["foo"]).to(beNil())
        
        fakeClock.tick(channel.timeout / 2)
        joinPush.trigger("ok", payload: [:])
         
        expect(mockSocket.pushTopicEventPayloadRefJoinRefCalled).to(beTrue())
        let args2 = mockSocket.pushTopicEventPayloadRefJoinRefReceivedArguments
        expect(args2?.payload["foo"] as? String).to(equal("bar"))
      })
      
      it("does not push if channel join times out", closure: {
        let joinPush = channel.join()
        channel.push("event", payload: ["foo": "bar"])
        
        let args = mockSocket.pushTopicEventPayloadRefJoinRefReceivedArguments
        expect(args?.payload["foo"]).to(beNil())
        
        fakeClock.tick(channel.timeout * 2)
        joinPush.trigger("ok", payload: [:])
        
        expect(mockSocket.pushTopicEventPayloadRefJoinRefCalled).to(beTrue())
        let args2 = mockSocket.pushTopicEventPayloadRefJoinRefReceivedArguments
        expect(args2?.payload["foo"]).to(beNil())
      })
      
      it("uses channel timeout by default", closure: {
        channel.join().trigger("ok", payload: [:])
        
        var timeoutCallsCount = 0
        channel
          .push("event", payload: ["foo": "bar"])
          .receive("timeout", callback: { (_) in
            timeoutCallsCount += 1
          })
        
        fakeClock.tick(channel.timeout / 2)
        expect(timeoutCallsCount).to(equal(0))
        
        fakeClock.tick(channel.timeout)
        expect(timeoutCallsCount).to(equal(1))
      })
      
      it("accepts timeout arg", closure: {
        channel.join().trigger("ok", payload: [:])
        
        var timeoutCallsCount = 0
        channel
          .push("event", payload: ["foo": "bar"], timeout: channel.timeout * 2)
          .receive("timeout", callback: { (_) in
            timeoutCallsCount += 1
          })
        
        fakeClock.tick(channel.timeout)
        expect(timeoutCallsCount).to(equal(0))
        
        fakeClock.tick(channel.timeout * 2)
        expect(timeoutCallsCount).to(equal(1))
      })
      
      it("does not time out after receiving 'ok'", closure: {
        channel.join().trigger("ok", payload: [:])
        
        var timeoutCallsCount = 0
        let push = channel.push("event", payload: ["foo": "bar"])
        push.receive("timeout", callback: { (_) in
          timeoutCallsCount += 1
        })
        
        fakeClock.tick(channel.timeout / 2)
        expect(timeoutCallsCount).to(equal(0))
        
        push.trigger("ok", payload: [:])
        
        fakeClock.tick(channel.timeout)
        expect(timeoutCallsCount).to(equal(0))
      })
      
      it("throws if channel has not been joined", closure: {
        expect { channel.push("event", payload: [:]) }.to(throwAssertion())
      })
    }
    
    describe("leave") {
      beforeEach {
        mockClient.readyState = .open
        channel.join().trigger("ok", payload: [:])
      }
      
      it("unsubscribes from server events", closure: {
        mockSocket.makeRefClosure = nil
        mockSocket.makeRefReturnValue = kDefaultRef
        
        let joinRef = channel.joinRef
        channel.leave()
        
        expect(mockSocket.pushTopicEventPayloadRefJoinRefCalled).to(beTrue())
        let args = mockSocket.pushTopicEventPayloadRefJoinRefReceivedArguments
        expect(args?.topic).to(equal("topic"))
        expect(args?.event).to(equal("phx_leave"))
        expect(args?.payload).to(beEmpty())
        expect(args?.joinRef).to(equal(joinRef))
        expect(args?.ref).to(equal(kDefaultRef))
      })
      
      it("closes channel on 'ok' from server", closure: {
        let socket = Socket(endPoint: "/socket", transport: { _ in return mockClient })
        
        let channel = socket.channel("topic", params: ["one": "two"])
        channel.join().trigger("ok", payload: [:])
        
        let anotherChannel = socket.channel("another", params: ["three": "four"])
        
        expect(socket.channels).to(haveCount(2))
        
        channel.leave().trigger("ok", payload: [:])
        expect(socket.channels).to(haveCount(1))
        expect(socket.channels.first === anotherChannel).to(beTrue())
      })
    }
    
    
    describe("isMemeber") {
      it("returns false if the message topic does not match the channel") {
        let message = Message(topic: "other")
        expect(channel.isMember(message)).to(beFalse())
      }

      it("returns true if topics match but the message doesn't have a join ref") {
        let message = Message(topic: "topic", event: ChannelEvent.close, joinRef: nil)
        expect(channel.isMember(message)).to(beTrue())
      }
      
      it("returns true if topics and join refs match") {
        channel.joinPush.ref = "2"
        let message = Message(topic: "topic", event: ChannelEvent.close, joinRef: "2")
        expect(channel.isMember(message)).to(beTrue())
      }
      
      it("returns true if topics and join refs match but event is not lifecycle") {
        channel.joinPush.ref = "2"
        let message = Message(topic: "topic", event: "event", joinRef: "2")
        expect(channel.isMember(message)).to(beTrue())
      }
      
      it("returns false topics match and is a lifecycle event but join refs do not match ") {
        channel.joinPush.ref = "2"
        let message = Message(topic: "topic", event: ChannelEvent.close, joinRef: "1")
        expect(channel.isMember(message)).to(beFalse())
      }
    }
    
    describe("isClosed") {
      it("returns true if state is .closed", closure: {
        channel.state = .joined
        expect(channel.isClosed).to(beFalse())
        
        channel.state = .closed
        expect(channel.isClosed).to(beTrue())
      })
    }
    
    describe("isErrored") {
      it("returns true if state is .errored", closure: {
        channel.state = .joined
        expect(channel.isErrored).to(beFalse())
        
        channel.state = .errored
        expect(channel.isErrored).to(beTrue())
      })
    }
    
    describe("isJoined") {
      it("returns true if state is .joined", closure: {
        channel.state = .leaving
        expect(channel.isJoined).to(beFalse())
        
        channel.state = .joined
        expect(channel.isJoined).to(beTrue())
      })
    }
    
    describe("isJoining") {
      it("returns true if state is .joining", closure: {
        channel.state = .joined
        expect(channel.isJoining).to(beFalse())
        
        channel.state = .joining
        expect(channel.isJoining).to(beTrue())
      })
    }
    
    describe("isLeaving") {
      it("returns true if state is .leaving", closure: {
        channel.state = .joined
        expect(channel.isLeaving).to(beFalse())
        
        channel.state = .leaving
        expect(channel.isLeaving).to(beTrue())
      })
    }
    
  }
}
