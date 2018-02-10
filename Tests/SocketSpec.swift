//
//  SocketSpec.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 2/10/18.
//

import Quick
import Nimble
@testable import SwiftPhoenixClient

class SocketSpec: QuickSpec {
    
    override func spec() {
        
        describe(".init(url:, params:)") {
            it("should construct a valid URL", closure: {
                
                // Test different schemes
                expect(Socket(url: "http://localhost:4000/socket/websocket")
                    .endpoint.absoluteString)
                    .to(equal("http://localhost:4000/socket/websocket"))
                
                expect(Socket(url: "https://localhost:4000/socket/websocket")
                    .endpoint.absoluteString)
                    .to(equal("https://localhost:4000/socket/websocket"))
                
                expect(Socket(url: "ws://localhost:4000/socket/websocket")
                    .endpoint.absoluteString)
                    .to(equal("ws://localhost:4000/socket/websocket"))
                
                expect(Socket(url: "wss://localhost:4000/socket/websocket")
                    .endpoint.absoluteString)
                    .to(equal("wss://localhost:4000/socket/websocket"))
                
                
                // test params
                expect(Socket(url: "ws://localhost:4000/socket/websocket",
                              params: ["token": "abc123"])
                    .endpoint.absoluteString)
                    .to(equal("ws://localhost:4000/socket/websocket?token=abc123"))
                
                expect(Socket(url: "ws://localhost:4000/socket/websocket",
                              params: ["token": "abc123", "user_id": 1])
                    .endpoint.absoluteString)
                    .to(equal("ws://localhost:4000/socket/websocket?token=abc123&user_id=1"))
                
                
                // test params with spaces
                expect(Socket(url: "ws://localhost:4000/socket/websocket",
                              params: ["token": "abc 123", "user_id": 1])
                    .endpoint.absoluteString)
                    .to(equal("ws://localhost:4000/socket/websocket?token=abc%20123&user_id=1"))
            })
        }
        
    }
}

