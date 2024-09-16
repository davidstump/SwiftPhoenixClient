//
//  Transport.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 9/14/24.
//  Copyright © 2024 SwiftPhoenixClient. All rights reserved.
//

import Foundation


public protocol Transport {
    
    /// The current `ReadyState` of the `Transport` layer
    var readyState: TransportReadyState { get }
    
    /// The async stream of messages received by the socket
    var messages: AsyncThrowingStream<SocketMessage, Error> { get }
    
    /// Connect to the server
    ///
    /// - Parameters:
    /// - headers: Headers to include in the URLRequests when opening the Websocket connection. Can be empty [:]
    func connect(with headers: [String: Any]) async throws
    
    /// Disconnect from the server.
    ///
    /// - Parameters:
    /// - code: Status code as defined by <ahref="http://tools.ietf.org/html/rfc6455#section-7.4">Section 7.4 of RFC 6455</a>.
    /// - reason: Reason why the connection is closing. Optional.
    func disconnect(code: Int, reason: String?)
    
    /// Sends the given `data` through the websocket.
    func send(data: Data) async throws
    
    /// Sends the given `string` through the websocket.
    func send(string: String) async throws
}


/// Available `ReadyState`s of a `Transport` layer.
public enum TransportReadyState {
  
  /// The `Transport` is opening a connection to the server.
  case connecting
  
  /// The `Transport` is connected to the server.
  case open
  
  /// The `Transport` is closing the connection to the server.
  case closing
  
  /// The `Transport` has disconnected from the server.
  case closed
  
}
