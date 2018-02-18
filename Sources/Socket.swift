//
//  Socket.swift
//  SwiftPhoenixClient
//

import Foundation
import Starscream

/// Special events
public struct PhoenixEvent {
    static let heartbeat = "heartbeat"
    static let join      = "phx_join"
    static let leave     = "phx_leave"
    static let reply     = "phx_reply"
    static let error     = "phx_error"
    static let close     = "phx_close"
}

/// Alias for a JSON dictionary [String: Any]
public typealias Payload = [String: Any]

public class Socket {
    
    //----------------------------------------------------------------------
    // MARK: - Public
    //----------------------------------------------------------------------
    /// Returns the socket protocol
    public var websocketProtocol: String { get { return _endpointUrl.scheme ?? "" } }
    
    /// The fully qualifed socket url
    public  var endpointUrl:  URL { get { return _endpointUrl } }
    private var _endpointUrl: URL
    
    /// Logs the message. Used for custom logging.
    public var log: ((_ msg: String) -> Void)?
    
    /// Registers callbacks for connection open events
    ///
    /// Example
    ///     socket.onOpen = { payload in print("socket opened") }"
    public var onOpen: (() -> Void)?
    
    /// Registers callbacks for connection close events
    public var onClose: (() -> Void)?
    
    /// Registers callbacks for connection error events
    ///
    /// Example
    ///     socket.onError = { error in print(error.localizedDescription) }"
    public var onError: ((Error) -> Void)?
    
    /// Registers callbacks for connection message events
    public var onMessage: ((Payload) -> Void)?
    
    /// - return: True if the socket is connected
    public var isConnected: Bool { return self._connection.isConnected }
    
    
    
    //----------------------------------------------------------------------
    // MARK: - Private
    //----------------------------------------------------------------------
    /// Collection of outbound events that are waiting for a response from the server
    var awaitingResponse: [String: Push] = [:]
    var channels: [String: Channel] = [:]

    var sendBuffer: [Void] = []
    var sendBufferTimer = Timer()
    let flushEveryMs = 1.0

    var reconnectTimer = Timer()
    let reconnectAfterMs = 1.0

    var heartbeatTimer = Timer()
    let heartbeatDelay = 30.0
    
    /// Counts messages that reference which message was sent to the server
    /// and which reply goes with which message
    var messageReference: UInt64 = UInt64.min // 0 (max: 18,446,744,073,709,551,615)
    
    
    /// Websocket connection to the server
    private let _connection: WebSocket
    
    
    //----------------------------------------------------------------------
    // MARK: - Initialization
    //----------------------------------------------------------------------
    /// Initializes a Socket
    ///
    /// - parameter connection: Websocket connection to maintain
    init(connection: WebSocket) {
        _connection = connection
        _endpointUrl = connection.currentURL
        
        log = { msg in
            #if DEBUG
                print(msg)
            #endif
        }
    }
    
