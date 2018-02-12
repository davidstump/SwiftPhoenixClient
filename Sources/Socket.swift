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

public class Socket {
    
    /// Alias for a JSON dictionary [String: Any]
    public typealias Payload = [String: Any]
    
    /// Websocket connection to the server
    private let _connection: WebSocket
    
    /// URL the Socket is pointed to
    public  var endpoint:  URL { get { return _endpoint } }
    private let _endpoint: URL
    
    fileprivate var awaitingResponse: [String: Outbound] = [:]
    var channels: [Channel] = []

    var sendBuffer: [Void] = []
    var sendBufferTimer = Timer()
    let flushEveryMs = 1.0

    var reconnectTimer = Timer()
    let reconnectAfterMs = 1.0

    var heartbeatTimer = Timer()
    let heartbeatDelay = 30.0

    
    //----------------------------------------------------------------------
    // MARK: - Initialization
    //----------------------------------------------------------------------
    /// Initializes a Socket
    ///
    /// - parameter connection: Websocket connection to maintain
    init(connection: WebSocket) {
        _connection = connection
        _endpoint = connection.currentURL
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
    // MARK: - Connection
    //----------------------------------------------------------------------
    /// Opens the connection
    public func open() {
        resetBufferTimer()
        
        _connection.delegate = self
        _connection.connect()
    }
    
    /// Closes the connection. All channels are maintained, so if the socket
    /// opened again, then all channels will be rejoined. To prevent this,
    /// pass reset: true
    ///
    /// - parameter reset: True to remove all previous channels. Default is false
    public func close(reset: Bool = false) {
        _connection.delegate = nil
        _connection.disconnect()
        
        invalidateTimers()
        
        // Clear all channels so they will not be rejoined on open
        if reset { self.channels = [] }
    }
    
    
    //----------------------------------------------------------------------
    // MARK: - Channels
    //----------------------------------------------------------------------
    /// Joins a topic's channel
    ///
    /// - parameter topic: Topic of the channel to join
    /// - parameter payload: Optional payload to send when joining a channel
    /// - parameter closure: Called when the channel is available for binding to events
    public func join(topic: String, payload: Payload? = nil, _ closure: @escaping ((Channel) -> Void)) {
        let channel = Channel(socket: self, topic: topic, payload: payload, joinClosure: closure)
        self.channels.append(channel)
        
        channel.join()
        channel.joinClosure(channel)
    }
    
    /// Leave a channel
    ///
    /// - parameter topic: Topic of the channel to leave
    /// - parameter payload: Optional payload to send when leaving a channel
    public func leave(topic: String, payload: Payload? = nil) {
        let outbound = Outbound(topic: topic,
                                event: PhoenixEvent.leave,
                                payload: payload ?? [:])
        let _ = send(outbound: outbound)
        
        // Release any channels that belongde to the topic
        var newChannels: [Channel] = []
        for chan in channels {
            let c = chan as Channel
            if c.topic != topic {
                newChannels.append(c)
            }
        }
        channels = newChannels
    }
    
    //----------------------------------------------------------------------
    // MARK: - Send
    //----------------------------------------------------------------------
    /// Sends an outbound message through the Socket. You can bind to the
    /// returned Outbound objet to receive successful and error events.
    ///
    /// - parameter event: Message event
    /// - parameter topic: Message topic
    /// - parameter payload: Optional. Extra payload to send with the message
    /// = return: Outbound instance that you can bind to for events
    public func send(event: String, topic: String, payload: Socket.Payload = [:]) -> Outbound {
        let outbound = Outbound(topic: topic, event: event, payload: payload)
        return self.send(outbound: outbound)
    }
    
    /// Sends an outbound message through the Socket. You can bind to the
    /// returned Outbound objet to receive successful and error events.
    ///
    /// - parameter outbound: Outbound payload to send
    /// = return: Outbound instance that you can bind to for events
    public func send(outbound: Outbound) -> Outbound {
        let runner = { (toSend: Outbound) -> Void in
            do {
                let json = try toSend.toJson()
                
                // Store outbounds that are waiting for a successful response
                self.awaitingResponse[toSend.ref] = toSend
                
                self._connection.write(data: json)
            } catch let error {
                Logger.debug(message: "Failed to parse message: \(error)")
                toSend.handleParseError()
            }
        }
        
        // If the socket is oepn, then send the outbound message. If closed,
        // then store the message in a buffer to send once the soecket is opened
        guard _connection.isConnected else {
            sendBuffer.append(runner(outbound))
            return outbound
        }
        
        runner(outbound)
        return outbound
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
        let _ = send(event: "phoenix", topic: PhoenixEvent.heartbeat)
    }

    /// Reopens the Socket
    @objc public func reopen() {
        self.close()
        self.open()
    }
    
    /// Send all messages in the buffer
    @objc func flushSendBuffer() {
        if _connection.isConnected && sendBuffer.count > 0 {
            for runner in sendBuffer { runner }
            sendBuffer = []
            resetBufferTimer()
        }
    }

    

    /// Triggers an error event out to all channels
    ///
    /// - parameter error: Error from the underlying connection
    func onError(error: Error) {
        Logger.debug(message: "Error: \(error)")
//        for chan in channels {
//            let msg = Message(message: ["body": error.localizedDescription] as Any)
//            chan.trigger(triggerEvent: "error", msg: msg)
//        }
    }

    /// Rejoins all Channels that were previously joined
    func rejoinAll() {
        for channel in channels {
            channel.join()
            channel.joinClosure(channel)
        }
    }
    
    /// Distributes a response to all channels that have joined
    /// the response's topic
    func dispatch(response: Response) {
        for channel in channels {
            if channel.topic == response.topic {
                channel.triggerEvent(named: response.event, with: response.payload)
            }
        }
    }
}


//----------------------------------------------------------------------
// MARK: - WebSocketDelegate
//----------------------------------------------------------------------
extension Socket: WebSocketDelegate {
    
    public func websocketDidConnect(socket: WebSocketClient) {
        Logger.debug(message: "socket opened")
        
        // Kills reconnect timer and joins all open channels
        reconnectTimer.invalidate()
        startHeartbeatTimer()
        rejoinAll()
    }
    
    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        if let error = error { onError(error: error) }
        
        Logger.debug(message: "socket closed: \(error?.localizedDescription ?? "Unknown error")")
        
        self.awaitingResponse.removeAll()
        
        // Begins the reconnect Timer. If the user manually disconnected the socket
        // then the timer will be inalidated and no reconnection will be tried
        reconnectTimer.invalidate()
        reconnectTimer = Timer.scheduledTimer(timeInterval: reconnectAfterMs,
                                              target: self,
                                              selector: #selector(reopen),
                                              userInfo: nil,
                                              repeats: true)
    }
    
    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        Logger.debug(message: "socket received: \(text)")
        
        guard let data = text.data(using: String.Encoding.utf8),
            let response = Response(data: data)
            else {
                Logger.debug(message: "Unable to parse JSON: \(text)")
                return }
        
        defer {
            self.awaitingResponse.removeValue(forKey: response.ref)
        }
        
        if let outbound = self.awaitingResponse[response.ref] {
            outbound.handleResponse(response)
        }
        
        Logger.debug(message: "Phoenix Response: \(response.description)")
        dispatch(response: response)
    }
    
    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        Logger.debug(message: "got some data: \(data.count)")
    }
    
    
}
