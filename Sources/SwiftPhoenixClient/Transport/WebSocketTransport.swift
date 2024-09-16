//
//  WebSocketTransport.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 9/14/24.
//  Copyright © 2024 SwiftPhoenixClient. All rights reserved.
//

import Foundation


open class WebSocketTransport: NSObject, URLSessionWebSocketDelegate, Transport {

    /// The URL to connect to
    internal let url: URL
    
    /// The URLSession configuration
    internal let configuration: URLSessionConfiguration
    
    /// Serializer converts data or json string into a `SocketMessage` to be consumed by the caller
    internal let serializer: Serializer
    
    /// The continuation that publishes messages to the async stream of messages
    private let messagesContinuation: AsyncThrowingStream<SocketMessage, Error>.Continuation
    
    /// The continuation that publishes during socket connection
    private let connectContinuation: CheckedContinuation<Never, any Error>? = nil
    
    /// The underling URLSession. Assigned during `connect()`
    private var session: URLSession? = nil
    
    /// The delegate that receives open/close information when connecting
    private var websocketTaskDelegate: WebSocketTaskDelegate? = nil
    
    /// The ongoing task. Assigned during `connect()`
    private var task: URLSessionWebSocketTask? = nil
    
    
    /// Initializes a `Transport` that is backed by URLSession's WebSocketTask. If URL does not use the `ws`/`wss`
    /// protocol, then it will automatically be updated from `http`/`https` to its respective `ws`/`wss` protocol.
    ///
    /// A custom `URLSessionConfiguration` can be passed in as well to further customize the behavior of `URLSession`
    /// when creating the `URLSessionWebsocketTask`. Otherwise the `.default` one will be used.
    ///
    /// Example:
    ///
    ///     ```swift
    ///     let url = URL("wss://example.com/socket")
    ///     let transport: Transport = WebsocketTransport(url: url)
    ///     ```
    ///
    /// Example:
    ///
    ///     ```swift
    ///     let url = URL("https://example.com/socket")
    ///     let configuration = URLSessionConfiguration.ephemeral
    ///     let transport: Transport = WebsocketTransport(url: url, configuration: configuration)
    ///     ```
    ///
    public init(
        url: URL,
        serializer: Serializer,
        configuration: URLSessionConfiguration = .default
    ) {
        // URLSessionWebSocketTask requires that the endpoint be "wss" instead of "https".
        let endpoint = url.absoluteString
        let wsEndpoint = endpoint
          .replacingOccurrences(of: "http://", with: "ws://")
          .replacingOccurrences(of: "https://", with: "wss://")
        
        // Force unwrapping should be safe here since a valid URL came in and we just
        // replaced the protocol.
        self.url = URL(string: wsEndpoint)!
        self.configuration = configuration
        self.serializer = serializer
        
        let (stream, continuation) = AsyncThrowingStream
            .makeStream(of: SocketMessage.self, throwing: Error.self)
        
        self.messages = stream
        self.messagesContinuation = continuation
    }
    
    
    // MARK: - Transport
    public let messages: AsyncThrowingStream<SocketMessage, Error>
    public private(set) var readyState: TransportReadyState = .closed
    
    
    public func connect(with headers: [String : Any]) async throws {
        // Set the transport state as connecting
        self.readyState = .connecting
        
        try await withCheckedThrowingContinuation { continuation in
            // Create the session and websocket task
            self.websocketTaskDelegate = WebSocketTaskDelegate(
                onWebSocketTaskDidOpen: { string in
                    // Mark the socket as open and
                    self.readyState = .open
                    
                    // Resume the async call, signalling that the socket has connected
                    continuation.resume()
                    
                    // Start listening for messages received from the server.
                    self.receive()
                },
                onWebSocketTaskDidClose: { closeCode, data in
                    // A close frame was received from the server.
                    self.readyState = .closed
                    
                    // No more messages will be received
                    self.messagesContinuation.finish()
                    
                    // Stop listening for connection events
                    self.websocketTaskDelegate = nil
                    
                    
                },
                onWebSocketTaskDidCompleteWithError: { error in
                    // Only propagate errors that occur during the process of connecting the socket.
                    if let error, self.readyState == .connecting {
                        continuation.resume(throwing: error)
                    }
                }
            )
            
            self.session = URLSession(
                configuration: self.configuration,
                delegate: self.websocketTaskDelegate,
                delegateQueue: nil
            
            )
            var request = URLRequest(url: url)
              
            headers.forEach { (key: String, value: Any) in
                guard let value = value as? String else { return }
                request.addValue(value, forHTTPHeaderField: key)
            }
              
            self.task = self.session?.webSocketTask(with: request)
        }
    }
    
