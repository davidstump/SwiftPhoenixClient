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

@Suite("Channel")
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
            
            #expect(throws: ChannelError.alreadyJoined, performing: {
                try channel.join()
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
        
        @Suite("timeout behavior")
        class TimeoutBehavior {
            
            let transport: TransportMock
            let socket: SocketSpy
            let channel: Channel
            let joinPush: Push
            
            let fakeClock: FakeTimerQueue
            
            init() {
                let transport = TransportMock()
                self.transport = transport
                socket  = SocketSpy("/socket", transport: { _ in transport })
                socket.timeout = 10.0
                channel = socket.channel("topic", params: ["one": "two"])
                joinPush = channel.joinPush
                
                fakeClock = FakeTimerQueue()
                TimerQueue.main = fakeClock
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
            func retriesWithBackoff
        }
    }
}
