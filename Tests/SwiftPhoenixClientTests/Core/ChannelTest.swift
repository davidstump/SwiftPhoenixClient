//
//  ChannelTest.swift
//  SwiftPhoenixClientTests
//
//  Created by Daniel Rees on 2/13/25.
//  Copyright © 2025 SwiftPhoenixClient. All rights reserved.
//

import Foundation
import Testing
@testable import SwiftPhoenixClient

@Suite("Channel", .serialized)
struct ChannelTest {
    
    @Suite("constructor")
    struct Constructor {
        
        let socket: SocketSpy
        
        init() {
            socket = SocketSpy("/", transport: { _ in TransportMock() })
            socket.timeout = 1234
        }
        
        
        @Test("sets defaults")
        func setsDefaults() async throws {
            let channel = Channel(topic: "topic", params: ["one": "two"], socket: socket)
            
            #expect(channel.state == .closed)
            #expect(channel.topic == "topic")
            expectJson(channel.params) { params in
                let params = params as! [String: Any]
                #expect(params["one"] as! String == "two")
            }
            #expect(channel.socket === socket)
            #expect(channel.timeout == 1234)
            #expect(channel.joinedOnce == false)
            #expect(channel.joinPush != nil)
            #expect(channel.pushBuffer.isEmpty)
        }
        
        @Test("sets up join push object with literal params")
        func joinPushLiteralParams() async throws {
            let channel = Channel(topic: "topic",
                                  params: .json(["one": "two"]),
                                  socket: socket)
            let joinPush = channel.joinPush
            
            #expect(joinPush?.channel === channel)
            if case .json(let json) = joinPush?.payload {
                let payload = json as? [String: Any]
                #expect(payload?["one"] as? String == "two")
            } else {
                fatalError("expected json payload")
            }
            
            #expect(joinPush?.event == "phx_join")
            #expect(joinPush?.timeout == 1234)
        }
    }
    
    @Suite("updating join params")
    struct UpdatingJoinParams {
        let socket = SocketSpy("/", transport: { _ in TransportMock() })
        
        init() {
            socket.timeout = 1234
        }
        
        @Test("can update the join params")
        func updateJoinParams() async throws {
            let channel = Channel(topic: "topic",
                                  params: .json(["value": 1]),
                                  socket: socket)
            let joinPush = channel.joinPush
            
            #expect(joinPush?.channel === channel)
            #expect(joinPush?.event == "phx_join")
            #expect(joinPush?.timeout == 1234)
            expectJson(joinPush?.payload) { payload in
                let payload = payload as! [String: Any]
                #expect(payload["value"] as! Int == 1)
            }
            
            channel.params = .json(["value": 2])
            #expect(joinPush?.channel === channel)
            #expect(joinPush?.event == "phx_join")
            #expect(joinPush?.timeout == 1234)
            expectJson(joinPush?.payload) { payload in
                let payload = payload as! [String: Any]
                #expect(payload["value"] as! Int == 2)
            }
            
            expectJson(channel.params) { params in
                let params = params as! [String: Any]
                #expect(params["value"] as! Int == 2)
            }
        }
    }
    
    @Suite("join")
    struct ChannelJoin {
        
        let socket = SocketSpy("/socket")
        let channel: Channel
        
        init() {
            socket.timeout = 15.0
            channel = socket.channel("topic", params: ["one": "two"])
        }
        
        @Test("sets state to joining")
        func testJoining() async throws {
            try channel.join()
            #expect(channel.state == .joining)
        }
        
        @Test("sets joinedOnce to true")
        func testJoinedOnce() async throws {
            #expect(channel.joinedOnce == false)
            try channel.join()
            #expect(channel.joinedOnce == true)
        }
        