    /// Initializes a Socket
    ///
    /// - parameter url: URL to point to
    /// - parameter params: Optional query parameters to append to the URL
    public convenience init(url: URL, params: [String: Any]? = nil) {
        guard
            var urlComponents = URLComponents(url: url,
                                              resolvingAgainstBaseURL: false),
            let params = params
            else {
                self.init(connection: WebSocket(url: url))
                return
            }
        
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
    
    
    
    
    //----------------------------------------------------------------------
    // MARK: - Public
    //----------------------------------------------------------------------
    /// Disconnects the Socket. onClose() will be fired when the socket closes
    ///
    /// - parameter callback: Called when disconnected
    public func disconnect(_ callback: (() -> Void)? = nil) {
        _connection.delegate = nil
        _connection.disconnect()
        
        callback?()
    }
    
    /// Connects the Socket
    ///
    /// - parameter params: The params to send when connecting, for example {user_id: userToken}
    public func connect() {
        _connection.delegate = self
        _connection.connect()
    }
    
    /// Removes a channel from the socket
    ///
    /// - parameter channel: Channel to remove
    public func remove(_ channel: Channel) {
        channel.leave().receive("ok") { [weak self] (_) in
            self?.channels.removeValue(forKey: channel.topic)
        }
    }
    
    /// Initiates a new channel for the given topic. If a channel already exists, then
    /// it is returned instead of a new one being created
    ///
    /// - parameter topic: Topic of the channel
    /// - parameter params: Parameters for the channel
    /// - return: A new channel
    public func channel(_ topic: String, params: [String: Any]? = nil) -> Channel {
        if let previousChannel = channels[topic] { return previousChannel }
        
        let channel = Channel(topic: topic, params: params, socket: self)
        self.channels[topic] = channel

        return channel
    }
    
    /// Sends an data through the Socket. You can bind to the
    /// returned Push object to receive successful and error events. A
    /// reference number will be generated for the message.
    ///
    /// - parameter topic: Message topic
    /// - parameter event: Message event
    /// - parameter payload: Optional. Extra payload to send with the message
    /// - return: Push instance that you can bind to for events
    public func push(topic: String, event: String, payload: [String: Any] = [:]) -> Push {
        let push = Push(topic: topic, event: event, payload: payload, ref: makeRef())
        return self.push(data: push)
    }
    
    /// Sends data through the Socket
    ///
    /// - parameter data: Data to send
    public func push(data: Push) -> Push {
        guard isConnected else {
            data.handleNotConnected()
            return data
        }
        
        do {
            let json = try data.toJson()
            
            // Store push objects that are waiting for status events
            self.awaitingResponse[data.ref] = data
            self._connection.write(data: json)
        } catch let error {
            log?("Failed to send message: \(error)")
            data.handleParseError()
        }
        
        return data
    }
    
    /// - return: the next message ref, accounting for overflows
    public func makeRef() -> String {
        let newRef = messageReference + 1
        messageReference = (newRef == UInt64.max) ? 0 : newRef
        
        return String(newRef)
    }
    
    
    //----------------------------------------------------------------------
    // MARK: - Timers
    //----------------------------------------------------------------------

    /// Invalidate open timers to allow socket to be deallocated when closed
    func invalidateTimers() {
        heartbeatTimer.invalidate()
        reconnectTimer.invalidate()
        sendBufferTimer.invalidate()

        heartbeatTimer = Timer()
        reconnectTimer = Timer()
        sendBufferTimer = Timer()
    }

    /// Initializes a 30s timer to let Phoenix know this device is still alive
    func startHeartbeatTimer() {
        heartbeatTimer.invalidate()
        heartbeatTimer = Timer.scheduledTimer(timeInterval: heartbeatDelay,
                                              target: self,
                                              selector: #selector(sendHeartbeat),
                                              userInfo: nil, repeats: true)
    }
    
    /// Resets the message buffer timer and invalidates any existing ones
    func resetBufferTimer() {
        sendBufferTimer.invalidate()
        sendBufferTimer = Timer.scheduledTimer(timeInterval: flushEveryMs,
                                               target: self,
                                               selector: #selector(flushSendBuffer),
                                               userInfo: nil, repeats: true)
        sendBufferTimer.fire()
    }

    
    //----------------------------------------------------------------------
    // MARK: - Selectors
    //----------------------------------------------------------------------
    /// Sends a hearbeat payload to the phoenix serverss
    @objc func sendHeartbeat() {
        let _ = push(topic: "phoenix", event: PhoenixEvent.heartbeat)
    }
    
    /// Send all messages in the buffer
    @objc func flushSendBuffer() {
        if _connection.isConnected && sendBuffer.count > 0 {
            for runner in sendBuffer { runner }
            sendBuffer = []
            resetBufferTimer()
        }
    }

    
    /// Distributes a response to all channels that have joined
    /// the response's topic
    func dispatch(response: Response) {
        guard let channel = channels[response.topic] else { return }
        channel.trigger(event: response.event, with: response.payload, ref: response.ref)
    }
}


//----------------------------------------------------------------------
// MARK: - WebSocketDelegate
//----------------------------------------------------------------------
extension Socket: WebSocketDelegate {
    
    public func websocketDidConnect(socket: WebSocketClient) {
        log?("SwiftPhoenixClient: Socket Opened")
        onOpen?()
        
        startHeartbeatTimer()
    }
    
    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        self.awaitingResponse.removeAll()
        
        if let error = error {
            log?("SwiftPhoenixClient: Socket disconnected due to error: \(error)")
            onError?(error)
        } else {
            log?("SwiftPhoenixClient: Socket Closed")
            onClose?()
        }
    }
    
    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        log?("SwiftPhoenixClient: Received: \(text)")
        
        guard let data = text.data(using: String.Encoding.utf8),
            let response = Response(data: data)
            else {
                log?("SwiftPhoenixClient: Unable to parse JSON: \(text)")
                return }
        
        defer {
            self.awaitingResponse.removeValue(forKey: response.ref)
        }
        
        if let push = self.awaitingResponse[response.ref] {
            push.handleResponse(response)
        }
        
        dispatch(response: response)
    }
    
    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) { /* no-op */ }
    
}
