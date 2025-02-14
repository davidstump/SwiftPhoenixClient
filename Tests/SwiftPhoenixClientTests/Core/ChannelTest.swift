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
    
        
        @Test
        func setsDefaults() async throws {
            let channel = Channel(topic: "topic", params: ["one": "two"], socket: socket)
            
            #expect(channel.state == .closed)
            #expect(channel.topic == "topic")
            #expect(channel.params["one"] as! String == "two")
            #expect(channel.socket === socket)
            #expect(channel.timeout == 1234)
            #expect(channel.joinedOnce == false)
            #expect(channel.joinPush != nil)
            #expect(channel.pushBuffer.isEmpty)
        }
        
        @Test func setsUpJoinPushObjectWithLiteralParams() async throws {
            let channel = Channel(topic: "topic", params: ["one": "two"], socket: socket)
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
    
    
    
}
