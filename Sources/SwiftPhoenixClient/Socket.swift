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

public enum SocketError: Error {
  
  case abnormalClosureError
  
}


/// Alias for a JSON dictionary [String: Any]
public typealias Payload = [String: Any]

/// Alias for a function returning an optional JSON dictionary (`Payload?`)
public typealias PayloadClosure = () -> Payload?

/// Struct that gathers callbacks assigned to the Socket
struct StateChangeCallbacks {
    let open: SynchronizedArray<(ref: String, callback: Delegated<URLResponse?, Void>)> = .init()
    let close: SynchronizedArray<(ref: String, callback: Delegated<(Int, String?), Void>)> = .init()
    let error: SynchronizedArray<(ref: String, callback: Delegated<(Error, URLResponse?), Void>)> = .init()
    let message: SynchronizedArray<(ref: String, callback: Delegated<Message, Void>)> = .init()
}


/// ## Socket Connection
/// A single connection is established to the server and
/// channels are multiplexed over the connection.
/// Connect to the server using the `Socket` class:
///
/// ```swift
/// let socket = new Socket("/socket", paramsClosure: { ["userToken": "123" ] })
/// socket.connect()
/// ```
///
/// The `Socket` constructor takes the mount point of the socket,
/// the authentication params, as well as options that can be found in
/// the Socket docs, such as configuring the heartbeat.
public class Socket: PhoenixTransportDelegate {
  
  
    //----------------------------------------------------------------------
    // MARK: - Public Attributes
    //----------------------------------------------------------------------
    /// The string WebSocket endpoint (ie `"ws://example.com/socket"`,
    /// `"wss://example.com"`, etc.) That was passed to the Socket during
    /// initialization. The URL endpoint will be modified by the Socket to
    /// include `"/websocket"` if missing.
    public let endPoint: String

    /// The fully qualified socket URL
    public private(set) var endPointUrl: URL
    
    /// Resolves to return the `paramsClosure` result at the time of calling.
    /// If the `Socket` was created with static params, then those will be
    /// returned every time.
    public var params: Payload? {
        return self.paramsClosure?()
    }
    
    /// The optional params closure used to get params when connecting. Must
    /// be set when initializing the Socket.
    public let paramsClosure: PayloadClosure?
    
    /// The WebSocket transport. Default behavior is to provide a
    /// URLSessionWebsocketTask. See README for alternatives.
    private let transport: ((URL) -> PhoenixTransport)

    /// Phoenix serializer version, defaults to "2.0.0"
    public let vsn: String
  
    /// Override to provide custom encoding/decoding of data before it is sent to or received from
    /// the Server.
    public var serializer: Serializer = PhoenixSerializer()
  
  /// Timeout to use when opening connections
  public var timeout: TimeInterval = Defaults.timeoutInterval
    
  /// Custom headers to be added to the socket connection request
  public var headers: [String : Any] = [:]
  
  /// Interval between sending a heartbeat
  public var heartbeatInterval: TimeInterval = Defaults.heartbeatInterval

  /// The maximum amount of time which the system may delay heartbeats in order to optimize power usage
  public var heartbeatLeeway: DispatchTimeInterval = Defaults.heartbeatLeeway
  
  /// Interval between socket reconnect attempts, in seconds
  public var reconnectAfter: (Int) -> TimeInterval = Defaults.reconnectSteppedBackOff
  
  /// Interval between channel rejoin attempts, in seconds
  public var rejoinAfter: (Int) -> TimeInterval = Defaults.rejoinSteppedBackOff
  
  /// The optional function to receive logs
  public var logger: ((String) -> Void)?
  
  /// Disables heartbeats from being sent. Default is false.
  public var skipHeartbeat: Bool = false
  
  /// Enable/Disable SSL certificate validation. Default is false. This
  /// must be set before calling `socket.connect()` in order to be applied
  public var disableSSLCertValidation: Bool = false
  
  #if os(Linux)
  #else
  /// Configure custom SSL validation logic, eg. SSL pinning. This
  /// must be set before calling `socket.connect()` in order to apply.
//  public var security: SSLTrustValidator?
  
