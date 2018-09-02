//
//  Socket.swift
//  SwiftPhoenixClient
//

import Foundation
import Starscream

/// Alias for a JSON dictionary [String: Any]
public typealias Payload = [String: Any]

public class Socket {
    
    //----------------------------------------------------------------------
    // MARK: - Public Attributes
    //----------------------------------------------------------------------
    /// Timeout to use when opening connections
    public var timeout: Int = PHOENIX_DEFAULT_TIMEOUT
    
    /// Interval between sending a heartbeat
    public var heartbeatIntervalMs: Int = PHOENIX_DEFAULT_HEARTBEAT
    
    /// Internval between socket reconnect attempts
    public var reconnectAfterMs: (_ tryCount: Int) -> Int = { tryCount in
        guard tryCount < 4 else { return 10000 } // After 4 tries, default to 10 second retries
        return [1000, 2000, 5000, 10000][tryCount]
    }
    
    /// Hook for custom logging into the client
    public var logger: ((_ msg: String) -> Void)?
    
    /// Disable sending Heartbeats by setting to true
    public var skipHeartbeat: Bool = false
    
    /// Socket will attempt to reconnect if the Socket was closed. Will not
    /// reconnect if the Socket errored (e.g. connection refused.) Default
    /// is set to true
    public var autoReconnect: Bool = true
    
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
    
    
    
    //----------------------------------------------------------------------
    // MARK: - Private Attributes
    //----------------------------------------------------------------------
    /// Collection of callbacks for onOpen socket events
    private var onOpenCallbacks: [() -> Void] = []
    
    /// Collection of callbacks for onClose socket events
    private var onCloseCallbacks: [() -> Void] = []
    
    /// Collection of callbacks for onError socket events
    private var onErrorCallbacks: [(Error) -> Void] = []
    
    /// Collection of callbacks for onMessage socket events
    private var onMessageCallbacks: [(Message) -> Void] = []
    
    /// Collection on channels created for the Socket
    private var channels: [Channel] = []
    
    /// Buffers messages that need to be sent once the socket has connected
    private var sendBuffer: [() throws -> ()] = []
    
    /// Ref counter for messages
    private var ref: UInt64 = UInt64.min // 0 (max: 18,446,744,073,709,551,615)
    
    /// Params appendend to the URL when connecting
    private var params: Payload?
    
    /// Internal endpoint that the Socket is connecting to
    private var _endpoint: URL
    
    /// Timer that triggers sending new Heartbeat messages
    private var heartbeatTimer: Timer?
    
    /// Ref counter for the last heartbeat that was sent
    private var pendingHeartbeatRef: String?
    
    /// Timer to use when attempting to reconnect
    private var reconnectTimer: PhxTimer!
    
    /// Websocket connection to the server
    private let connection: WebSocket
    
    
    //----------------------------------------------------------------------
    // MARK: - Initialization
    //----------------------------------------------------------------------
    /// Initializes a Socket
    ///
    /// - parameter connection: Websocket connection to maintain
    init(connection: WebSocket) {
        self.connection = connection
        self._endpoint = connection.currentURL
        self.reconnectTimer = PhxTimer(callback: { [weak self] in
            self?.disconnect({ self?.connect() })
        }, timerCalc: { [weak self] tryCount in
            return self?.reconnectAfterMs(tryCount) ?? 10000
        })
    }
    
    /// Initializes the Socket
    ///
    /// - parameter url: The string Websocket endpoint. ie "ws://example.com/socket", "wss://example.com/socket
    /// - parameter params: Optional parameters to pass when connecting
    public convenience init(url: URL, params: [String: Any]? = nil) {
        guard
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let params = params
            else {
                self.init(connection: WebSocket(url: url))
                return }
        
        urlComponents.queryItems
            = params.map({ return URLQueryItem(name: $0.key,
                                               value: String(describing: $0.value)) })
        guard let url = urlComponents.url else { fatalError("Malformed URL while adding paramters") }
        self.init(connection: WebSocket(url: url))
    }
    
    /// Initializes a Socket
    ///
    /// - parameter url: String representation of URL to point to
    /// - parameter params: Optional query parameters to append to the URL
    public convenience init(url: String, params: [String: Any]? = nil) {
        guard let parsedUrl = URL(string: url) else { fatalError("Malformed URL String \(url)") }
        self.init(url: parsedUrl, params: params)
    }
    
