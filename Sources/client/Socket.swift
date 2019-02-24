//
//  Socket.swift
//  SwiftPhoenixClient
//

import Foundation
import Starscream


/// Provides customization when enoding and decoding data within the Socket
public protocol Serializer {
    
    /// Convert a message into Data to be sent over the Socket
    func encode(_ message: [String: Any]) throws -> Data
    
    /// Convert data from the Socket into a Message
    func decode(_ data: Data) -> Message?
}


/// Default class to Serialize data within a Socket
class DefaultSerializer: Serializer {
    
    func encode(_ message: [String: Any]) throws -> Data {
        return try JSONSerialization.data(withJSONObject: message,
                                          options: JSONSerialization.WritingOptions())
    }
    
    func decode(_ data: Data) -> Message? {
        do {
            guard let jsonObject = try JSONSerialization
                    .jsonObject(with: data, options: JSONSerialization.ReadingOptions()) as? Payload
                else { return nil }
            
            let ref = jsonObject["ref"] as? String ?? ""
            let joinRef = jsonObject["join_ref"] as? String
            
            guard
                let topic = jsonObject["topic"] as? String,
                let event = jsonObject["event"] as? String,
                let payload = jsonObject["payload"] as? Payload else { return  nil }
                
            return Message(ref: ref, topic: topic, event: event, payload: payload, joinRef: joinRef)
            
        } catch {
            return nil
        }
    }
}




/// Alias for a JSON dictionary [String: Any]
public typealias Payload = [String: Any]



/// ## Socket Connection
/// A single connection is established to the server and
/// channels are multiplexed over the connection.
/// Connect to the server using the `Socket` class:
///
/// ```swift
/// let socket = new Socket("/socket", {params: {userToken: "123"}})
/// socket.connect()
/// ```
///
/// The `Socket` constructor takes the mount point of the socket,
/// the authentication params, as well as options that can be found in
/// the Socket docs, such as configuring the heartbeat.
public class Socket {
    
    // RFC 6455 Section 7.4: Status code 1000 indicates a normal closure
    private let WS_CLOSE_NORMAL: UInt16 = 1000
    
    /// Timeout to use when opening connections
    public var timeout: TimeInterval
    
    /// Interval between sending a heartbeat
    public var heartbeatInterval: TimeInterval
    
    /// Internval between socket reconnect attempts
    public var reconnectAfter: (Int) -> TimeInterval
    
    /// Hook for custom logging into the client
    public var logger: ((_ msg: String) -> Void)?
    
    /// Disable sending Heartbeats by setting to true
    public var skipHeartbeat: Bool = false
    
    /// The fully qualified endpoint the socket is connected to
    public private(set) var endpointUrl: URL
    
    
    /// Enable/Disable SSL certificate validation by setting the value on the 
    /// underlying WebSocket.
    /// See https://github.com/daltoniam/Starscream#self-signed-ssl
    public var disableSSLCertValidation: Bool {
        get { return connection.disableSSLCertValidation }
        set { connection.disableSSLCertValidation = newValue }
    }

    #if os(Linux)
    #else
    /// Configure custom SSL validation logic, eg. SSL pinning, by setting the 
    /// value on the underlyting WebSocket.
    /// See https://github.com/daltoniam/Starscream#ssl-pinning
    public var security: SSLTrustValidator? {
        get { return connection.security }
        set { connection.security = newValue }
    }
    
    /// Configure the encryption used by your client by setting the allowed 
    /// cipher suites supported by your server.
    /// See https://github.com/daltoniam/Starscream#ssl-cipher-suites
    public var enabledSSLCipherSuites: [SSLCipherSuite]? {
        get { return connection.enabledSSLCipherSuites }
        set { connection.enabledSSLCipherSuites = newValue }
    }
    #endif
    
    public var serializer: Serializer = DefaultSerializer()
    
    //----------------------------------------------------------------------
    // MARK: - Private Attributes
    //----------------------------------------------------------------------
    /// Callbacks for socket state changes
    var stateChangeCallbacks: StateChangeCallbacks