  /// Configure the encryption used by your client by setting the
  /// allowed cipher suites supported by your server. This must be
  /// set before calling `socket.connect()` in order to apply.
  public var enabledSSLCipherSuites: [SSLCipherSuite]?
  #endif
  
  
    //----------------------------------------------------------------------
    // MARK: - Private Attributes
    //----------------------------------------------------------------------
    /// Callbacks for socket state changes
    let stateChangeCallbacks: StateChangeCallbacks = StateChangeCallbacks()
    
    /// Collection on channels created for the Socket
    public internal(set) var channels: [Channel] = []
    
    /// Buffers messages that need to be sent once the socket has connected. It is an array
    /// of tuples, with the ref of the message to send and the callback that will send the message.
    let sendBuffer = SynchronizedArray<(ref: String?, callback: () throws -> ())>()
    
    /// Ref counter for messages
    var ref: UInt64 = UInt64.min // 0 (max: 18,446,744,073,709,551,615)
    
    /// Timer that triggers sending new Heartbeat messages
    var heartbeatTimer: HeartbeatTimer?
    
    /// Ref counter for the last heartbeat that was sent
    var pendingHeartbeatRef: String?
    
    /// Timer to use when attempting to reconnect
    var reconnectTimer: TimeoutTimer
    
    /// Close status, if one has been received. `nil` otherwise.
    var closeStatus: URLSessionWebSocketTask.CloseCode? = nil
    
    /// The connection to the server
    var connection: PhoenixTransport? = nil
  
  
  //----------------------------------------------------------------------
  // MARK: - Initialization
  //----------------------------------------------------------------------
  @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
  public convenience init(_ endPoint: String,
                          params: Payload? = nil,
                          vsn: String = Defaults.vsn) {
    self.init(endPoint: endPoint,
              transport: { url in return URLSessionTransport(url: url) },
              paramsClosure: { params },
              vsn: vsn)
  }

  @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
  public convenience init(_ endPoint: String,
                          paramsClosure: PayloadClosure?,
                          vsn: String = Defaults.vsn) {
    self.init(endPoint: endPoint,
              transport: { url in return URLSessionTransport(url: url) },
              paramsClosure: paramsClosure,
              vsn: vsn)
  }
  
  
  public init(endPoint: String,
       transport: @escaping ((URL) -> PhoenixTransport),
       paramsClosure: PayloadClosure? = nil,
       vsn: String = Defaults.vsn) {
    self.transport = transport
    self.paramsClosure = paramsClosure
    self.endPoint = endPoint
    self.vsn = vsn
    self.endPointUrl = Socket.buildEndpointUrl(endpoint: endPoint,
                                               paramsClosure: paramsClosure,
                                               vsn: vsn)

    self.reconnectTimer = TimeoutTimer()
    self.reconnectTimer.callback.delegate(to: self) { (self) in
      self.logItems("Socket attempting to reconnect")
      self.teardown(reason: "reconnection") { self.connect() }
    }
    self.reconnectTimer.timerCalculation
      .delegate(to: self) { (self, tries) -> TimeInterval in
        let interval = self.reconnectAfter(tries)
        self.logItems("Socket reconnecting in \(interval)s")
        return interval
    }
  }
  
  deinit {
    reconnectTimer.reset()
  }
  
  //----------------------------------------------------------------------
  // MARK: - Public
  //----------------------------------------------------------------------
  /// - return: The socket protocol, wss or ws
  public var websocketProtocol: String {
    switch endPointUrl.scheme {
    case "https": return "wss"
    case "http": return "ws"
    default: return endPointUrl.scheme ?? ""
    }
  }
  
  /// - return: True if the socket is connected
  public var isConnected: Bool {
    return self.connectionState == .open
  }
  
  /// - return: The state of the connect. [.connecting, .open, .closing, .closed]
  public var connectionState: PhoenixTransportReadyState {
    return self.connection?.readyState ?? .closed
  }
  