    deinit {
        reconnectTimer.reset()
    }
    
    //----------------------------------------------------------------------
    // MARK: - Public
    //----------------------------------------------------------------------
    /// Returns the socket protocol
    public var websocketProtocol: String {
        get { return _endpoint.scheme ?? "" }
    }
    
    /// The fully qualified socket URL
    public var endpointUrl:  URL {
        get { return _endpoint }
    }
    
    // TODO:
    public var connectionState: SocketState {
        return SocketState.closed
    }
    
    /// - return: True if the socket is connected
    public var isConnected: Bool {
        return self.connection.isConnected
    }
    
    /// Disconnects the Socket. onClose() will be fired when the socket closes
    ///
    /// - parameter callback: Called when disconnected
    public func disconnect(_ callback: (() -> Void)? = nil) {
        connection.delegate = nil
        connection.disconnect()

        self.heartbeatTimer?.invalidate()
        self.onCloseCallbacks.forEach( { $0() } )
        
        callback?()
    }
    
    /// Connects the Socket. The params passed to the Socket on initialization
    /// will be sent through the connection. If the Socket is already connected,
    /// then this call will be ignored.
    public func connect() {
        // Do not attempt to reconnect if the socket is currently connected
        guard !isConnected else { return }
        
        connection.delegate = self
        connection.connect()
    }
    
    /// Registers a callback for connection open events
    ///
    /// Example:
    ///     socket.onOpen { [unowned self] in
    ///         print("Socket Connection Opened")
    ///     }
    ///
    /// - parameter callback: Callback to register
    public func onOpen(callback: @escaping () -> Void) {
        self.onOpenCallbacks.append(callback)
    }
    
    
    /// Registers a callback for connection close events
    ///
    /// Example:
    ///     socket.onClose { [unowned self] in
    ///         print("Socket Connection Closed")
    ///     }
    ///
    /// - parameter callback: Callback to register
    public func onClose(callback: @escaping () -> Void) {
        self.onCloseCallbacks.append(callback)
    }
    
    /// Registers a callback for connection error events
    ///
    /// Example:
    ///     socket.onError { [unowned self] (error) in
    ///         print("Socket Connection Error")
    ///     }
    ///
    /// - parameter callback: Callback to register
    public func onError(callback: @escaping (Error) -> Void) {
        self.onErrorCallbacks.append(callback)
    }
    
    /// Registers a callback for connection message events
    ///
    /// Example:
    ///     socket.onMessage { [unowned self] (message) in
    ///         print("Socket Connection Message")
    ///     }
    ///
    /// - parameter callback: Callback to register
    public func onMessage(callback: @escaping (Message) -> Void) {
        self.onMessageCallbacks.append(callback)
    }
    
    /// Releases all stored callback hooks (onError, onOpen, onClose, etc.) You should
    /// call this method when you are finished when the Socket in order to release
    /// any references held by the socket.
    public func removeAllCallbacks() {
        self.onOpenCallbacks.removeAll()
        self.onCloseCallbacks.removeAll()
        self.onErrorCallbacks.removeAll()
        self.onMessageCallbacks.removeAll()
    }
    
    
    /// Removes the Channel from the socket. This does not cause the channel to
    /// inform the server that it is leaving. You should call channel.leave() first.
    public func remove(_ channel: Channel) {
        self.channels = channels.filter( { $0.joinRef != channel.joinRef } )
    }
    
