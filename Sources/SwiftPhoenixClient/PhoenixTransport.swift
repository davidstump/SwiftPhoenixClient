// Copyright (c) 2021 David Stump <david@davidstump.net>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation


//----------------------------------------------------------------------
// MARK: - Transport Protocol
//----------------------------------------------------------------------
/// Defines a `Socket`'s Transport layer.
// sourcery: AutoMockable
public protocol PhoenixTransport {
    
    /// The current `ReadyState` of the `Transport` layer
    var readyState: PhoenixTransportReadyState { get }
    
    /// Delegate for the `Transport` layer
    var delegate: PhoenixTransportDelegate? { get set }
    
    /// Connect to the server
    ///
    /// - Parameters:
    /// - headers: Headers to include in the URLRequests when opening the Websocket connection. Can be empty [:]
    func connect(with headers: [String: Any])
    
    /// Disconnect from the server.
    ///
    /// - Parameters:
    ///     - code: Status code as defined by <ahref="http://tools.ietf.org/html/rfc6455#section-7.4">Section 7.4 of RFC 6455</a>.
    ///     - reason: Reason why the connection is closing. Optional.
    func disconnect(code: URLSessionWebSocketTask.CloseCode, reason: String?)
    
    /// Sends a message to the server.
    ///
    /// - Parameter data: Data to send.
    func send(data: Data)
    
    /// Sends a message to the server.
    ///
    /// - Parameter string: String to send.
    func send(string: String)
    
}


//----------------------------------------------------------------------
// MARK: - Transport Delegate Protocol
//----------------------------------------------------------------------
/// Delegate to receive notifications of events that occur in the `Transport` layer
public protocol PhoenixTransportDelegate {
    
    /// Notified when the `Transport` opens.
    ///
    /// - Parameter response: Response from the server indicating that the WebSocket handshake was successful and the connection has been upgraded to webSockets
    func onOpen(response: URLResponse?)
    
    /// Notified when the `Transport` receives an error.
    ///
    /// - Parameters
    ///     - error: Client-side error from the underlying `Transport` implementation
    ///     - response: Response from the server, if any, that occurred with the Error
    func onError(error: Error, response: URLResponse?)
    
    /// Notified when the `Transport` receives a string message from the server.
    ///
    /// - Parameter string: String message received from the server
    func onMessage(string: String)
    
    /// Notified when the `Transport` receives a data message from the server.
    ///
    /// - Parameter data: Binary data message received from the server
    func onMessage(data: Data)
    
    /// Notified when the `Transport` closes.
    ///
    /// - Parameters:
    ///     - code: Code that was sent when the `Transport` closed
    ///     - reason: A concise human-readable prose explanation for the closure
    func onClose(code: URLSessionWebSocketTask.CloseCode, reason: String?)
}

//----------------------------------------------------------------------
// MARK: - Transport Ready State Enum
//----------------------------------------------------------------------
/// Available `ReadyState`s of a `Transport` layer.
public enum PhoenixTransportReadyState {
    
    /// The `Transport` is opening a connection to the server.
    case connecting
    
    /// The `Transport` is connected to the server.
    case open
    
    /// The `Transport` is closing the connection to the server.
    case closing
    
    /// The `Transport` has disconnected from the server.
    case closed
    
}

//----------------------------------------------------------------------
// MARK: - Default Websocket Transport Implementation
//----------------------------------------------------------------------
/// A `Transport` implementation that relies on URLSession's native WebSocket
open class URLSessionTransport: NSObject, PhoenixTransport, URLSessionWebSocketDelegate {
    
    /// The URL to connect to
    internal let url: URL
    
    /// The URLSession configuration
    internal let configuration: URLSessionConfiguration
    
    /// The underling URLSession. Assigned during `connect()`
    private var session: URLSession? = nil
    
    /// The ongoing task. Assigned during `connect()`
    private var task: URLSessionWebSocketTask? = nil
    
    
    
    /// Initializes a `Transport` layer built using URLSession's WebSocket
    ///
    /// Example:
    ///
    /// ```swift
    /// let url = URL("wss://example.com/socket")
    /// let transport: Transport = URLSessionTransport(url: url)
    /// ```
    ///
    /// Using a custom `URLSessionConfiguration`
    ///
    /// ```swift
    /// let url = URL("wss://example.com/socket")
    /// let configuration = URLSessionConfiguration.default
    /// let transport: Transport = URLSessionTransport(url: url, configuration: configuration)
    /// ```
    ///
    /// - parameter url: URL to connect to
    /// - parameter configuration: Provide your own URLSessionConfiguration. Uses `.default` if none provided
    