  /// Connects the Socket. The params passed to the Socket on initialization
  /// will be sent through the connection. If the Socket is already connected,
  /// then this call will be ignored.
  public func connect() {
    // Do not attempt to reconnect if the socket is currently connected
    guard !isConnected else { return }
    
    // Reset the close status when attempting to connect
    self.closeStatus = nil

    // We need to build this right before attempting to connect as the
    // parameters could be built upon demand and change over time
    self.endPointUrl = Socket.buildEndpointUrl(endpoint: self.endPoint,
                                               paramsClosure: self.paramsClosure,
                                               vsn: vsn)

    self.connection = self.transport(self.endPointUrl)
    self.connection?.delegate = self
//    self.connection?.disableSSLCertValidation = disableSSLCertValidation
//
//    #if os(Linux)
//    #else
//    self.connection?.security = security
//    self.connection?.enabledSSLCipherSuites = enabledSSLCipherSuites
//    #endif
    
    self.connection?.connect(with: self.headers)
  }
  
    /// Disconnects the socket
    ///
    /// - parameter code: Optional. Closing status code
    /// - parameter callback: Optional. Called when disconnected
    public func disconnect(code: URLSessionWebSocketTask.CloseCode = .normalClosure,
                           reason: String? = nil,
                           callback: (() -> Void)? = nil) {
        // The socket was closed cleanly by the User
        self.closeStatus = code
        
        // Reset any reconnects and teardown the socket connection
        self.reconnectTimer.reset()
        self.teardown(code: code, reason: reason, callback: callback)
    }
    
    internal func teardown(code: URLSessionWebSocketTask.CloseCode = .normalClosure, reason: String? = nil, callback: (() -> Void)? = nil) {
        self.connection?.delegate = nil
        self.connection?.disconnect(code: code, reason: reason)
        self.connection = nil
        
        // The socket connection has been torndown, heartbeats are not needed
        self.heartbeatTimer?.stop()
        
        // Since the connection's delegate was nil'd out, inform all state
        // callbacks that the connection has closed
        self.stateChangeCallbacks.close.forEach({ $0.callback.call((code.rawValue, reason)) })
        callback?()
    }
  

  
  //----------------------------------------------------------------------
  // MARK: - Register Socket State Callbacks
  //----------------------------------------------------------------------
  
  /// Registers callbacks for connection open events. Does not handle retain
  /// cycles. Use `delegateOnOpen(to:)` for automatic handling of retain cycles.
  ///
  /// Example:
  ///
  ///     socket.onOpen() { [weak self] in
  ///         self?.print("Socket Connection Open")
  ///     }
  ///
  /// - parameter callback: Called when the Socket is opened
  @discardableResult
  public func onOpen(callback: @escaping () -> Void) -> String {
    return self.onOpen { _ in callback() }
  }
  
  /// Registers callbacks for connection open events. Does not handle retain
  /// cycles. Use `delegateOnOpen(to:)` for automatic handling of retain cycles.
  ///
  /// Example:
  ///
  ///     socket.onOpen() { [weak self] response in
  ///         self?.print("Socket Connection Open")
  ///     }
  ///
  /// - parameter callback: Called when the Socket is opened
  @discardableResult
  public func onOpen(callback: @escaping (URLResponse?) -> Void) -> String {
    var delegated = Delegated<URLResponse?, Void>()
    delegated.manuallyDelegate(with: callback)
    
    return self.append(callback: delegated, to: self.stateChangeCallbacks.open)
  }
  
  /// Registers callbacks for connection open events. Automatically handles
  /// retain cycles. Use `onOpen()` to handle yourself.
  ///
  /// Example:
  ///
  ///     socket.delegateOnOpen(to: self) { self in
  ///         self.print("Socket Connection Open")
  ///     }
  ///
  /// - parameter owner: Class registering the callback. Usually `self`
  /// - parameter callback: Called when the Socket is opened
  @discardableResult
  public func delegateOnOpen<T: AnyObject>(to owner: T,
                                           callback: @escaping ((T) -> Void)) -> String {
    return self.delegateOnOpen(to: owner) { owner, _ in callback(owner) }
  }

