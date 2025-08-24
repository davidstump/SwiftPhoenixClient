//
//  URLSessionWebSocket.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 8/20/25.
//  Copyright © 2025 SwiftPhoenixClient. All rights reserved.
//

import Foundation

/// A `URLSession` implementation of the `WebSocket` protocol
final class URLSessionWebSocket: WebSocket {
    
    /// Thread-safe mutable state for the WebSocket connection.
    private struct MutableState {
        var readyState: WebSocketReadyState = .closed
        var onEvent: (@Sendable (WebSocketEvent) -> Void)? = nil
    }
    
    /// Lock-isolated mutable state to ensure thread safety.
    private let mutableState = LockIsolated(MutableState())
    
    /// The underlying URLSessionWebSocketTask connected to the peer.
    private let task: URLSessionWebSocketTask
    
    /// The subprotocol negotiated with the peer upon connection.
    private let subProtocol: String?
    
    
    private init(
        task: URLSessionWebSocketTask,
        subProtocol: String?
    ) {
        self.task = task
        self.subProtocol = subProtocol
        
        
        self.mutableState.withValue { state in
            state.readyState = .open
        }
        scheduleReceive()
    }
    
    // MARK: Private Internal Helpers
    private func handleReceivedResult(_ result: Result<URLSessionWebSocketTask.Message, Error>) {
        switch result {
        case .success(let value):
            handleMessage(value)
        case .failure(let error):
            closeConnection(with: error)
        }
    }
    
    private func handleMessage(_ value: URLSessionWebSocketTask.Message) {
        guard !isClosed else { return }
        
        let event: WebSocketEvent
        switch value {
        case .string(let text):
            event = .text(text)
        case .data(let data):
            event = .binary(data)
        @unknown default:
            // Handle unknown message types gracefully by closing the connection
            closeConnection(with: WebSocketError.connection(
                message: "Received unsupported message type",
                error: NSError(
                    domain: "WebSocketError",
                    code: URLSessionWebSocketTask.CloseCode.protocolError.rawValue,
                    userInfo: [NSLocalizedDescriptionKey: "Unsupported message type"]
                )
            )
            )
            return
        }
        
        trigger(event)
        scheduleReceive()
    }
    
    private func scheduleReceive() {
        if #available(iOS 17.0, *) {
            awaitReceive()
        } else {
            receiveAsCallback()
        }
    }
    
    private func awaitReceive() {
        Task {
            let result = await { () async -> Result<URLSessionWebSocketTask.Message, Error> in
                do {
                    let message = try await task.receive()
                    return .success(message)
                } catch {
                    return .failure(error)
                }
            }()
            
            handleReceivedResult(result)
        }
    }
    
    private func receiveAsCallback() {
        self.task.receive { [weak self] result in
            self?.handleReceivedResult(result)
        }
    }
    
    
    private func closeConnection(with error: any Error) {
        let nsError = error as NSError
        
        // Handle socket not connected error - delegate callbacks will handle this
        if nsError.domain == NSPOSIXErrorDomain && nsError.code == 57 {
            // Socket is not connected.
            // onClosed/onComplete will be invoked and may indicate a close code.
            return
        }
        
        // Map errors to appropriate WebSocket close codes per RFC 6455
        let (code, reason): (URLSessionWebSocketTask.CloseCode, String) = {
            switch (nsError.domain, nsError.code) {
            case (NSPOSIXErrorDomain, 100):
                // Network protocol error
                return (
                    URLSessionWebSocketTask.CloseCode.protocolError,
                    nsError.localizedDescription
                )
            case (NSURLErrorDomain, NSURLErrorTimedOut):
                // Connection timeout
                return (
                    URLSessionWebSocketTask.CloseCode.abnormalClosure,
                    "Connection timed out"
                )
            case (NSURLErrorDomain, NSURLErrorNetworkConnectionLost):
                // Network connection lost
                return (
                    URLSessionWebSocketTask.CloseCode.abnormalClosure,
                    "Network connection lost"
                )
            case (NSURLErrorDomain, NSURLErrorNotConnectedToInternet):
                // No internet connection
                return (
                    URLSessionWebSocketTask.CloseCode.abnormalClosure,
                    "No internet connection"
                )
            default:
                // Abnormal closure for other errors
                return (
                    URLSessionWebSocketTask.CloseCode.abnormalClosure,
                    nsError.localizedDescription
                )
            }
        }()
        
        task.cancel()
        connectionClosed(code: code, reason: Data(reason.utf8))
    }
    
    /// Handles the connection being closed and triggers the close event.
    /// - Parameters:
    ///   - code: The WebSocket close code, if available.
    ///   - reason: The close reason data, if available.
    private func connectionClosed(
        code: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        guard !isClosed else { return }
        self.mutableState.withValue { state in
            state.readyState = .closed
        }
        
        let closeReason = reason.map { String(decoding: $0, as: UTF8.self) } ?? ""
        trigger(.close(code: code.rawValue, reason: closeReason))
    }
    
    private func trigger(_ event: WebSocketEvent) {
        mutableState.withValue { state in
            state.onEvent?(event)
            
            if case .close(_, _) = event {
                state.onEvent = nil
                state.readyState = .closed
            }
        }
    }
    
    // MARK: WebSocket
    var readyState: WebSocketReadyState {
        mutableState.value.readyState
    }
    
    var isClosed: Bool {
        mutableState.value.readyState == .closed
    }
    
    var onEvent: (@Sendable (WebSocketEvent) -> Void)? {
        get { mutableState.value.onEvent }
        set {
            mutableState.withValue { state in
                state.onEvent = newValue
            }
        }
    }
    
    func send(data: Data) {
        self.send(.data(data))
    }
    func send(string: String) {
        self.send(.string(string))
    }
    
    private func send(_ message: URLSessionWebSocketTask.Message) {
        guard !isClosed else { return }
        Task {
            do {
                try await task.send(message)
            } catch {
                closeConnection(with: error)
            }
        }
    }
    
    func disconnect(code: URLSessionWebSocketTask.CloseCode, reason: String?) {
        guard !isClosed else { return }
        
        // Validate reason length per RFC 6455
        if let reason = reason, reason.utf8.count > 123 {
            preconditionFailure("Close reason must be ≤ 123 bytes when UTF-8 encoded")
        }
        
        mutableState.withValue { state in
            guard state.readyState != .closed else { return }
            
            state.readyState = .closing
            self.task.cancel(with: code, reason: reason?.data(using: .utf8))
        }
    }
}

