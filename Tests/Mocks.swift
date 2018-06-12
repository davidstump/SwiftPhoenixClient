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
    
    var underlyingIsConnected: Bool!
    override var isConnected: Bool {
        get { return underlyingIsConnected }
        set(value) { underlyingIsConnected = value }
    }
    
    
    init() {
        let mockWebSocket = WebSocketMock(url: URL(string: "http://localhost:4000/socket/websocket")!)
        super.init(connection: mockWebSocket)
    }
    
    
    var pushCallsCount = 0
    var pushCalled: Bool { return pushCallsCount > 0 }
    var pushArgs: (topic: String, event: String, payload: Payload, ref: String?, joinRef: String?)?
    override func push(topic: String, event: String, payload: Payload, ref: String?, joinRef: String?) {
        pushCallsCount += 1
        pushArgs = (topic, event, payload, ref, joinRef)
    }
    
    
    var makeRefCallsCount = 0
    var makeRefCalled: Bool { return makeRefCallsCount > 0 }
    var makeRefReturnValue: String?
    override func makeRef() -> String {
        guard let stubbedValue = makeRefReturnValue else { return super.makeRef() }
        return stubbedValue
    }
    


}