    public init(url: URL, configuration: URLSessionConfiguration = .default) {
        
        // URLSession requires that the endpoint be "wss" instead of "https".
        let endpoint = url.absoluteString
        let wsEndpoint = endpoint
            .replacingOccurrences(of: "http://", with: "ws://")
            .replacingOccurrences(of: "https://", with: "wss://")
        
        // Force unwrapping should be safe here since a valid URL came in and we just
        // replaced the protocol.
        self.url = URL(string: wsEndpoint)!
        self.configuration = configuration
        
        super.init()
    }
    
    
    
    // MARK: - Transport
    public var readyState: PhoenixTransportReadyState = .closed
    public var delegate: PhoenixTransportDelegate? = nil
    
    public func connect(with headers: [String : Any]) {
        // Set the transport state as connecting
        self.readyState = .connecting
        
        // Create the session and websocket task
        self.session = URLSession(configuration: self.configuration, delegate: self, delegateQueue: nil)
        var request = URLRequest(url: url)
        
        headers.forEach { (key: String, value: Any) in
            guard let value = value as? String else { return }
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        self.task = self.session?.webSocketTask(with: request)
        
        // Start the task
        self.task?.resume()
    }
    
    open func disconnect(code: URLSessionWebSocketTask.CloseCode, reason: String?) {
        self.readyState = .closing
        self.task?.cancel(with: code, reason: reason?.data(using: .utf8))
        self.session?.finishTasksAndInvalidate()
    }
    
    open func send(string: String)  {
        self.send(.string(string))
    }
    
    open func send(data: Data) {
        self.send(.data(data))
    }
    
    private func send(_ message: URLSessionWebSocketTask.Message) { // async throws {
        self.task?.send(message) { error in
            // TODO: What is the behavior when an error occurs? Using continuations just moves the problem to the `Task {}`
//            if let error {
//                continuation.resume(with: .failure(error))
//            } else {
//                continuation.resume()
//            }
        }
        
//        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
//            self.task?.send(message) { error in
//                if let error {
//                    continuation.resume(with: .failure(error))
//                } else {
//                    continuation.resume()
//                }
//            }
//        }
    }
    
    
    // MARK: - URLSessionWebSocketDelegate
    open func urlSession(_ session: URLSession,
                         webSocketTask: URLSessionWebSocketTask,
                         didOpenWithProtocol protocol: String?) {
        // The Websocket is connected. Set Transport state to open and inform delegate
        self.readyState = .open
        self.delegate?.onOpen(response: webSocketTask.response)
        
        // Start receiving messages
        self.receive()
    }
    
    open func urlSession(_ session: URLSession,
                         webSocketTask: URLSessionWebSocketTask,
                         didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                         reason: Data?) {
        // A close frame was received from the server.
        self.readyState = .closed
        self.delegate?.onClose(code: closeCode, reason: reason.flatMap { String(data: $0, encoding: .utf8) })
    }
    
    open func urlSession(_ session: URLSession,
                         task: URLSessionTask,
                         didCompleteWithError error: Error?) {
        // The task has terminated. Inform the delegate that the transport has closed abnormally
        // if this was caused by an error.
        guard let err = error else { return }
        
        self.abnormalErrorReceived(err, response: task.response)
    }
    
    
    // MARK: - Private
    private func receive() {
        self.task?.receive { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(.data(let data)):
                self.delegate?.onMessage(data: data)
                self.receive()
                
            case .success(.string(let text)):
                self.delegate?.onMessage(string: text)
                self.receive()
                    
            case .failure(let error):
                self.abnormalErrorReceived(error, response: nil)
                
            default:
                fatalError("Unknown result was received. [\(result)]")
            }
        }
    }
    
    private func abnormalErrorReceived(_ error: Error, response: URLResponse?) {
        // Set the state of the Transport to closed
        self.readyState = .closed
        
        // Inform the Transport's delegate that an error occurred.
        self.delegate?.onError(error: error, response: response)
        
        // An abnormal error is results in an abnormal closure, such as internet getting dropped
        // so inform the delegate that the Transport has closed abnormally. This will kick off
        // the reconnect logic.
        self.delegate?.onClose(code: URLSessionWebSocketTask.CloseCode.abnormalClosure, reason: error.localizedDescription)
    }
}