    /// Initialize a new Channel with a given topic
    ///
    /// Example:
    ///     let channel = socket.channel("rooms", params: ["user_id": "abc123"])
    ///
    /// - parameter topic: Topic of the channel
    /// - parameter params: Parameters for the channel
    /// - return: A new channel
    public func channel(_ topic: String, params: [String: Any]? = nil) -> Channel {
        let channel = Channel(topic: topic, params: params, socket: self)
        self.channels.append(channel)
        
        return channel
    }
    
    
    /// Sends data through the Socket
    ///
    /// - parameter data: Data to send
    public func push(topic: String, event: String, payload: Payload, ref: String? = nil, joinRef: String? = nil) {
        
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
    public func makeRef() -> String {
        let newRef = self.ref + 1
        self.ref = (newRef == UInt64.max) ? 0 : newRef
        
        return String(newRef)
    }
    
    
    
    //----------------------------------------------------------------------
    // MARK: - Library Internal
    //----------------------------------------------------------------------
    /// Logs the message. Override Socket.logger for specialized logging. noops by default
    ///
    /// - paramter items: List of items to be logged. Behaves just like debugPrint()
    func logItems(_ items: Any...) {
        let msg = items.map( { return String(describing: $0) } ).joined(separator: ", ")
        self.logger?("SwiftPhoenixClient: \(msg)")
    }
    
    
    //----------------------------------------------------------------------
    // MARK: - Private
    //----------------------------------------------------------------------
    /// Called when the underlying Websocket connects to it's host
    private func onConnectionOpen() {
        self.logItems("transport", "Connected to \(_endpoint.absoluteString)")
        self.flushSendBuffer()
        self.reconnectTimer.reset()

        
        // Start sending heartbeats if enabled
        if !skipHeartbeat { self.startHeartbeatTimer() }
        
        // Inform all onOpen callbacks that the Socket has opened
        self.onOpenCallbacks.forEach( { $0() } )
    }
    
    private func onConnectionClosed() {
        self.logItems("transport", "close")
        self.triggerChannelError()
        self.heartbeatTimer?.invalidate()
        
        // Attempt to reconnect the socket
        if autoReconnect { self.reconnectTimer.scheduleTimeout() }
        self.onCloseCallbacks.forEach( { $0() } )
    }
    
    private func onConnectionError(_ error: Error) {
        self.logItems("transport", error)
        self.onErrorCallbacks.forEach( { $0(error) } )
        self.triggerChannelError()
    }
    
    private func onConnectionMessage(_ rawMessage: String) {
        self.logItems("receive ", rawMessage)
        
        guard
            let data = rawMessage.data(using: String.Encoding.utf8),
            let message = Message(data: data)
            else {
                self.logItems("receive: Unable to parse JSON: \(rawMessage)")
                return }
        
        // Dispatch the message to all channels that belong to the topic
        self.channels
            .filter( { $0.isMember(message) } )
            .forEach( { $0.trigger(message) } )
        
        // Inform all onMessage callbacks of the message
        self.onMessageCallbacks.forEach( { $0(message) } )
        
        // Check if this message was a pending heartbeat
        if message.ref == pendingHeartbeatRef {
            self.logItems("received pending heartbeat")
            pendingHeartbeatRef = nil
        }
    }
    
    /// Triggers an error event to all of the connected Channels
    private func triggerChannelError() {
        let errorMessage = Message(event: ChannelEvent.error)
        self.channels.forEach( { $0.trigger(errorMessage) } )
    }
    
    /// Send all messages that were buffered before the socket opened
    private  func flushSendBuffer() {
        guard isConnected && sendBuffer.count > 0 else { return }
        self.sendBuffer.forEach( { try? $0() } )
        self.sendBuffer = []
    }
    
    //----------------------------------------------------------------------
    // MARK: - Timers
    //----------------------------------------------------------------------
    /// Initializes a 30s timer to let Phoenix know this device is still alive
    func startHeartbeatTimer() {
        let heartbeatInterval = TimeInterval(heartbeatIntervalMs / 1000)
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(timeInterval: heartbeatInterval,
                                              target: self,
                                              selector: #selector(sendHeartbeat),
                                              userInfo: nil, repeats: true)
    }
    
    
    //----------------------------------------------------------------------
    // MARK: - Selectors
    //----------------------------------------------------------------------
    /// Sends a hearbeat payload to the phoenix serverss
    @objc func sendHeartbeat() {
        guard isConnected else { return }
        if let _ = self.pendingHeartbeatRef {
            self.pendingHeartbeatRef = nil
            self.logItems("transport", "heartbeat timeout. Attempting to re-establish connection")
            self.connection.disconnect()
            return
        }
        
        self.pendingHeartbeatRef = self.makeRef()
        self.push(topic: "phoenix", event: ChannelEvent.heartbeat, payload: [:], ref: self.pendingHeartbeatRef)
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
    
    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        self.onConnectionMessage(text)
    }
    
    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        /* no-op */
    }
}
