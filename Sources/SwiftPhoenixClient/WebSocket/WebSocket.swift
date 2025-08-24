//
//  Websocket.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 8/20/25.
//  Copyright © 2025 SwiftPhoenixClient. All rights reserved.
//

import Foundation

/// Available `ReadyState`s of a `Websocket`.
public enum WebSocketReadyState: Sendable {
    
    /// The `Websocket` is opening a connection to the server.
    case connecting
    
    /// The `Websocket` is connected to the server.
    case open
    
    /// The `Websocket` is closing the connection to the server.
    case closing
    
    /// The `Websocket` has disconnected from the server.
    case closed
}

public enum WebSocketEvent: Sendable {
    /// The connection was opened
    case open(URLResponse?)
    
    /// A text frame was received
    case text(String)
    
    /// A binary frame was received
    case binary(Data)
    
    /// The connection was closed.
    case close(code: Int, reason: String?)
}

/// Represents errors that can occur on a WebSocket connection.
enum WebSocketError: Error, LocalizedError {
  /// An error occurred while connecting to the peer.
  case connection(message: String, error: any Error)

  var errorDescription: String? {
    switch self {
    case .connection(let message, let error): "\(message) \(error.localizedDescription)"
    }
  }
}

/// Defines a connection to a peer over a websocket.
public protocol WebSocket: Sendable, AnyObject {
    
    /// The current `ReadyState` of the connection.
    var readyState: WebSocketReadyState { get }
    
    /// True if the connection is closed.
    var isClosed: Bool { get }
    
    /// A lambda callback of ``WebSocketEvent`` received from the peer.
    var onEvent: (@Sendable (WebSocketEvent) -> Void)? { get set }
    
    /// Sends a data message to the server.
    ///
    /// - Parameter data: Data to send.
    func send(data: Data)
    
    /// Sends a string message to the peer.
    ///
    /// - Parameter string: String to send.
    func send(string: String)
    
    /// Disconnect from the peer.
    ///
    /// - Parameters:
    ///    - code: Status code as defined by <ahref="http://tools.ietf.org/html/rfc6455#section-7.4">Section 7.4 of RFC 6455</a>.
    ///    - reason: Reason why the connection is closing. Optional.
    func disconnect(code: URLSessionWebSocketTask.CloseCode, reason: String?)
    
}

extension WebSocket {
    
    /// An `AsyncStream` of ``WebSocketEvent`` received from the peer.
    var events: AsyncStream<WebSocketEvent> {
        let (stream, continuation) = AsyncStream<WebSocketEvent>.makeStream()
        self.onEvent = { event in
            continuation.yield(event)
            
            if case .close = event {
                continuation.finish()
            }
        }
        
        continuation.onTermination = { _ in
            self.onEvent = nil
        }
        return stream
    }
}