  /// Registers callbacks for connection open events. Automatically handles
  /// retain cycles. Use `onOpen()` to handle yourself.
  ///
  /// Example:
  ///
  ///     socket.delegateOnOpen(to: self) { self, response in
  ///         self.print("Socket Connection Open")
  ///     }
  ///
  /// - parameter owner: Class registering the callback. Usually `self`
  /// - parameter callback: Called when the Socket is opened
  @discardableResult
  public func delegateOnOpen<T: AnyObject>(to owner: T,
                                           callback: @escaping ((T, URLResponse?) -> Void)) -> String {
    var delegated = Delegated<URLResponse?, Void>()
    delegated.delegate(to: owner, with: callback)
    
    return self.append(callback: delegated, to: self.stateChangeCallbacks.open)
  }
  
  /// Registers callbacks for connection close events. Does not handle retain
  /// cycles. Use `delegateOnClose(_:)` for automatic handling of retain cycles.
  ///
  /// Example:
  ///
  ///     socket.onClose() { [weak self] in
  ///         self?.print("Socket Connection Close")
  ///     }
  ///
  /// - parameter callback: Called when the Socket is closed
  @discardableResult
  public func onClose(callback: @escaping () -> Void) -> String {
    return self.onClose { _, _ in callback() }
  }

  /// Registers callbacks for connection close events. Does not handle retain
  /// cycles. Use `delegateOnClose(_:)` for automatic handling of retain cycles.
  ///
  /// Example:
  ///
  ///     socket.onClose() { [weak self] code, reason in
  ///         self?.print("Socket Connection Close")
  ///     }
  ///
  /// - parameter callback: Called when the Socket is closed
  @discardableResult
  public func onClose(callback: @escaping (Int, String?) -> Void) -> String {
    var delegated = Delegated<(Int, String?), Void>()
    delegated.manuallyDelegate(with: callback)
    
    return self.append(callback: delegated, to: self.stateChangeCallbacks.close)
  }
  
  /// Registers callbacks for connection close events. Automatically handles
  /// retain cycles. Use `onClose()` to handle yourself.
  ///
  /// Example:
  ///
  ///     socket.delegateOnClose(self) { self in
  ///         self.print("Socket Connection Close")
  ///     }
  ///
  /// - parameter owner: Class registering the callback. Usually `self`
  /// - parameter callback: Called when the Socket is closed
  @discardableResult
  public func delegateOnClose<T: AnyObject>(to owner: T,
                                            callback: @escaping ((T) -> Void)) -> String {
    return self.delegateOnClose(to: owner) { owner, _ in callback(owner) }
  }

  /// Registers callbacks for connection close events. Automatically handles
  /// retain cycles. Use `onClose()` to handle yourself.
  ///
  /// Example:
  ///
  ///     socket.delegateOnClose(self) { self, code, reason in
  ///         self.print("Socket Connection Close")
  ///     }
  ///
  /// - parameter owner: Class registering the callback. Usually `self`
  /// - parameter callback: Called when the Socket is closed
  @discardableResult
  public func delegateOnClose<T: AnyObject>(to owner: T,
                                            callback: @escaping ((T, (Int, String?)) -> Void)) -> String {
    var delegated = Delegated<(Int, String?), Void>()
    delegated.delegate(to: owner, with: callback)
   
    return self.append(callback: delegated, to: self.stateChangeCallbacks.close)
  }
  
  /// Registers callbacks for connection error events. Does not handle retain
  /// cycles. Use `delegateOnError(to:)` for automatic handling of retain cycles.
  ///
  /// Example:
  ///
  ///     socket.onError() { [weak self] (error) in
  ///         self?.print("Socket Connection Error", error)
  ///     }
  ///
  /// - parameter callback: Called when the Socket errors
  @discardableResult
  public func onError(callback: @escaping ((Error, URLResponse?)) -> Void) -> String {
    var delegated = Delegated<(Error, URLResponse?), Void>()
    delegated.manuallyDelegate(with: callback)
    
    return self.append(callback: delegated, to: self.stateChangeCallbacks.error)
  }
  