        @Test("throws if attempting to join multiple times")
        func testJoinsMultipleTimes() async throws {
            try channel.join()
            
            #expect(performing: {
                try channel.join()
            }, throws: { error in
                switch error as! ChannelError {
                case .alreadyJoined: return true
                default: return false
                }
            })
        }
        
        @Test("triggers socket push with channel params")
        func triggersSocketPushWithChannelParams() async throws {
            socket.makeRefReturnValue = "1"
            
            try channel.join()
            
            #expect(socket.pushOutgoingCallCount == 1)
            let outgoingMessage = socket.pushOutgoingReceivedMessage
            #expect(outgoingMessage?.topic == "topic")
            #expect(outgoingMessage?.event == "phx_join")
            expectJson(outgoingMessage?.payload) { payload in
                let json = payload as! [String: String]
                #expect(json["one"] == "two")
            }
            #expect(outgoingMessage?.ref == "1")
            #expect(outgoingMessage?.joinRef == channel.joinRef)
        }
        
        @Test("can set timeout on joinPush")
        func canSetTimeoutOnJoinPush() async throws {
            let newTimeout: TimeInterval = 2.0
            let joinPush = channel.joinPush
            
            #expect(joinPush?.timeout == 15.0)
            try channel.join(timeout: newTimeout)
            
            #expect(joinPush?.timeout == 2.0)
        }
        
        @Test("leaves existing duplicate topic on new join")
        func leavedExistingDupTopicOnNewJoin() async throws {
            try channel.join()
                .receive("ok") { message in
                    let newChannel = socket.channel("topic")
                    #expect(channel.isJoined)
                    try! newChannel.join()
                    #expect(channel.isJoined == false)
                }
            
            channel.joinPush.trigger("ok", payload: [:])
        }
        
        @Suite("timeout behavior", .serialized)
        class TimeoutBehavior {
            
            let transport: TransportMock
            let socket: SocketSpy
            let channel: Channel
            let joinPush: Push
            
            let fakeClock: FakeTimerQueue
            
            init() {
                fakeClock = FakeTimerQueue()
                TimerQueue.main = fakeClock
                
                let transport = TransportMock()
                self.transport = transport
                socket = SocketSpy("/socket", transport: { _ in transport })
                socket.timeout = 10.0
                channel = socket.channel("topic", params: ["one": "two"])
                joinPush = channel.joinPush
            }
            
            deinit {
                fakeClock.reset()
            }
            
            func receiveSocketOpen() {
                transport.readyState = .open
                socket.onConnectionOpen(response: nil)
                
            }
            
            @Test("succeeds before timeout")
            func suceedsBeforeTimeout() async throws {
                let timeout = joinPush.timeout
                
                socket.connect()
                receiveSocketOpen()
                
                try channel.join()
                #expect(socket.pushOutgoingCalled)
                #expect(channel.timeout == 10.0)
                
                fakeClock.tick(0.100)
                joinPush.trigger("ok", payload: [:])
                
                #expect(channel.state == .joined)
                
                fakeClock.tick(timeout)
                #expect(socket.pushOutgoingCallCount == 1)
            }
            
            @Test("retries with backoff after timeout")
            func retriesWithBackoff() async throws {
                let timeout = joinPush.timeout
                
                socket.connect()
                receiveSocketOpen()
                
                var timeoutCallCount = 0
                try channel.join().receive("timeout") { _ in
                    timeoutCallCount += 1
                }
                
                #expect(socket.pushOutgoingCallCount == 1)
                #expect(socket.pushOutgoingReceivedMessage?.event == "phx_join")
                #expect(timeoutCallCount == 0)
                
                fakeClock.tick(timeout) // leave pushed to server
                #expect(socket.pushOutgoingCallCount == 2)
                #expect(socket.pushOutgoingReceivedMessage?.event == "phx_leave")
                #expect(timeoutCallCount == 1)
                
                
                fakeClock.tick(timeout + 1) // rejoin
                #expect(socket.pushOutgoingCallCount == 4)
                #expect(socket.pushOutgoingReceivedMessages[3]?.event == "phx_join")
                #expect(socket.pushOutgoingReceivedMessages[4]?.event == "phx_leave")
                #expect(timeoutCallCount == 2)
                
                fakeClock.tick(10)
                joinPush.trigger("ok", payload: [:])
                #expect(socket.pushOutgoingCallCount == 5)
                #expect(socket.pushOutgoingReceivedMessages[5]?.event == "phx_join")
                #expect(channel.state == .joined)
            }
            
            @Test("with socket and join delay")
            func withSocketAndJoinDelay() async throws {
                try channel.join()
                #expect(socket.pushOutgoingCallCount == 1)
                
                // Open the socket after a delay
                fakeClock.tick(9.0)
                #expect(socket.pushOutgoingCallCount == 1)
                
                // join request returns between timeouts
                fakeClock.tick(1.0)
                socket.connect()
                
                #expect(channel.state == .errored)
                receiveSocketOpen()
                joinPush.trigger("ok", payload: [:])
                
                // join request succeeds after delay
                fakeClock.tick(1.0)
                #expect(channel.state == .joined)
                #expect(socket.pushOutgoingCallCount == 3)
            }
            
            @Test("with socket delay only")
            func withSocketDelayOnly() async throws {
                try channel.join()
                #expect(channel.state == .joining)
                
                // connect socket after a delay
                fakeClock.tick(6.0)
                socket.connect()
                transport.readyState = .connecting
                
                // open Socket after delay
                fakeClock.tick(5.0)
                receiveSocketOpen()
                joinPush.trigger("ok", payload: [:])
                
                joinPush.trigger("ok", payload: [:])
                #expect(channel.state == .joined)
            }
        }
    }
    
    @Suite("joinPush", .serialized)
    class JoinPush {
        
        let transport: TransportMock
        let socket: SocketSpy
        let channel: Channel
        let joinPush: Push
        
        let fakeClock: FakeTimerQueue
        
        init() throws {
            fakeClock = FakeTimerQueue()
            TimerQueue.main = fakeClock
            
            let transport = TransportMock()
            transport.readyState = .open
            self.transport = transport
            
            socket = SocketSpy("/socket", transport: { _ in transport })
            socket.connect()
            
            channel = socket.channel("topic", params: ["one": "two"])
            joinPush = channel.joinPush
            
            try channel.join()
        }
        
        deinit {
            fakeClock.reset()
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
        
        @Test("receives 'ok' - sets channel state to joined")
        func receivesOkSetsChannelStateToJoined() async throws {
            #expect(channel.state != .joined)
            receivesOk()
            #expect(channel.state == .joined)
        }
        
        @Test("receives 'ok' - triggers receive('ok') callback after ok response")
        func receivesOkTriggersOkCallbackAfterResponse() async throws {
            var callbackCallCount: Int = 0
            joinPush.receive("ok") { _ in callbackCallCount += 1}
            
            receivesOk()
            #expect(callbackCallCount == 1)
        }
        @Test("receives 'ok' - triggers receive('ok') callback if ok response already received")
        func triggersOkayAfterAlreadyReceived() async throws {
            receivesOk()
            
            var callbackCallCount: Int = 0
            joinPush.receive("ok") { _ in callbackCallCount += 1}
            #expect(callbackCallCount == 1)
        }
        
        @Test("receives 'ok' - does not trigger other receive callbacks after ok response")
        func doesNotTriggerOtherCallbacksAfterOk() async throws {
            var callbackCallCount: Int = 0
            joinPush
                .receive("error", callback: {_ in callbackCallCount += 1})
                .receive("timeout", callback: {_ in callbackCallCount += 1})
            
            receivesOk()
            receivesTimeout()
            
            #expect(callbackCallCount == 0)
        }
        
        @Test("receives 'ok' - clears timeoutTimer workItem")
        func clearsTimeoutTimerWorkItem() async throws{
            #expect(joinPush.timeoutWorkItem != nil)
            
            receivesOk()
            #expect(joinPush.timeoutWorkItem == nil)
        }
        
        @Test("receives 'ok' - sets receivedMessage")
        func setsReceivedMesage() async throws {
            #expect(joinPush.receivedMessage == nil)
            
            receivesOk()
            #expect(joinPush.receivedMessage != nil)
            #expect(joinPush.receivedMessage?.status == "ok")
            
        }
        
        @Test("receives 'ok' - removes channel binding")
        func okayRemovesChannelBinding() async throws {
            var subscriptions = channel.getChannelSubscription("chan_reply_3")
            #expect(subscriptions.count == 1)
            
            receivesOk()
            subscriptions = channel.getChannelSubscription("chan_reply_3")
            #expect(subscriptions.count == 0)
        }
        
        
        @Test("receives 'ok' - resets channel rejoinTimer")
        func resetsChannelRejoinTimer() async throws {
            let mockRejoinTimer = ScheduleTimerMock()
            channel.rejoinTimer = mockRejoinTimer
            
            receivesOk()
            #expect(mockRejoinTimer.resetCallsCount == 1)
        }
        
        @Test("receives 'ok' - sends and empties channel's buffered pushEvents")
        func sendsAndEmptiesChannelBufferedPushEvents() async throws {
            let push = PushSpy(channel: channel, event: "new:msg")
            channel.pushBuffer.append(push)
            
            #expect(channel.state == .joining)
            var okReceived = false
            joinPush.receive("ok") { _ in
                okReceived = true
                #expect(push.sendCalled)
                #expect(self.channel.pushBuffer.isEmpty)
            }
            
            receivesOk()
            #expect(okReceived)
        }
        
        @Test("receives 'timeout' - sets channel state to errored")
        func setsChannelStateToErrored() async throws {
            var timeoutReceived = false
            joinPush.receive("timeout", callback: { (_) in
                #expect(self.channel.state == .errored)
                timeoutReceived = true
            })
            
            receivesTimeout()
            #expect(timeoutReceived)
        }
        
        @Test("receives 'timeout' - triggers receive('timeout') callback after timeout response")
        func triggersTimeoutCallbackAfterOkay() async throws {
            var receiveTimeoutCallCount = 0
            joinPush.receive("timeout", callback: { (_) in
                receiveTimeoutCallCount += 1
            })
            
            receivesTimeout()
            #expect(receiveTimeoutCallCount == 1)
        }
        
        @Test("receives 'timeout' - does not trigger other receive callbacks after timeout response")
        func doesNotTriggerOtherCallabcksAfterTimeout() async throws {
            var receiveOkCallCount = 0
            var receiveErrorCallCount = 0
            var timeoutReceived = false
            
            joinPush
                .receive("ok") {_ in receiveOkCallCount += 1 }
                .receive("error") {_ in receiveErrorCallCount += 1 }
                .receive("timeout", callback: { (_) in
                    #expect(receiveOkCallCount == 0)
                    #expect(receiveErrorCallCount == 0)
                    timeoutReceived = true
                })
            
            receivesTimeout()
            receivesOk()
            
            #expect(timeoutReceived)
        }
        
        @Test("receives 'timeout' - schedules rejoinTimer timeout")
        func schedulesRejoinTimeout() async throws {
            let mockRejoinTimer = ScheduleTimerMock()
            channel.rejoinTimer = mockRejoinTimer
            
            receivesTimeout()
            #expect(mockRejoinTimer.scheduleTimeoutCalled)
        }
        
        
        @Test("receives 'error' - triggers receive('error') callback after error response")
        func triggersErrorCallbacks() async throws {
            #expect(channel.state == .joining)
        
            var errorCallsCount = 0
            joinPush.receive("error") { (_) in errorCallsCount += 1 }
            
            receiveError()
            joinPush.trigger("error", payload: [:])
            #expect(errorCallsCount == 1)
        }
        
        @Test("receives 'error' - triggers receive('error') callback if error response already received")
        func triggersErrorCallbacksIfErroResponsesAlreadyReceived() async throws {
            receiveError()
            
            var errorCallsCount = 0
            joinPush.receive("error") { (_) in errorCallsCount += 1 }
            
            #expect(errorCallsCount == 1)
        }
        
        @Test("receives 'error' - does not trigger other receive callbacks after error response")
        func errorDoesNotTriggerOtherReceiveCallbacksAfterErrorResponse() async throws {
            var receiveOkCallCount = 0
            var receiveTimeoutCallCount = 0
            var receiveErrorCallCount = 0
            joinPush
                .receive("ok") {_ in receiveOkCallCount += 1 }
                .receive("error", callback: { (_) in
                    receiveErrorCallCount += 1
                    self.channel.leave()
                })
                .receive("timeout") {_ in receiveTimeoutCallCount += 1 }
            
            receiveError()
            receivesTimeout()
            
            #expect(receiveErrorCallCount == 1)
            #expect(receiveOkCallCount == 0)
            #expect(receiveTimeoutCallCount == 0)
        }
        
        @Test("receives 'error' - clears timeoutTimer workItem")
        func errorClearsTimeoutWorkItem() async throws {
            #expect(joinPush.timeoutWorkItem != nil)
            
            receiveError()
            #expect(joinPush.timeoutWorkItem == nil)
        }
        
        @Test("receives 'error' - sets receivedMessage")
        func setsReceivedMessage() async throws {
            #expect(joinPush.receivedMessage == nil)
            
            receiveError()
            #expect(joinPush.receivedMessage != nil)
            #expect(joinPush.receivedMessage?.status == "error")
        }
        
        @Test("receives 'error' - removes channel binding")
        func errorRemovesChannelBinding() async throws {
            var subscription = channel.getChannelSubscription("chan_reply_3")
            #expect(subscription.count == 1)
            
            receiveError()
            subscription = channel.getChannelSubscription("chan_reply_3")
            #expect(subscription.isEmpty)
        }
        
        @Test("receives 'error' - does not sets channel state to joined")
        func doesNotSetChannelsStateToJoined() async throws {
            receiveError()
            #expect(channel.state != .joined)
        }
        
        @Test("receives 'error' - does not trigger channel's buffered pushEvents")
        func doesNotTriggerChannelsBufferedPushEvents() async throws {
            let mockPush = PushSpy(channel: channel, event: "new:msg")
            channel.pushBuffer.append(mockPush)
            
            receiveError()
            #expect(mockPush.sendCalled == false)
            #expect(channel.pushBuffer.count == 1)
        }
    }
    
    @Suite("onError", .serialized)
    class OnError {
        
        let socket: SocketSpy
        let channel: Channel
        let joinPush: Push
        
        let fakeClock: FakeTimerQueue
        
        init() throws {
            fakeClock = FakeTimerQueue()
            TimerQueue.main = fakeClock
            
            let transport = TransportMock()
            transport.readyState = .open
            
            socket = SocketSpy("/socket", transport: { _ in transport })
            socket.connect()
            
            channel = socket.channel("topic", params: ["one": "two"])
            joinPush = channel.joinPush
            
            try channel.join()
            joinPush.trigger("ok", payload: [:])
        }
        
        deinit {
            fakeClock.reset()
        }
        
        
        @Test("sets state to 'errored'")
        func setsStateToErrored() async throws {
            #expect(channel.state != .errored)
            
            channel.trigger(event: "phx_error")
            #expect(channel.state == .errored)
        }
        
        @Test("does not trigger redundant errors during backoff")
        func doesNotTriggerRedundantErrorsDuringBackoff() async throws {
            // Spy the channel's Join Push
            let mockPush = PushSpy(channel: channel, event: "event")
            channel.joinPush = mockPush
            
            #expect(mockPush.sendCallCount == 0)
            channel.trigger(event: ChannelEvent.error)
            
            fakeClock.tick(1.0)
            #expect(mockPush.sendCallCount == 1)
            
            channel.trigger(event: "error")
            fakeClock.tick(1.0)
            #expect(mockPush.sendCallCount == 1)
        }
        
        @Test("does not rejoin if channel leaving")
        func doesNotRejoinIfChannelLeaving() async throws {
            channel.state = .leaving
            
            let mockPush = PushSpy(channel: channel, event: "event")
            channel.joinPush = mockPush
            
            socket.onConnectionError(TestError.stub, response: nil)
            
            fakeClock.tick(1.0)
            #expect(mockPush.sendCallCount == 0)
            
            fakeClock.tick(2.0)
            #expect(mockPush.sendCallCount == 0)
            
            #expect(channel.state == .leaving)
        }
        
        @Test("does not rejoin if channel closed")
        func doesNotRejoinIfChannelClosed() async throws {
            channel.state = .closed
            
            let mockPush = PushSpy(channel: channel, event: "event")
            channel.joinPush = mockPush
            
            socket.onConnectionError(TestError.stub, response: nil)
            
            fakeClock.tick(1.0)
            #expect(mockPush.sendCallCount == 0)
            
            fakeClock.tick(2.0)
            #expect(mockPush.sendCallCount == 0)
            
            #expect(channel.state == .closed)
            
        }
        
        @Test("triggers additional callbacks")
        func triggersAdditionalCallbacks() async throws {
            var onErrorCallCount = 0
            channel.onError({ (_) in onErrorCallCount += 1 })
            joinPush.trigger("ok", payload: [:])
            
            #expect(channel.state == .joined)
            #expect(onErrorCallCount == 0)
            
            channel.trigger(event: "phx_error")
            #expect(onErrorCallCount == 1)
        }
        
        @Test("while joining - resets and removes the joinPush from the send buffer")
        func whileJoiningRemovesTheJoinPushFromSendBuffer() async throws {
            let mockPush = PushSpy(channel: channel, event: "event")
            mockPush.ref = "10"
            
            socket.sendBuffer.withValue { buffer in
                buffer.append(("10", {}))
            }
            
            
            channel.joinPush = mockPush
            channel.state = .joining
            
            channel.trigger(event: ChannelEvent.error)
            #expect(socket.removeFromSendBufferReceivedRef == "10")
            #expect(mockPush.resetCalled)
        }
    }
    
    @Suite("onClose", .serialized)
    class OnClose {
        let socket: SocketSpy
        let channel: Channel
        let joinPush: Push
        
        let fakeClock: FakeTimerQueue
        
        init() throws {
            fakeClock = FakeTimerQueue()
            TimerQueue.main = fakeClock
            
            let transport = TransportMock()
            transport.readyState = .open
            
            socket = SocketSpy("/socket", transport: { _ in transport })
            channel = socket.channel("topic", params: ["one": "two"])
            joinPush = channel.joinPush
            
            try channel.join()
        }
        
        deinit {
            fakeClock.reset()
        }
        
        @Test("sets state to 'closed'")
        func setsStateToClosed() async throws {
            #expect(channel.state != .closed)
            
            channel.trigger(event: "phx_close")
            #expect(channel.state == .closed)
        }
        
        @Test("does not rejoin")
        func doesNotRejoin() async throws {
            let joinPush = PushSpy(channel: channel, event: "phx_join")
            channel.joinPush = joinPush
            
            channel.trigger(event: ChannelEvent.close)
            
            fakeClock.tick(1.0)
            #expect(!joinPush.sendCalled)
            
            fakeClock.tick(2.0)
            #expect(!joinPush.sendCalled)
        }
        
        @Test("resets the rejoin timer")
        func resetsTheRejoinTimer() async throws {
            let mockRejoinTimer = ScheduleTimerMock()
            channel.rejoinTimer = mockRejoinTimer
            
            channel.trigger(event: ChannelEvent.close)
            #expect(mockRejoinTimer.resetCalled)
        }
        
        @Test("triggers additional callbacks")
        func triggersAdditionalCallbacks() async throws {
            var onCloseCallCount = 0
            channel.onClose { _ in onCloseCallCount += 1 }
            
            channel.trigger(event: ChannelEvent.close)
            #expect(onCloseCallCount == 1)
        }
        
        @Test("removes channel from socket")
        func removesChannelFromSocket() async throws {
            channel.trigger(event: ChannelEvent.close)
            #expect(socket.removeCalled)
            #expect(socket.removeReceivedChannel === channel)
        }
    }
    
    @Suite("onMessage")
    struct OnMessage {
        let socket: SocketSpy
        let channel: Channel
    
        init() throws {
            socket = SocketSpy("/socket", transport: { _ in TransportMock() })
            channel = socket.channel("topic", params: ["one": "two"])
        }
        
        @Test("returns message by default")
        func returnsMessageByDefault() async throws {
            let message = channel.onMessage(buildIncomingMessage(event: "original"))
            #expect(message.event == "original")
        }
        
        @Test("can be overridden")
        func canBeOverriden() async throws {
            channel.onMessage = { _ in buildIncomingMessage(event: "modified") }
            
            let message = channel.onMessage(buildIncomingMessage(event: "original"))
            #expect(message.event == "modified")
        }
    }
    
    @Suite("canPush")
    struct CanPush {
        
        let transport: TransportMock
        let socket: SocketSpy
        let channel: Channel
    
        init() throws {
            let transportMock = TransportMock()
            transport = transportMock
            socket = SocketSpy("/socket", transport: { _ in transportMock })
            socket.connect()
            
            channel = socket.channel("topic", params: ["one": "two"])
        }
        
        @Test("returns true when socket connected and channel joined")
        func returnsTrueWhenSocketConnectedAndChannelJoined() async throws {
            channel.state = .joined
            transport.readyState = .open
            
            #expect(channel.canPush)
        }
        
        @Test("otherwise returns false")
        func otherwiseReturnsFalse() async throws {
            channel.state = .joined
            transport.readyState = .closed
            
            #expect(!channel.canPush)
            
            channel.state = .joining
            transport.readyState = .open
            
            #expect(!channel.canPush)
            
            channel.state = .joining
            transport.readyState = .closed
            
            #expect(!channel.canPush)
        }
    }
    
    @Suite("leave")
    struct Leave {
        let socket: SocketSpy
        let channel: Channel
        
        init() throws {
            let transport = TransportMock()
            socket = SocketSpy("/socket", transport: { _ in transport })
            socket.connection = transport
            transport.readyState = .open
            
            channel = socket.channel("topic", params: ["one": "two"])
            try channel.join().trigger("ok", payload: [:])
        }
        
        @Test("unsubscribes from server events")
        func unsubscribesFromServerEvents() async throws {
            socket.makeRefReturnValue = "1"
            
            let joinRef = channel.joinRef
            channel.leave()
            
            #expect(socket.pushOutgoingCalled)
            let outgoingMessage = socket.pushOutgoingReceivedMessage
            #expect(outgoingMessage?.topic == "topic")
            #expect(outgoingMessage?.event == "phx_leave")
            #expect(outgoingMessage?.joinRef == joinRef)
            #expect(outgoingMessage?.ref == "1")
        }
        
        @Test("closes channel on 'ok' from server")
        func closesChanelOnOkfromServer() async throws {
            let socket = Socket("/socket", transport: { _ in TransportMock() })
            
            let channel = socket.channel("topic", params: ["one": "two"])
            try channel.join().trigger("ok", payload: [:])
            
            let anotherChannel = socket.channel("another", params: ["three": "four"])
            #expect(socket.channels.count == 2)
            
            channel.leave().trigger("ok", payload: [:])
            #expect(socket.channels.count == 1)
            #expect(socket.channels.first === anotherChannel)
        }
        
        @Test("sets state to closed on 'ok' event")
        func setsStateToClosedOnOkEvent() async throws {
            #expect(channel.state != .closed)
            
            channel.leave().trigger("ok", payload: [:])
            #expect(channel.state == .closed)
        }
    }
    
    @Suite("on")
    struct OnSuite {
        let socket: SocketSpy
        let channel: Channel
        let kDefaultRef = "1"
        
        init() {
            socket = SocketSpy("/socket", transport: { _ in TransportMock() })
            socket.makeRefReturnValue = kDefaultRef
            channel = socket.channel("topic", params: ["one": "two"])
        }
        
        @Test("sets up callback for event")
        func setsUpCallbackForEvent() async throws {
            var onCallCount = 0
            
            channel.trigger(buildIncomingMessage(ref: kDefaultRef, event: "event"))
            #expect(onCallCount == 0)
            
            channel.on("event", callback: { (_) in
                onCallCount += 1
            })
            
            channel.trigger(buildIncomingMessage(ref: kDefaultRef, event: "event"))
            #expect(onCallCount == 1)
        }
        
        @Test("other event callbacks are ignored")
        func otherEventCallbacksAreIgnored() async throws {
            var onCallCount = 0
            let ignoredOnCallCount = 0
            
            channel.trigger(buildIncomingMessage(ref: kDefaultRef, event: "event"))
            #expect(ignoredOnCallCount == 0)
            
            channel.on("event") { _ in onCallCount += 1 }
            
            channel.trigger(buildIncomingMessage(ref: kDefaultRef, event: "event"))
            #expect(ignoredOnCallCount == 0)
        }
        
        @Test("generates unique refs for callbacks")
        func generatesUniqueRefsForCallbacks() async throws {
            let ref1 = channel.on("event1") { _ in }
            let ref2 = channel.on("event2") { _ in }
            #expect(ref1 != ref2)
            #expect(ref1 + 1 == ref2)
        }
        
        @Test("calls all callbacks for event if they modified during event processing")
        func callsAllCallbacksForEventIfTheyModifiedDuringEventProcessing() async throws {
            channel.bindingRef = 3
            let ref1 = channel.on("event") { _ in
                channel.off("event", ref: 3)
            }
            
            #expect(ref1 == 3)
            
            var onCallCount = 0
            channel.on("event") { _ in
                onCallCount += 1
            }
            
            channel.trigger(buildIncomingMessage(ref: kDefaultRef, event: "event"))
            #expect(onCallCount == 1)
        }
        
        @Test("on data")
        func onData() async throws {
            var data: Data? = nil
            channel.onData("event") { channelMessage in
                data = try! channelMessage.payload.get()
            }
            
            channel.trigger(buildIncomingMessage(event: "event", payload: .decided(Data())))
            
            #expect(data != nil)
        }
        
        @Test("on decodable")
        func onDecodable() async throws {
            var data: TestData? = nil
            channel.onDecodable("event", of: TestData.self) { message in
                data = try! message.payload.get()
            }
            channel.trigger(buildIncomingJsonMessage(event: "event",
                                                     jsonPayload: ["foo": 1]))
            #expect(data?.foo == 1)
            
        }
    }
    // TODO: On AsyncStream/Publisher
    
    
    @Suite("off")
    struct OffSwuite {
        
        let socket: SocketSpy
        let channel: Channel
        let kDefaultRef = "1"
        
        init() {
            socket = SocketSpy("/socket", transport: { _ in TransportMock() })
            socket.makeRefReturnValue = kDefaultRef
            channel = socket.channel("topic", params: ["one": "two"])
        }
        
        @Test("removes all callbacks for event")
        func removesAllCallbacksForEvents() async throws {
            var callCount1 = 0
            var callCount2 = 0
            var callCount3 = 0
            
            channel.on("event", callback: { _ in callCount1 += 1})
            channel.on("event", callback: { _ in callCount2 += 1})
            channel.on("other", callback: { _ in callCount3 += 1})
            
            channel.off("event")
            channel.trigger(buildIncomingMessage(ref: kDefaultRef, event: "event"))
            channel.trigger(buildIncomingMessage(ref: kDefaultRef, event: "other"))
            
            #expect(callCount1 == 0)
            #expect(callCount2 == 0)
            #expect(callCount3 == 1)
        }
        
        @Test("removes callback by ref")
        func removesCallbackByRef() async throws {
            var callCount1 = 0
            var callCount2 = 0
            
            let ref1 = channel.on("event", callback: { _ in callCount1 += 1})
            let _ = channel.on("event", callback: { _ in callCount2 += 1})
            
            channel.off("event", ref: ref1)
            channel.trigger(buildIncomingMessage(ref: kDefaultRef, event: "event"))
            
            #expect(callCount1 == 0)
            #expect(callCount2 == 1)
        }
    }
    
    @Suite("push", .serialized)
    class PushSuite {
        
        let socket: SocketSpy
        let channel: Channel
         
        let fakeClock: FakeTimerQueue
        
        init() {
            fakeClock = FakeTimerQueue()
            TimerQueue.main = fakeClock

            socket = SocketSpy("/socket", transport: { _ in TransportMock() })
            socket.makeRefReturnValue = "1"
            socket.isConnectedReturnValue = true
            
            channel = socket.channel("topic", params: ["one": "two"])
        }
        
        deinit {
            fakeClock.reset()
        }
        
        private func expectSocketPushParamsCalled() {
            let outgoingMessage = socket.pushOutgoingReceivedMessage
            #expect(outgoingMessage?.topic == "topic")
            #expect(outgoingMessage?.event == "event")
            expectJson(outgoingMessage?.payload) { any in
                let json = any as! [String: String]
                #expect(json["foo"] == "bar")
            }
            #expect(outgoingMessage?.joinRef == channel.joinRef)
            #expect(outgoingMessage?.ref == "1")
        }
        
        private func refuteSocketPushParamsCalled() {
            let outgoingMessage = socket.pushOutgoingReceivedMessage
            #expect(outgoingMessage?.event != "event")
            expectJson(outgoingMessage?.payload) { any in
                let json = any as! [String: String]
                #expect(json["foo"] != "bar")
            }
        }
        
        
        @Test("sends push event when successfully joined")
        func sendsPushEventWhenSuccessfullyJoined() throws {
            try channel.join().trigger("ok", payload: [:])
            try channel.push("event", payload: ["foo": "bar"])
            
            #expect(socket.pushOutgoingCalled)
            expectSocketPushParamsCalled()
        }
        
        @Test("enqueues push event to be sent once join has succeeded")
        func enqueuesPushEventToBeSentOnceJoinHasSucceeded() throws {
            let joinPush = try channel.join()
            try channel.push("event", payload: ["foo": "bar"])
            
            refuteSocketPushParamsCalled()
            
            fakeClock.tick(channel.timeout / 2)
            joinPush.trigger("ok", payload: [:])
            
            expectSocketPushParamsCalled()
        }
        
        @Test("does not push if channel join times out")
        func doesNotPushIfChannelJoinTimesOut() throws {
            let joinPush = try channel.join()
            try channel.push("event", payload: ["foo": "bar"])
            
            refuteSocketPushParamsCalled()
            
            fakeClock.tick(channel.timeout * 2)
            joinPush.trigger("ok", payload: [:])
            
            refuteSocketPushParamsCalled()
        }
        
        @Test("uses channel timeout by default")
        func usesChannelTimeoutByDefault() throws {
            try channel.join().trigger("ok", payload: [:])
            
            var timeoutCallsCount = 0
            try channel
                .push("event", payload: ["foo": "bar"])
                .receive("timeout") { _ in
                    timeoutCallsCount += 1
                }
            
            fakeClock.tick(channel.timeout / 2)
            #expect(timeoutCallsCount == 0)
            
            fakeClock.tick(channel.timeout)
            #expect(timeoutCallsCount == 1)
        }
        
        @Test("accepts timeout arg")
        func acceptsTimeoutArg() async throws {
            try channel.join().trigger("ok", payload: [:])
            
            var timeoutCallsCount = 0
            try channel
                .push("event", payload: ["foo": "bar"], timeout: channel.timeout * 2)
                .receive("timeout") { _ in
                    timeoutCallsCount += 1
                }
            
            fakeClock.tick(channel.timeout)
            #expect(timeoutCallsCount == 0)
            
            fakeClock.tick(channel.timeout * 2)
            #expect(timeoutCallsCount == 1)
        }
        
        @Test("does not time out after receiving 'ok'")
        func doesNotTimeOutAfterReceivingOk() async throws {
            try channel.join().trigger("ok", payload: [:])
            
            var timeoutCallsCount = 0
            let push = try channel.push("event", payload: ["foo": "bar"])
            push.receive("timeout") { _ in
                timeoutCallsCount += 1
            }
            
            fakeClock.tick(channel.timeout / 2)
            #expect(timeoutCallsCount == 0)
            
            push.trigger("ok", payload: [:])
            
            fakeClock.tick(channel.timeout)
            #expect(timeoutCallsCount == 0)
        }
        
        @Test("throws if channel has not been joined")
        func throwsIfCHannelHasNotBeenJoined() async throws {
            
            #expect(performing: {
                try channel.push("event", payload: [:])
            }, throws: { error in
                switch error as! ChannelError {
                case .pushTriedBeforeJoin(let topic, let event):
                    #expect(event == "event")
                    #expect(topic == "topic")
                    return true
                default: return false
                }
            })
        }
    }
    
    @Suite("isMemeber")
    struct IsMember {
        let socket: SocketSpy
        let channel: Channel
        
        init() throws {
            socket = SocketSpy("/socket", transport: { _ in TransportMock() })
            channel = socket.channel("t", params: ["one": "two"])
        }
        
        @Test("returns false if the message topic does not match the channel")
        func topicDoesNotMatch() async throws {
            let message = buildIncomingMessage(topic: "other")
            #expect(!channel.isMember(message))
        }
        
        @Test("returns true if topics match but the message doesn't have a join ref")
        func topicsMatchButMessageDoesntHaveJoinRef() async throws {
            let message = buildIncomingMessage(event: ChannelEvent.close)
            #expect(channel.isMember(message))
        }
        
        @Test("returns true if topics and join refs match")
        func topicsAndJoinRefsMatch() async throws {
            channel.joinPush.ref = "2"
            let message = buildIncomingMessage(joinRef: "2", event: ChannelEvent.close)
            #expect(channel.isMember(message))
        }
        
        @Test("returns true if topics and join refs match but event is not lifecycle")
        func topicsAndJoinRefsMatchButNotLifecycleEvent() async throws {
            channel.joinPush.ref = "2"
            let message = buildIncomingMessage(joinRef: "2")
            #expect(channel.isMember(message))
        }
        
        @Test("returns false topics match and is a lifecycle event but join refs do not match ")
        func topicsMatchAndLifecycleEventButRefsDontMatch() async throws {
            channel.joinPush.ref = "2"
            let message = buildIncomingMessage(joinRef: "1", event: ChannelEvent.close)
            #expect(!channel.isMember(message))
        }
    }
    
    
    @Suite("state helpers")
    struct StateHelpers {
        let socket: SocketSpy
        let channel: Channel
        
        init() throws {
            socket = SocketSpy("/socket", transport: { _ in TransportMock() })
            channel = socket.channel("topic", params: ["one": "two"])
        }
        
        @Test("isClosed returns true if state is .closed")
        func isClosed() async throws {
            channel.state = .joined
            #expect(!channel.isClosed)
            
            channel.state = .closed
            #expect(channel.isClosed)
        }
        
        @Test("isErrored returns true if state is .errored")
        func isErrored() async throws {
            channel.state = .joined
            #expect(!channel.isErrored)
            
            channel.state = .errored
            #expect(channel.isErrored)
        }
        
        @Test("isJoined returns true if state is .joined")
        func isJoined() async throws {
            channel.state = .joining
            #expect(!channel.isJoined)
            
            channel.state = .joined
            #expect(channel.isJoined)
        }
        
        @Test("isLeaving returns true if state is .leaving")
        func isLeaving() async throws {
            channel.state = .joined
            #expect(!channel.isLeaving)
            
            channel.state = .leaving
            #expect(channel.isLeaving)
        }
    }
}
