//
//  Mocks.swift
//  SwiftPhoenixClientTests
//
//  Created by Daniel Rees on 5/18/18.
//

import Starscream
@testable import SwiftPhoenixClient

/// Mocks method calls to the Starscrean WebSocket class
class WebSocketMock: WebSocket {
    
    var disconnectCallsCount = 0
    var disconnectCalled: Bool { return disconnectCallsCount > 0 }
    func disconnect() {
        disconnectCallsCount += 1
    }
    
    var connectCallsCount = 0
    var connectCalled: Bool { return connectCallsCount > 0 }
    override func connect() {
        connectCallsCount += 1
    }
}

class SocketMock: Socket {
    
    init() {
        let mockWebSocket = WebSocketMock(url: URL(string: "http://localhost:4000/socket/websocket")!)
        super.init(connection: mockWebSocket)
    }
}