    /// Collection on channels created for the Socket
    var channels: [Channel]
    
    /// Buffers messages that need to be sent once the socket has connected
    var sendBuffer: [() throws -> ()]
    
    /// Ref counter for messages
    var ref: Int
    
    /// Params appendend to the URL when connecting
    var params: Payload?
    
    /// Timer that triggers sending new Heartbeat messages
    var heartbeatTimer: Timer?
    
    /// Ref counter for the last heartbeat that was sent
    var pendingHeartbeatRef: String?
    
    /// Timer to use when attempting to reconnect
    var reconnectTimer: TimeoutTimer
    
    /// Websocket connection to the server
    let connection: WebSocket
    
    
    //----------------------------------------------------------------------
    // MARK: - Initialization
    //----------------------------------------------------------------------
    /// Initializes a Socket
    ///
    /// - parameter connection: Websocket connection to maintain
    init(connection: WebSocket) {
        self.stateChangeCallbacks = StateChangeCallbacks()
        self.channels = []
        self.sendBuffer = []
        self.ref = Int.min
        self.timeout = PHOENIX_TIMEOUT_INTERVAL
        self.heartbeatInterval = PHOENIX_HEARTBEAT_INTERVAL
        self.reconnectAfter = { $0 > 4 ? 10 : [1, 2, 5, 10][$0 - 1] }
        
        self.connection = connection
        self.endpointUrl = connection.currentURL
        
        self.reconnectTimer = TimeoutTimer()
        self.reconnectTimer.callback.delegate(to: self) { (self, _) in
            self.teardown() { self.connect() }
        }
        self.reconnectTimer.timerCalculation
            .delegate(to: self) { (self, tries) -> TimeInterval in
                return self.reconnectAfter(tries)
        }
    }
    
    /// Initializes the Socket
    ///
    /// - parameter url: The string Websocket endpoint.
    ///                  ie "ws://example.com/socket", "wss://example.com/socket
    /// - parameter params: Optional parameters to pass when connecting
    public convenience init(url: URL, params: [String: Any]? = nil) {
        guard let safeParams = params,
            var urlComponents = URLComponents(url: url,
                                              resolvingAgainstBaseURL: false)
            else {
                self.init(connection: WebSocket(url: url))
                return
        }
        
        urlComponents.queryItems = safeParams.map({
            return URLQueryItem(name: $0.key, value: String(describing: $0.value))
        })
        
        guard
            let url = urlComponents.url
            else { fatalError("Malformed URL while adding paramters") }
        
        self.init(connection: WebSocket(url: url))
    }
    
    /// Initializes a Socket
    ///
    /// - parameter url: String representation of URL to point to
    /// - parameter params: Optional query parameters to append to the URL
    public convenience init(url: String, params: [String: Any]? = nil) {
        guard
            let parsedUrl = URL(string: url)
            else { fatalError("Malformed URL String \(url)") }
        
        self.init(url: parsedUrl, params: params)
    }
    
    deinit {
        reconnectTimer.reset()
    }
    
    //----------------------------------------------------------------------
    // MARK: - Public
    //----------------------------------------------------------------------
    /// Returns the socket protocol
    public var websocketProtocol: String? { return endpointUrl.scheme }
    
    /// - return: True if the socket is connected
    public var isConnected: Bool { return self.connection.isConnected }
    
    /// Connects the Socket. The params passed to the Socket on initialization
    /// will be sent through the connection. If the Socket is already connected,
    /// then this call will be ignored.
    public func connect() {
        // Do not attempt to reconnect if the socket is currently connected
        guard !isConnected else { return }
        
        connection.delegate = self
        connection.connect()
    }
    