// MARK: - Internal URLSession Delegate
private final class Delegate: NSObject, URLSessionWebSocketDelegate {
    
    typealias OnOpenCallback = @Sendable (URLSession,
                                          URLSessionWebSocketTask,
                                          String?) -> Void
    typealias OnCloseCallback = @Sendable (URLSession,
                                           URLSessionWebSocketTask,
                                           URLSessionWebSocketTask.CloseCode,
                                           Data?) -> Void
    typealias OnCompleteCallback = @Sendable (URLSession,
                                              URLSessionTask,
                                              (any Error)?) -> Void
    
    let onOpen: OnOpenCallback?
    let onClose: OnCloseCallback?
    let onComplete: OnCompleteCallback?
    
    init(
        onOpen: OnOpenCallback?,
        onClose: OnCloseCallback?,
        onComplete: OnCompleteCallback?
    ) {
        self.onOpen = onOpen
        self.onClose = onClose
        self.onComplete = onComplete
    }
    
    
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        self.onOpen?(session, webSocketTask, `protocol`)
    }
    
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        self.onClose?(session, webSocketTask, closeCode, reason)
    }
    
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: (any Error)?) {
        self.onComplete?(session, task, error)
    }
}


extension URLSessionWebSocket {
    /// Creates and returns a new WebSocket object and immediately
    /// attempts to establish a connection to the specified WebSocket URL.
    /// - Parameter url: The URL of the target WebSocket server to connect to.
    ///     The URL must use one of the following schemes: ws, wss, http, or https.
    /// - Parameter configuration: A URLSessionConfiguration which can be used to add
    ///     headers or further configure the underling URLSession used to drive the
    ///     URLSessoinWebSocketTask.
    /// - Parameter protocols: An array of strings representing the sub-protocol(s)
    ///     that the client would like to use, in order of preference. If it is
    ///      omitted, an empty array is used by default, i.e., [].
    static func connect(
        to url: URL,
        configuration: URLSessionConfiguration = .default,
        protocols: [String] = []
    ) async throws -> URLSessionWebSocket {
        // `http` and `https` are acceptable, but will be replaced with `ws` or `wss
        // respectively.
        let wsUrl = { () -> URL in
            if url.scheme == "ws" || url.scheme == "wss" {
                return url
            } else {
                // URLSession requires that the endpoint be "wss" instead of "https".
                let endpoint = url.absoluteString
                let wsEndpoint = endpoint
                    .replacingOccurrences(of: "http://", with: "ws://")
                    .replacingOccurrences(of: "https://", with: "wss://")
                return URL(string: wsEndpoint)!
            }
        }()
        
        
        // Holds the created WebSocket to be returned after connection
        struct MutableState {
            var continuation: CheckedContinuation<URLSessionWebSocket, any Error>!
            var webSocket: URLSessionWebSocket?
        }
        let mutableState = LockIsolated(MutableState())
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        let delegate = Delegate(
            onOpen: { urlSession, wsTask, withProtocol in
                mutableState.withValue { state in
                    let websocket = URLSessionWebSocket(task: wsTask, subProtocol: withProtocol)
                    state.webSocket = websocket
                    state.continuation.resume(returning: websocket)
                }
            },
            onClose: { urlSession, wsTask, closeCode, reason in
                mutableState.withValue { state in
                    assert(state.webSocket != nil, "connection should exist by this time")
                    state.webSocket?.connectionClosed(code: closeCode, reason: reason)
                }
            },
            onComplete: { urlSession, wsTask, error in
                mutableState.withValue { state in
                    if let webSocket = state.webSocket {
                        webSocket.connectionClosed(code: .abnormalClosure,
                                                   reason: Data("abnormal close".utf8))
                    } else if let error {
                        state.continuation
                            .resume(
                                throwing: WebSocketError.connection(
                                    message: "connection ended unexpectedly",
                                    error: error
                                )
                            )
                    } else {
                        // `onWebSocketTaskOpened` should have been called and resumed continuation.
                        // So either there was an error creating the connection or a logic error.
                        assertionFailure(
                            "expected an error or `onOpen` to have been called first"
                        )
                    }
                }
            }
        )
        
        let session = URLSession(
            configuration: configuration,
            delegate: delegate,
            delegateQueue: queue
        )
        
        session.webSocketTask(with: wsUrl, protocols: protocols).resume()
        return try await withCheckedThrowingContinuation { continuation in
            mutableState.withValue { state in
                state.continuation = continuation
            }
        }
    }
}