  /// Registers callbacks for connection error events. Automatically handles
  /// retain cycles. Use `manualOnError()` to handle yourself.
  ///
  /// Example:
  ///
  ///     socket.delegateOnError(to: self) { (self, error) in
  ///         self.print("Socket Connection Error", error)
  ///     }
  ///
  /// - parameter owner: Class registering the callback. Usually `self`
  /// - parameter callback: Called when the Socket errors
  @discardableResult
  public func delegateOnError<T: AnyObject>(to owner: T,
                                            callback: @escaping ((T, (Error, URLResponse?)) -> Void)) -> String {
    var delegated = Delegated<(Error, URLResponse?), Void>()
    delegated.delegate(to: owner, with: callback)

    return self.append(callback: delegated, to: self.stateChangeCallbacks.error)
  }
  
  /// Registers callbacks for connection message events. Does not handle
  /// retain cycles. Use `delegateOnMessage(_to:)` for automatic handling of
  /// retain cycles.
  ///
  /// Example:
  ///
  ///     socket.onMessage() { [weak self] (message) in
  ///         self?.print("Socket Connection Message", message)
  ///     }
  ///
  /// - parameter callback: Called when the Socket receives a message event
  @discardableResult
  public func onMessage(callback: @escaping (Message) -> Void) -> String {
    var delegated = Delegated<Message, Void>()
    delegated.manuallyDelegate(with: callback)
    
    return self.append(callback: delegated, to: self.stateChangeCallbacks.message)
  }
  
  /// Registers callbacks for connection message events. Automatically handles
  /// retain cycles. Use `onMessage()` to handle yourself.
  ///
  /// Example:
  ///
  ///     socket.delegateOnMessage(self) { (self, message) in
  ///         self.print("Socket Connection Message", message)
  ///     }
  ///
  /// - parameter owner: Class registering the callback. Usually `self`
  /// - parameter callback: Called when the Socket receives a message event
  @discardableResult
  public func delegateOnMessage<T: AnyObject>(to owner: T,
                                              callback: @escaping ((T, Message) -> Void)) -> String {
    var delegated = Delegated<Message, Void>()
    delegated.delegate(to: owner, with: callback)
    
    return self.append(callback: delegated, to: self.stateChangeCallbacks.message)
  }
  
  private func append<T>(callback: T, to array: SynchronizedArray<(ref: String, callback: T)>) -> String {
    let ref = makeRef()
    array.append((ref, callback))
    return ref
  }
  
  /// Releases all stored callback hooks (onError, onOpen, onClose, etc.) You should
  /// call this method when you are finished when the Socket in order to release
  /// any references held by the socket.
  public func releaseCallbacks() {
    self.stateChangeCallbacks.open.removeAll()
    self.stateChangeCallbacks.close.removeAll()
    self.stateChangeCallbacks.error.removeAll()
    self.stateChangeCallbacks.message.removeAll()
  }
  
  
  
  //----------------------------------------------------------------------
  // MARK: - Channel Initialization
  //----------------------------------------------------------------------
  /// Initialize a new Channel
  ///
  /// Example:
  ///
  ///     let channel = socket.channel("rooms", params: ["user_id": "abc123"])
  ///
  /// - parameter topic: Topic of the channel
  /// - parameter params: Optional. Parameters for the channel
  /// - return: A new channel
  public func channel(_ topic: String,
                      params: [String: Any] = [:]) -> Channel {
    let channel = Channel(topic: topic, params: params, socket: self)
    self.channels.append(channel)
    
    return channel
  }
  
  /// Removes the Channel from the socket. This does not cause the channel to
  /// inform the server that it is leaving. You should call channel.leave()
  /// prior to removing the Channel.
  ///
  /// Example:
  ///
  ///     channel.leave()
  ///     socket.remove(channel)
  ///
  /// - parameter channel: Channel to remove
  public func remove(_ channel: Channel) {
    self.off(channel.stateChangeRefs)
    self.channels.removeAll(where: { $0.joinRef == channel.joinRef })
  }
  