    public func disconnect(code: Int, reason: String?) {
        
    }
    
    public func send(data: Data) async throws {
        try await self.send(.data(data))
    }
    
    public func send(string: String) async throws {
        try await self.send(.string(string))
    }
    
    // MARK: - Private
    private func send(_ message: URLSessionWebSocketTask.Message) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.task?.send(message) { error in
                if let error {
                    continuation.resume(with: .failure(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    private func receive() {
        self.task?.receive { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(.data(let data)):
                let socketMessage = self.serializer.binaryDecode(data: data)
                self.messagesContinuation.yield(socketMessage)
                self.receive()

            case .success(.string(let string)):
                let socketMessage = self.serializer.decode(text: string)
                self.messagesContinuation.yield(socketMessage)
                self.receive()

            case .failure(let error):
                self.messagesContinuation.finish(throwing: error)

            default:
                break
            }
        }
    }
    
    // MARK: - URLSessionWebSocketDelegate
    open func urlSession(_ session: URLSession,
                         webSocketTask: URLSessionWebSocketTask,
                         didOpenWithProtocol protocol: String?) {
      // The Websocket is connected. Set Transport state to open and inform delegate
      self.readyState = .open
        
//      self.delegate?.onOpen(response: webSocketTask.response)
      
      // Start receiving messages
      self.receive()
    }
    
    open func urlSession(_ session: URLSession,
                         webSocketTask: URLSessionWebSocketTask,
                         didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                         reason: Data?) {
      // A close frame was received from the server.
      self.readyState = .closed
//      self.delegate?.onClose(code: closeCode.rawValue, reason: reason.flatMap { String(data: $0, encoding: .utf8) })
    }
    
    open func urlSession(_ session: URLSession,
                         task: URLSessionTask,
                         didCompleteWithError error: Error?) {
      // The task has terminated. Inform the delegate that the transport has closed abnormally
      // if this was caused by an error.
      guard let err = error else { return }
      
//      self.abnormalErrorReceived(err, response: task.response)
    }
}


private class WebSocketTaskDelegate: NSObject, URLSessionWebSocketDelegate {
    private let onWebSocketTaskDidOpen: (_ protocol: String?) -> Void
    private let onWebSocketTaskDidClose: (_ code: URLSessionWebSocketTask.CloseCode, _ reason: Data?) -> Void
    private let onWebSocketTaskDidCompleteWithError: (_ error: Error?) -> Void

    init(
        onWebSocketTaskDidOpen: @escaping (_: String?) -> Void,
        onWebSocketTaskDidClose: @escaping (_: URLSessionWebSocketTask.CloseCode, _: Data?) -> Void,
        onWebSocketTaskDidCompleteWithError: @escaping (_: Error?) -> Void
    ) {
        self.onWebSocketTaskDidOpen = onWebSocketTaskDidOpen
        self.onWebSocketTaskDidClose = onWebSocketTaskDidClose
        self.onWebSocketTaskDidCompleteWithError = onWebSocketTaskDidCompleteWithError
    }

    public func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol proto: String?
    ) {
        onWebSocketTaskDidOpen(proto)
    }

    public func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        onWebSocketTaskDidClose(closeCode, reason)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        onWebSocketTaskDidCompleteWithError(error)
    }
}

