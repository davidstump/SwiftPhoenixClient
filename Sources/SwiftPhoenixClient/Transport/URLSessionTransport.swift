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


/// A `Transport` implementation that relies on URLSession's native WebSocket
/// implementation.
///
/// This implementation ships default with SwiftPhoenixClient however
/// SwiftPhoenixClient supports earlier OS versions using one of the submodule
/// `Transport` implementations. Or you can create your own implementation using
/// your own WebSocket library or implementation.
open class URLSessionTransport: NSObject, Transport, URLSessionWebSocketDelegate {

    /// The URL to connect to
    internal let url: URL
    
    /// The URLSession configuration
    internal let configuration: URLSessionConfiguration
    
    /// The underling URLSession. Assigned during `connect()`
    private var session: URLSession? = nil
    
    /// The ongoing task. Assigned during `connect()`
    private var task: URLSessionWebSocketTask? = nil
    
    /// The Concurrency Task that receives messages
    private var receiveMessageTask: Task<Void, Never>? {
          didSet { oldValue?.cancel() }
      }
    
    
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
    
    
    deinit {
        self.delegate = nil
        self.receiveMessageTask?.cancel()
    }
    
    // MARK: - Transport
    public var readyState: TransportReadyState = .closed
    public var delegate: TransportDelegate? = nil
    
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
        
        // This should be handled by the URLSessionWebsocketTask, but to be safe,
        // we go ahead and cancel it anyways.
        self.receiveMessageTask?.cancel()
    }
    
    open func send(string: String) {
        self.send(message: .string(string))
    }
    
    open func send(data: Data) {
        self.send(message: .data(data))
    }
    
    private func send(message: URLSessionWebSocketTask.Message) {
        self.task?.send(message, completionHandler: { error in
            // TODO: What is the behavior when an error occurs?
        })
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
        self.delegate?.onClose(
            code: closeCode,
            reason: reason.flatMap { String(data: $0, encoding: .utf8) }
        )
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
        if #available(iOS 17.0, *) {
            awaitReceive()
        } else {
            receiveAsCallback()
        }
    }
    
    private func awaitReceive() {
        self.receiveMessageTask = Task { [weak self] in
            guard let self else { return }
            do {
                let message = try await self.task?.receive()
                switch message {
                case .data(let data):
                    delegate?.onMessage(data: data)
                case .string(let string):
                    delegate?.onMessage(string: string)
                case .none:
                    fatalError("Receive nil from the server. Message with either data or string value expected.")
                case .some(_):
                    fatalError("Receive some from the server, but wasn't already handled.")
                }
                
                // Since `.receive()` is only good for a single message, it must
                // be called again after a message is received in order to
                // received the next message.
                receive()
            } catch {
                abnormalErrorReceived(error, response: nil)
            }
        }
    }
    
    private func receiveAsCallback() {
        self.task?.receive { [weak self] result in
            switch result {
            case .success(.data(let data)):
                self?.delegate?.onMessage(data: data)
                self?.receive()
                
            case .success(.string(let string)):
                self?.delegate?.onMessage(string: string)
                self?.receive()
                
            case .failure(let error):
                self?.abnormalErrorReceived(error, response: nil)
                
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
        self.delegate?.onClose(code: .abnormalClosure, reason: error.localizedDescription)
    }
}