  /// Removes `onOpen`, `onClose`, `onError,` and `onMessage` registrations.
  ///
  ///
  /// - Parameter refs: List of refs returned by calls to `onOpen`, `onClose`, etc
  public func off(_ refs: [String]) {
    self.stateChangeCallbacks.open.removeAll { refs.contains($0.ref) }
    self.stateChangeCallbacks.close.removeAll { refs.contains($0.ref) }
    self.stateChangeCallbacks.error.removeAll { refs.contains($0.ref) }
    self.stateChangeCallbacks.message.removeAll { refs.contains($0.ref) }
  }
  
  
  //----------------------------------------------------------------------
  // MARK: - Sending Data
  //----------------------------------------------------------------------
  /// Sends data through the Socket. This method is internal. Instead, you
  /// should call `push(_:, payload:, timeout:)` on the Channel you are
  /// sending an event to.
  ///
  /// - parameter topic:
  /// - parameter event:
  /// - parameter payload:
  /// - parameter ref: Optional. Defaults to nil
  /// - parameter joinRef: Optional. Defaults to nil
  internal func push(topic: String,
                     event: String,
                     payload: Payload,
                     ref: String? = nil,
                     joinRef: String? = nil) {
    
    let callback: (() throws -> ()) = { [weak self] in
      guard let self else { return }
      let body: [Any?] = [joinRef, ref, topic, event, payload]
      let data = self.encode(body)
      
      self.logItems("push", "Sending \(String(data: data, encoding: String.Encoding.utf8) ?? "")" )
      self.connection?.send(data: data)
    }
    
    /// If the socket is connected, then execute the callback immediately.
    if isConnected {
      try? callback()
    } else {
      /// If the socket is not connected, add the push to a buffer which will
      /// be sent immediately upon connection.
      self.sendBuffer.append((ref: ref, callback: callback))
    }
  }
  
  /// - return: the next message ref, accounting for overflows
  public func makeRef() -> String {
    self.ref = (ref == UInt64.max) ? 0 : self.ref + 1
    return String(ref)
  }
  
  /// Logs the message. Override Socket.logger for specialized logging. noops by default
  ///
  /// - parameter items: List of items to be logged. Behaves just like debugPrint()
  func logItems(_ items: Any...) {
    let msg = items.map( { return String(describing: $0) } ).joined(separator: ", ")
    self.logger?("SwiftPhoenixClient: \(msg)")
  }
  
    //----------------------------------------------------------------------
    // MARK: - Connection Events
    //----------------------------------------------------------------------
    /// Called when the underlying Websocket connects to it's host
    internal func onConnectionOpen(response: URLResponse?) {
        self.logItems("transport", "Connected to \(endPoint)")
        
        // Reset the close status now that the socket has been connected
        self.closeStatus = nil
        
        // Send any messages that were waiting for a connection
        self.flushSendBuffer()
        
        // Reset how the socket tried to reconnect
        self.reconnectTimer.reset()
        
        // Restart the heartbeat timer
        self.resetHeartbeat()
        
        // Inform all onOpen callbacks that the Socket has opened
        self.stateChangeCallbacks.open.forEach({ $0.callback.call((response)) })
    }
  
    internal func onConnectionClosed(code: URLSessionWebSocketTask.CloseCode, reason: String?) {
        self.logItems("transport", "close")
        
        // Send an error to all channels
        self.triggerChannelError()
        
        // Prevent the heartbeat from triggering if the
        self.heartbeatTimer?.stop()
        
        // Only attempt to reconnect if the socket did not close normally,
        // or if it was closed abnormally but on client side (e.g. due to heartbeat timeout)
        let shouldReconnect = self.closeStatus == nil || self.closeStatus == .abnormalClosure
        
        if (shouldReconnect) {
            self.reconnectTimer.scheduleTimeout()
        }
        
        self.stateChangeCallbacks.close.forEach({ $0.callback.call((code.rawValue, reason)) })
    }
  
    internal func onConnectionError(_ error: Error, response: URLResponse?) {
        self.logItems("transport", error, response ?? "")
        
        // Send an error to all channels
        self.triggerChannelError()
        
        // Inform any state callbacks of the error
        self.stateChangeCallbacks.error.forEach({ $0.callback.call((error, response)) })
    }
  