    /// Disconnects the socket
    ///
    /// - parameter code: Optional. Closing status code
    /// - parameter reason: Optional. Reason for closure
    /// - paramter callback: Optional. Called when disconnected
    public func disconnect(code: Int? = nil,
                           reason: String? = nil,
                           callback: (() -> Void)? = nil) {
        self.reconnectTimer.reset()
        self.teardown(code: code, reason: reason, callback: callback)
    }
    
    
    public func teardown(code: Int? = nil,
                         reason: String? = nil,
                         callback: (() -> Void)? = nil) {
        if isConnected {
            self.connection.delegate = nil
            
            if let closeCode = code {
                connection.disconnect(closeCode: UInt16(closeCode))
            } else {
                connection.disconnect()
            }
            
            // TODO: This?
            //        self.heartbeatTimer?.invalidate()
            //        self.onCloseCallbacks.forEach( { $0() } )
        }
        
        callback?()
    }
    
    
    
    //----------------------------------------------------------------------
    // MARK: - Register Socket State Callbacks
    //----------------------------------------------------------------------
    
    /// Registers callbacks for connection open events. Does not handle retain
    /// cycles. Use `onOpen(_:)` for automatic handling of retain cycles.
    ///
    /// Example:
    ///
    ///     socket.manualOnOpen() { [weak self] in
    ///         self?.print("Socket Connection Open")
    ///     }
    ///
    /// - parameter callback: Called when the Socket is opened
    public func manualOnOpen(callback: @escaping () -> Void) {
        var delegated = Delegated<Void, Void>()
        delegated.manuallyDelegate(with: callback)
        self.stateChangeCallbacks.open.append(delegated)
    }
    
    /// Registers callbacks for connection open events. Automatically handles
    /// retain cycles. Use `manualOnOpen()` to handle yourself.
    ///
    /// Example:
    ///
    ///     socket.onOpen(self) { self in
    ///         self.print("Socket Connection Open")
    ///     }
    ///
    /// - parameter owner: Class registering the callback. Usually `self`
    /// - parameter callback: Called when the Socket is opened
    public func onOpen<T: AnyObject>(_ owner: T,
                                     callback: @escaping ((T) -> Void)) {
        var delegated = Delegated<Void, Void>()
        delegated.delegate(to: owner, with: callback)
        self.stateChangeCallbacks.open.append(delegated)
    }
    
    /// Registers callbacks for connection close events. Does not handle retain
    /// cycles. Use `onClose(_:)` for automatic handling of retain cycles.
    ///
    /// Example:
    ///
    ///     socket.manualOnClose() { [weak self] in
    ///         self?.print("Socket Connection Close")
    ///     }
    ///
    /// - parameter callback: Called when the Socket is closed
    public func manualOnClose(callback: @escaping () -> Void) {
        var delegated = Delegated<Void, Void>()
        delegated.manuallyDelegate(with: callback)
        self.stateChangeCallbacks.close.append(delegated)
    }
    
    /// Registers callbacks for connection close events. Automatically handles
    /// retain cycles. Use `manualOnClose()` to handle yourself.
    ///
    /// Example:
    ///
    ///     socket.onClose(self) { self in
    ///         self.print("Socket Connection Close")
    ///     }
    ///
    /// - parameter owner: Class registering the callback. Usually `self`
    /// - parameter callback: Called when the Socket is closed
    public func onClose<T: AnyObject>(_ owner: T,
                                     callback: @escaping ((T) -> Void)) {
        var delegated = Delegated<Void, Void>()
        delegated.delegate(to: owner, with: callback)
        self.stateChangeCallbacks.close.append(delegated)
    }
    
    
    /// Registers callbacks for connection error events. Does not handle retain
    /// cycles. Use `onError(_:)` for automatic handling of retain cycles.
    ///
    /// Example:
    ///
    ///     socket.manualOnError() { [weak self] (error) in
    ///         self?.print("Socket Connection Error", error)
    ///     }
    ///
    /// - parameter callback: Called when the Socket errors
    public func manualOnError(callback: @escaping (Error) -> Void) {
        var delegated = Delegated<Error, Void>()
        delegated.manuallyDelegate(with: callback)
        self.stateChangeCallbacks.error.append(delegated)
    }
    
