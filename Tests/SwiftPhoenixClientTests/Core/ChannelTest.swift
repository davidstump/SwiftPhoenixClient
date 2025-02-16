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

@Suite("Channel") struct ChannelTest {
    
    @Suite("constructor")
    struct Constructor {
    
        let socket: SocketSpy
        
        init() {
            socket = SocketSpy(endPoint: "/", transport: { _ in TransportMock() })
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
        let socket = SocketSpy(endPoint: "/", transport: { _ in TransportMock() })
        
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
        
        let socket = Socket("/socket")
        let channel: Channel
        
        init() {
            channel = socket.channel("topic", params: ["one": "two"])
        }
        
        @Test("sets state to joining")
        func testJoining() async throws {
            channel.join()
            #expect(channel.state == .joining)
        }
        
        @Test("sets joinedOnce to true")
        func testJoinedOnce() async throws {
            #expect(channel.joinedOnce == false)
            channel.join()
            #expect(channel.joinedOnce == true)
        }
        
        @Test("throws if attempting to join multiple times")
        func testJoinsMultipleTimes() async throws {
            channel.join()
            
        }
    }
}