    internal func onConnectionMessage(_ message: SocketMessage) {
        
        
        // Clear heartbeat ref, preventing a heartbeat timeout disconnect
        if let ref = message.ref, ref == pendingHeartbeatRef {
            self.clearHeartbeats()
            self.pendingHeartbeatRef = nil
            
        }
        if message.ref == pendingHeartbeatRef {
            pendingHeartbeatRef = nil
        }
        
        
        
        // Dispatch the message to all channels that belong to the topic
        self.channels
            .filter( { $0.isMember(message) } )
            .forEach( { $0.trigger(message) } )
        
        // Inform all onMessage callbacks of the message
        self.stateChangeCallbacks.message.forEach({ $0.callback.call(message) })
    }
  
  /// Triggers an error event to all of the connected Channels
  internal func triggerChannelError() {
    self.channels.forEach { (channel) in
      // Only trigger a channel error if it is in an "opened" state
      if !(channel.isErrored || channel.isLeaving || channel.isClosed) {
        channel.trigger(event: ChannelEvent.error)
      }
    }
  }
  
  /// Send all messages that were buffered before the socket opened
  internal func flushSendBuffer() {
    guard isConnected else { return }
    self.sendBuffer.forEach( { try? $0.callback() } )
    self.sendBuffer.removeAll()
  }
  
  /// Removes an item from the sendBuffer with the matching ref
  internal func removeFromSendBuffer(ref: String) {
    self.sendBuffer.removeAll { $0.ref == ref }
  }

  /// Builds a fully qualified socket `URL` from `endPoint` and `params`.
  internal static func buildEndpointUrl(endpoint: String, paramsClosure params: PayloadClosure?, vsn: String) -> URL {
    guard
      let url = URL(string: endpoint),
      var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
      else { fatalError("Malformed URL: \(endpoint)") }

    // Ensure that the URL ends with "/websocket
    if !urlComponents.path.contains("/websocket") {
      // Do not duplicate '/' in the path
      if urlComponents.path.last != "/" {
        urlComponents.path.append("/")
      }

      // append 'websocket' to the path
      urlComponents.path.append("websocket")

    }

    urlComponents.queryItems = [URLQueryItem(name: "vsn", value: vsn)]

    // If there are parameters, append them to the URL
    if let params = params?() {
      urlComponents.queryItems?.append(contentsOf: params.map {
        URLQueryItem(name: $0.key, value: String(describing: $0.value))
      })
    }

    guard let qualifiedUrl = urlComponents.url
      else { fatalError("Malformed URL while adding parameters") }
    return qualifiedUrl
  }
  
  
  // Leaves any channel that is open that has a duplicate topic
  internal func leaveOpenTopic(topic: String) {
    guard
      let dupe = self.channels.first(where: { $0.topic == topic && ($0.isJoined || $0.isJoining) })
    else { return }
    
    self.logItems("transport", "leaving duplicate topic: [\(topic)]" )
    dupe.leave()
  }
  
    //----------------------------------------------------------------------
    // MARK: - Heartbeat
    //----------------------------------------------------------------------
    internal func resetHeartbeat() {
        // Clear anything related to the heartbeat
        self.pendingHeartbeatRef = nil
        self.heartbeatTimer?.stop()
        
        // Do not start up the heartbeat timer if skipHeartbeat is true
        guard !skipHeartbeat else { return }
        
        self.heartbeatTimer = HeartbeatTimer(timeInterval: heartbeatInterval, leeway: heartbeatLeeway)
        self.heartbeatTimer?.start(eventHandler: { [weak self] in
            self?.sendHeartbeat()
        })
    }
    