    /// Registers callbacks for connection error events. Automatically handles
    /// retain cycles. Use `manualOnError()` to handle yourself.
    ///
    /// Example:
    ///
    ///     socket.onError(self) { (self, error) in
    ///         self.print("Socket Connection Error", error)
    ///     }
    ///
    /// - parameter owner: Class registering the callback. Usually `self`
    /// - parameter callback: Called when the Socket errors
    public func onClose<T: AnyObject>(_ owner: T,
                                      callback: @escaping ((T, Error) -> Void)) {
        var delegated = Delegated<Error, Void>()
        delegated.delegate(to: owner, with: callback)
        self.stateChangeCallbacks.error.append(delegated)
    }
    
    /// Registers callbacks for connection message events. Does not handle
    /// retain cycles. Use `onMessage(_:)` for automatic handling of retain
    /// cycles.
    ///
    /// Example:
    ///
    ///     socket.manualOnError() { [weak self] (message) in
    ///         self?.print("Socket Connection Message", message)
    ///     }
    ///
    /// - parameter callback: Called when the Socket receives a message event
    public func manualOnMessage(callback: @escaping (Message) -> Void) {
        var delegated = Delegated<Message, Void>()
        delegated.manuallyDelegate(with: callback)
        self.stateChangeCallbacks.message.append(delegated)
    }
    
    /// Registers callbacks for connection message events. Automatically handles
    /// retain cycles. Use `manualOnMessage()` to handle yourself.
    ///
    /// Example:
    ///
    ///     socket.onMessage(self) { (self, message) in
    ///         self.print("Socket Connection Message", message)
    ///     }
    ///
    /// - parameter owner: Class registering the callback. Usually `self`
    /// - parameter callback: Called when the Socket receives a message event
    public func onMessage<T: AnyObject>(_ owner: T,
                                      callback: @escaping ((T, Message) -> Void)) {
        var delegated = Delegated<Message, Void>()
        delegated.delegate(to: owner, with: callback)
        self.stateChangeCallbacks.message.append(delegated)
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
        self.channels.removeAll(where: { $0.joinRef == channel.joinRef })
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
        
        let callback: (() throws -> ()) = {
            var body: [String: Any] = [
                "topic": topic,
                "event": event,
                "payload": payload
            ]
            
            if let safeRef = ref { body["ref"] = safeRef }
            if let safeJoinRef = joinRef { body["join_ref"] = safeJoinRef}
            
            let data = try JSONSerialization.data(withJSONObject: body, options: JSONSerialization.WritingOptions())
            
            self.logItems("push", "Sending \(String(data: data, encoding: String.Encoding.utf8) ?? "")" )
            self.connection.write(data: data)
        }
        
        
        
        /// If the socket is connected, then execute the callback immediately.
        if isConnected {
            try? callback()
        } else {
            /// If the socket is not connected, add the push to a buffer which will
            /// be sent immediately upon connection.
            self.sendBuffer.append(callback)
        }
    }
    
    /// - return: the next message ref, accounting for overflows
    internal func makeRef() -> String {
        let newRef = self.ref + 1
        self.ref = (newRef == UInt64.max) ? 0 : newRef
        
        return String(newRef)
    }
    
    /// Logs the message. Override Socket.logger for specialized logging. noops by default
    ///
    /// - paramter items: List of items to be logged. Behaves just like debugPrint()
    internal func logItems(_ items: Any...) {
        let msg = items.map( { return String(describing: $0) } ).joined(separator: ", ")
        self.logger?("SwiftPhoenixClient: \(msg)")
    }
    
    
    //----------------------------------------------------------------------
    // MARK: - Connection Events
    //----------------------------------------------------------------------
    /// Called when the underlying Websocket connects to it's host
    private func onConnectionOpen() {
        self.logItems("transport", "Connected to \(endpointUrl.absoluteString)")
        
        // Send any messages that were waiting for a connection
        self.flushSendBuffer()
        
        // Reset how the socket tried to reconnect
        self.reconnectTimer.reset()
        
        // Restart the heartbeat timer
        self.resetHeartbeat()

        // Inform all onOpen callbacks that the Socket has opened
        self.stateChangeCallbacks.open.forEach({ $0.call() })
    }
    
