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
///     let channel = socket.channel("room:123, params: ["token: "Room Token"])
///     channel.on("new_msg") { payload in print("Got message", payload") }
///     channel.push("new_msg, payload: ["body": "This is a message"])
///         .receive("ok") { payload in print("Sent message", payload) }
///         .receive("error") { payload in print("Send failed", payload) }
///         .receive("timeout") { payload in print("Networking issue...", payload) }
///
///     channel.join()
///         .receive("ok") { payload in print("Channel Joined", payload) }
///         .receive("error") { payload in print("Failed ot join", payload) }
///         .receive("timeout") { payload in print("Networking issue...", payload) }
///
public class Channel {
    
    /// The topic of the Channel. e.g. "rooms:friends"
    public let topic: String
    
    /// The params sent when joining the channel
    public let params: Payload

    /// The Socket that the channel belongs to
    fileprivate let socket: Socket

    /// Collection of all event closures to trigger events to
    fileprivate var onEvents: [String: ((Payload) -> Void)]

    
    /// Callback hook into channel error
    ///
    /// - parameter payload: The payload from the server on close
    var onError: ((_ payload: Payload) -> Void)?
    
    /// Callback hook informed when the channel closes
    ///
    /// - parameter payload: The payload from the server on close
    var onClose: ((_ payload: Payload) -> Void)?
    
    /// Overridable message hook. Receives all events for specialized message
    /// handling before dispatching to the channel callbacks.
    ///
    /// - paremeter event: The event the message was for
    /// - parameter payload: The payload for the message
    /// - parameter ref: The reference of the message
    /// - return: Must return the payload, modified or unmodified
    var onMessage: ((_ event: String, _ payload: Payload, _ ref: String) -> Payload)?
    


    //----------------------------------------------------------------------
    // MARK: - Initialization
    //----------------------------------------------------------------------
    /// Initialize a Channel
    ///
    /// - parameter topic: Topic of the Channel
    /// - paremeter params: Parameters to send when joining. Can be nil
    /// - parameter socket: Socket that the channel is a part of
    init(topic: String, params: [String: Any]?, socket: Socket) {
        self.topic = topic
        self.params = params ?? [:]
        self.socket = socket
        
        self.onEvents = [:]
    }

    
    
    //----------------------------------------------------------------------
    // MARK: - Public
    //----------------------------------------------------------------------
    /// Joins the channel
    ///
    /// - paremeter timeout: Optional timeout
    /// - return: Push which can receive hooks can be applied to
    public func join(timeout: Int? = nil) -> Push {
        return socket.push(topic: topic, event: PhoenixEvent.join)
        
    }
    
    /// Hook into channel close
    ///
    /// - parameter callback: Callback to be informed when channel closes
    public func onClose(_ callback: @escaping ((_ payload: Payload) -> Void)) {
        self.onClose = callback
    }
    
    /// Hook into channel error
    ///
    /// - parameter callback: Callback to be informed when channel errors
    public func onError(_ callback: @escaping ((_ payload: Payload) -> Void)) {
        self.onError = callback
    }
    
    /// Subscribes on channel events
    ///
    /// - parameter event: Name of the event to subscribe to
    /// - parameter callback: Reveives payload of the event
    public func on(_ event: String, callback: @escaping ((Payload) -> Void)) {
        self.onEvents[event] = callback
    }
    
    /// Unsubscribes from channel events
    public func off(_ event: String) {
        self.onEvents.removeValue(forKey: event)
    }
    
    /// Push a payload to the Channel
    ///
    /// - parameter event: Event to push
    /// - parameter payload: Payload to push
    /// - parameter timeout: Optional timeout
    public func push(_ event: String, payload: Payload, timeout: Int? = nil) -> Push {
        return socket.push(topic: topic, event: event, payload: payload)
    }
    
    /// Leaves the channel, unsubscribing from server events, and instructs channel
    /// to terminate on server. Triggers onClose() hooks. // To receive leave
    /// acknowledgements, use the a receive hook to bind to the server ack.
    ///
    /// Example:
    ///     channel.leave().receive("ok") { _ in { print("left") }
    ///
    /// - parameter timeout: Optional timeout
    @discardableResult
    public func leave(timeout: Int? = nil) -> Push {
        return socket.push(topic: topic, event: PhoenixEvent.leave)
    }
    
    /// Overridable message hook. Receives all events for specialized message
    /// handling before dispatching to the channel callbacks.
    ///
    /// - paremeter event: The event the message was for
    /// - parameter payload: The payload for the message
    /// - parameter ref: The reference of the message
    /// - return: Must return the payload, modified or unmodified
    public func onMessage(_ callback: @escaping ((_ event: String, _ payload: Payload, _ ref: String) -> Payload)) {
        self.onMessage = callback
    }


    //----------------------------------------------------------------------
    // MARK: - Internal
    //----------------------------------------------------------------------
    /// Triggers a response to be sent to the closure bounds to the event.
    /// If no closure is bound to the event then the call is ignored
    ///
    /// - parameter named: Name of the event
    /// - parameter response: Response to send to the closure
    func trigger(event: String, with payload: Payload, ref: String) {
        var _payload = payload
        if let onMessageHook = self.onMessage {
            _payload = onMessageHook(event, _payload, ref)
        }
        
        guard let onEvent = self.onEvents[event] else { return }
        onEvent(_payload)
    }
}