    /// Sends a heartbeat payload to the phoenix servers
    @objc func sendHeartbeat() {
        // Do not send if the connection is closed
        guard isConnected else { return }
        
        
        // If there is a pending heartbeat ref, then the last heartbeat was
        // never acknowledged by the server. Close the connection and attempt
        // to reconnect.
        if let _ = self.pendingHeartbeatRef {
            self.pendingHeartbeatRef = nil
            self.logItems("transport",
                          "heartbeat timeout. Attempting to re-establish connection")
            
            // Close the socket manually, flagging the closure as abnormal. Do not use
            // `teardown` or `disconnect` as they will nil out the websocket delegate.
            self.abnormalClose("heartbeat timeout")
            
            return
        }
        
        // The last heartbeat was acknowledged by the server. Send another one
        self.pendingHeartbeatRef = self.makeRef()
        self.push(topic: "phoenix",
                  event: ChannelEvent.heartbeat,
                  payload: [:],
                  ref: self.pendingHeartbeatRef)
    }
    
    private func clearHeartbeats() {
        // TODO: Move heartbeatsa to async task
        // TODO: Clear the heartbeat async tasks here
    }
    
    
    internal func abnormalClose(_ reason: String) {
        self.closeStatus = .abnormalClosure
        
        /*
         We use NORMAL here since the client is the one determining to close the
         connection. However, we set to close status to abnormal so that
         the client knows that it should attempt to reconnect.
         
         If the server subsequently acknowledges with code 1000 (normal close),
         the socket will keep the `.abnormal` close status and trigger a reconnection.
         */
        self.connection?.disconnect(code: .normalClosure, reason: reason)
    }
  
    
    //----------------------------------------------------------------------
    // MARK: - TransportDelegate
    //----------------------------------------------------------------------
    public func onOpen(response: URLResponse?) {
        self.onConnectionOpen(response: response)
    }
    
    public func onError(error: Error, response: URLResponse?) {
        self.onConnectionError(error, response: response)
    }
    
    public func onMessage(data: Data) {
        self.logItems("receive ", data)
        
        do {
            let socketMessage = try self.serializer.binaryDecode(data: data)
            self.onConnectionMessage(socketMessage)
        } catch {
            self.logItems("receive: Unable to parse data: \(data)", error.localizedDescription)
        }
    }
    
    public func onMessage(string: String) {
        self.logItems("receive ", string)
        
        do {
            let socketMessage = try self.serializer.decode(text: string)
            self.onConnectionMessage(socketMessage)
        } catch {
            self.logItems("receive: Unable to parse json: \(string)", error.localizedDescription)
        }
    }
    
    public func onClose(code: URLSessionWebSocketTask.CloseCode, reason: String?) {
        self.closeStatus = code
        self.onConnectionClosed(code: code, reason: reason)
    }
    
}


//----------------------------------------------------------------------
// MARK: - Close Codes
//----------------------------------------------------------------------
extension Socket {
  public enum CloseCode : Int {
    case abnormal = 999
    
    case normal = 1000

    case goingAway = 1001
  }
}


//----------------------------------------------------------------------
// MARK: - Close Status
//----------------------------------------------------------------------
extension Socket {
  /// Indicates the different closure states a socket can be in.
  enum CloseStatus {
    /// Undetermined closure state
    case unknown
    /// A clean closure requested either by the client or the server
    case clean
    /// An abnormal closure requested by the client
    case abnormal
    
    /// Temporarily close the socket, pausing reconnect attempts. Useful on mobile
    /// clients when disconnecting a because the app resigned active but should
    /// reconnect when app enters active state.
    case temporary
    
    init(closeCode: Int) {
      switch closeCode {
      case CloseCode.abnormal.rawValue:
        self = .abnormal
      case CloseCode.goingAway.rawValue:
        self = .temporary
      default:
        self = .clean
      }
    }
    
    mutating func update(transportCloseCode: Int) {
      switch self {
      case .unknown, .clean, .temporary:
        // Allow transport layer to override these statuses.
        self = .init(closeCode: transportCloseCode)
      case .abnormal:
        // Do not allow transport layer to override the abnormal close status.
        // The socket itself should reset it on the next connection attempt.
        // See `Socket.abnormalClose(_:)` for more information.
        break
      }
    }
    
    var shouldReconnect: Bool {
      switch self {
      case .unknown, .abnormal:
        return true
      case .clean, .temporary:
        return false
      }
    }
  }
}
