//
//  Transport.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 2/2/25.
//  Copyright © 2025 SwiftPhoenixClient. All rights reserved.
//

import Foundation

public protocol TransportV2: Sendable {
    
    func connect(to url: URL) async throws -> URLSessionWebSocket
    func connect(to url: URL, protocols: [String]) async throws -> URLSessionWebSocket
}



/// Defines a `Socket`'s Transport layer.
// sourcery: AutoMockable
public protocol Transport {
    
    /// The current `ReadyState` of the `Transport` layer
    var readyState: TransportReadyState { get }
    
    /// Delegate for the `Transport` layer
    var delegate: TransportDelegate? { get set }
    
    /// Connect to the server
    ///
    /// - Parameters:
    ///    - headers: Headers to include in the URLRequests when opening the Websocket connection. Can be empty [:]
    func connect(with headers: [String: Any])
    
    /// Disconnect from the server.
    ///
    /// - Parameters:
    ///    - code: Status code as defined by <ahref="http://tools.ietf.org/html/rfc6455#section-7.4">Section 7.4 of RFC 6455</a>.
    ///    - reason: Reason why the connection is closing. Optional.
    func disconnect(code: URLSessionWebSocketTask.CloseCode, reason: String?)
    
    /// Sends a data message to the server.
    ///
    /// - Parameter data: Data to send.
    func send(data: Data)
    
    /// Sends a string message to the server.
    ///
    /// - Parameter string: String to send.
    func send(string: String)
}
