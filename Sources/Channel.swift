//
//  Channel.swift
//  SwiftPhoenixClient
//

import Swift

///
/// Represents a Channel which is bound to a topic
///
/// A Channel can bind to multiple events on a given topic and
/// be informed when those events occur within a topic.
///
/// Example:
///     channel.on(event: "new_message", { response in
///         print(response.payload)
///     }
///
public class Channel {
    
    /// The topic of the Channel. e.g. "rooms:friends"
    public let topic: String
    
    /// The payload sent when joining the channel
    public let payload: Socket.Payload
    
    /// Returns the channel that is joined
    internal let joinClosure: ((Channel) -> Void)
    
    /// Collection of all event closures to trigger events to
    fileprivate var eventHandlers: [String: ((Socket.Payload) -> Void)]
    
    /// The Socket that the channel belongs to
    fileprivate let socket: Socket
    
    
    //----------------------------------------------------------------------
    // MARK: - Initialization
    //----------------------------------------------------------------------
    init(socket: Socket, topic: String, payload: Socket.Payload?, joinClosure:@escaping ((Channel) -> Void)) {
        self.socket = socket
        self.topic = topic
        self.payload = payload ?? [:]
        self.joinClosure = joinClosure
        self.eventHandlers = [:]
    }

    
    //----------------------------------------------------------------------
    // MARK: - Message Sending
    //----------------------------------------------------------------------
    /// Leaves the channel
    ///
    /// - parameter payload: Optional message to send to the server when leaving
    public func leave(payload: Socket.Payload?) {
        socket.leave(topic: topic, payload: payload ?? [:])
        
        // Release all event handlers
        self.reset()
    }
    
    /// Sends an event and message to the Channel's topic
    ///
    /// - parameter event: Event name
    /// - parameter message: Message to send
    public func send(event: String, payload: Socket.Payload?) -> Outbound {
        Logger.debug(message: "conn sending")
        return socket.send(event: event, topic: topic, payload: payload ?? [:])
    }
    
    
    //----------------------------------------------------------------------
    // MARK: - Event Handling
    //----------------------------------------------------------------------
    /// Bind to events that occur on the channel
    ///
    /// - parameter event: Name of the event to bind to
    /// - closure: Called whenever an event occurs
    public func on(event: String, handler: @escaping ((Socket.Payload) -> Void)) {
        
        self.eventHandlers[event] = handler
    }

    /// Unbinds from an event that occurs on  the channel
    ///
    /// - parameter event: Name of the event to unbind from
    public func off(event: String) {
        self.eventHandlers.removeValue(forKey: event)
    }


    //----------------------------------------------------------------------
    // MARK: - Internal
    //----------------------------------------------------------------------
    /// Triggers a response to be sent to the closure bounds to the event.
    /// If no closure is bound to the event then the call is ignored
    ///
    /// - parameter named: Name of the event
    /// - parameter response: Response to send to the closure
    func triggerEvent(named: String, with payload: Socket.Payload) {
        guard let handler = self.eventHandlers[named] else {
            Logger.debug(message: "No closure bound to the event named \(named)")
            return }
        
        handler(payload)
    }
    
    /// Joins the channel
    @discardableResult
    func join() -> Outbound {
        self.eventHandlers = [:]
        return socket.send(event: PhoenixEvent.join, 
                           topic: topic, payload: payload)
    }
    
    /// Releases any event handlers that the channel was bound to
    func reset() {
        self.eventHandlers = [:]
    }
}