    private func onConnectionClosed() {
        self.logItems("transport", "close")
        self.triggerChannelError()
        
        // Prevent the heartbeat from triggering if the
        self.heartbeatTimer?.invalidate()
        self.heartbeatTimer = nil
        
        // Attempt to reconnect the socket
        // TODO:?
//        if(event && event.code !== WS_CLOSE_NORMAL) {
//            this.reconnectTimer.scheduleTimeout()
//        }
//        if autoReconnect { self.reconnectTimer.scheduleTimeout() }
        
        self.stateChangeCallbacks.close.forEach({ $0.call() })
    }
    
    private func onConnectionError(_ error: Error) {
        self.logItems("transport", error)
        // Send an error to all channels
        self.triggerChannelError()
        
        // Inform any state callabcks of the error
        self.stateChangeCallbacks.error.forEach({ $0.call(error) })
    }
    
    private func onConnectionMessage(_ rawMessage: String) {
        self.logItems("receive ", rawMessage)

        guard
            let data = rawMessage.data(using: String.Encoding.utf8),
            let message = serializer.decode(data)
            else {
                self.logItems("receive: Unable to parse JSON: \(rawMessage)")
                return }
        
        // Clear heartbeat ref, preventing a heartbeat timeout disconnect
        if message.ref == pendingHeartbeatRef { pendingHeartbeatRef = nil }
        
        
        // Dispatch the message to all channels that belong to the topic
        self.channels
            .filter( { $0.isMember(message) } )
            .forEach( { $0.trigger(message) } )
        
        // Inform all onMessage callbacks of the message
        self.stateChangeCallbacks.message.forEach({ $0.call(message) })
    }
    
    /// Triggers an error event to all of the connected Channels
    private func triggerChannelError() {
        self.channels.forEach( { $0.trigger(event: ChannelEvent.error) } )
    }
    
    /// Send all messages that were buffered before the socket opened
    private  func flushSendBuffer() {
        guard isConnected && sendBuffer.count > 0 else { return }
        self.sendBuffer.forEach( { try? $0() } )
        self.sendBuffer = []
    }
    
    //----------------------------------------------------------------------
    // MARK: - Heartbeat
    //----------------------------------------------------------------------
    func resetHeartbeat() {
        // Clear anything related to the heartbeat
        self.pendingHeartbeatRef = nil
        self.heartbeatTimer?.invalidate()
        self.heartbeatTimer = nil
        
        // Do not start up the heartbeat timer if skipHeartbeat is true
        guard !skipHeartbeat else { return }
        
        // Start the timer based on the correct iOS version
        if #available(iOS 10.0, *) {
            self.heartbeatTimer
                = Timer.scheduledTimer(withTimeInterval: heartbeatInterval,
                                       repeats: true) { _ in self.sendHeartbeat() }
        } else {
            self.heartbeatTimer
                = Timer.scheduledTimer(timeInterval: heartbeatInterval,
                                       target: self,
                                       selector: #selector(sendHeartbeat),
                                       userInfo: nil,
                                       repeats: false)
        }
    }
    
    /// Sends a hearbeat payload to the phoenix serverss
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
            
            // Disconnect the socket manually. Do not use `teardown` or
            // `disconnect` as they will nil out the websocket delegate
            self.connection.disconnect(closeCode: WS_CLOSE_NORMAL)
            return
        }
        
        // The last heartbeat was acknowledged by the server. Send another one
        self.pendingHeartbeatRef = self.makeRef()
        self.push(topic: "phoenix",
                  event: ChannelEvent.heartbeat,
                  payload: [:],
                  ref: self.pendingHeartbeatRef)
    }
}


//----------------------------------------------------------------------
// MARK: - WebSocketDelegate
//----------------------------------------------------------------------
extension Socket: WebSocketDelegate {
    
    public func websocketDidConnect(socket: WebSocketClient) {
        self.onConnectionOpen()
    }
    
    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        guard let error = error else {
            self.onConnectionClosed()
            return }
        
        self.onConnectionError(error)
    }
    
    public func websocketDidReceiveMessage(socket: WebSocketClient,
                                           text: String) {
        self.onConnectionMessage(text)
    }
    
    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        /* no-op */
    }
}
