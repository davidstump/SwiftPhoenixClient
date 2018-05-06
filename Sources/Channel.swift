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
///     let channel = socket.channel("room:123", params: ["token": "Room Token"])
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
    let topic: String
    
    /// The params sent when joining the channel
    var params: Payload

    /// The Socket that the channel belongs to
    let socket: Socket

    
    /// Current state of the Channel
    private var state: ChannelState
    
    /// Collection of event bindings
    private var bindings: [(event: String, ref: Int, callback: (Payload) -> Void)]
    
    /// Tracks event binding ref counters
    private var bindingRef: Int
    
    /// Timout when attempting to join a Channel
    private var timeout: Int
    
    /// Set to true once the channel calls .join()
    private var joinedOnce: Bool
    
    /// Push to send when the channel calls .join()
    private var joinPush: Push!
    
    /// Buffer of Pushes that will be sent once the Channel's socket connects
    private var pushBuffer: [Push]
    
    /// Timer to attempt to rejoin
    private var rejoinTimer: PhxTimer!
    

    
    


    //----------------------------------------------------------------------
    // MARK: - Initialization
    //----------------------------------------------------------------------
    /// Initialize a Channel
    ///
    /// - parameter topic: Topic of the Channel
    /// - parameter params: Parameters to send when joining. Can be nil
    /// - parameter socket: Socket that the channel is a part of
    init(topic: String, params: [String: Any]?, socket: Socket) {
        self.state = ChannelState.closed
        self.topic = topic
        self.params = params ?? [:]
        self.socket = socket
        self.bindings = []
        self.bindingRef = 0
        self.timeout = PHOENIX_DEFAULT_TIMEOUT // socket.timeout    
        self.joinedOnce = false
        self.pushBuffer = []
        self.joinPush = Push(channel: self, event: ChannelEvent.join, payload: self.params, timeout: self.timeout)
        
        self.rejoinTimer = PhxTimer(callback: {
            self.rejoinTimer?.scheduleTimeout()
            if self.socket.isConnected { self.rejoin() }
        }, timerCalc: socket.reconnectAfterMs)
        
        /// Perfom once the Channel is joined
        self.joinPush.receive("ok") { (_) in
            self.state = ChannelState.joined
            self.rejoinTimer?.reset()
            self.pushBuffer.forEach( { $0.send() })
            self.pushBuffer = [Push]()
        }
        
        /// Perfom when the Channel has been closed
        self.onClose { (_) in
            self.rejoinTimer?.reset()
            self.socket.logItems("channel", "close \(self.topic)")
            self.state = ChannelState.closed
            self.socket.remove(self)
        }
        
        /// Perfom when the Channel errors
        self.onError { (_) in
            guard self.isLeaving || !self.isClosed else { return }
            self.socket.logItems("channel", "error \(self.topic)")
            self.state = ChannelState.errored
            self.rejoinTimer?.scheduleTimeout()
        }
        
        self.joinPush.receive("timeout") { (_) in
            guard !self.isJoining else { return }
            self.socket.logItems("channel", "timeout \(self.topic) \(self.joinRef) after \(self.timeout)ms")
            
            let leavePush = Push(channel: self, event: ChannelEvent.leave, payload: [:], timeout: self.timeout)
            leavePush.send()
            
            self.state = ChannelState.errored
            self.joinPush.reset()
            self.rejoinTimer?.scheduleTimeout()
        }
        
        self.on(ChannelEvent.reply) { (payload) in
            print("Channel Reply")
//            self.trigger(event: self.replyEventName(ref), with: <#T##Payload#>, ref: <#T##String#>)
        }
    }
    
    
    /// Overridable message hook. Receives all events for specialized message
    /// handling before dispatching to the channel callbacks.
    ///
    /// - parameter event: The event the message was for
    /// - parameter payload: The payload for the message
    /// - parameter ref: The reference of the message
    /// - return: Must return the payload, modified or unmodified
    var onMessage: ((_ event: String, _ payload: Payload, _ ref: String) -> Payload) = { (_, payload, _) in
        return payload
    }
    
    
    //----------------------------------------------------------------------
    // MARK: - Public
    //----------------------------------------------------------------------
    /// Joins the channel
    ///
    /// - parameter timeout: Optional timeout
    /// - return: Push which can receive hooks can be applied to
    public func join(timeout: Int? = nil) -> Push {
        guard !joinedOnce else { fatalError("Tried to join channel multiple times. 'join()' can only be called once per channel instance")}
        
        self.joinedOnce = true
        self.rejoin(timeout)
        return joinPush
    }
    
    
    /// Hook into channel close
    ///
    /// - parameter callback: Callback to be informed when channel closes
    /// - return: The ref counter of the subscription
    @discardableResult
    public func onClose(_ callback: @escaping ((_ payload: Payload) -> Void)) -> Int {
        return self.on(ChannelEvent.close, callback: callback)
    }
    
    /// Hook into channel error
    ///
    /// - parameter callback: Callback to be informed when channel errors
    /// - return: The ref counter of the subscription
    @discardableResult
    public func onError(_ callback: @escaping ((_ payload: Payload) -> Void)) -> Int {
        return self.on(ChannelEvent.error, callback: callback)
    }
    
    /// Subscribes on channel events
    ///
    /// Subscription returns the ref counter, which can be used later
    /// to unsubscribe the exact event listener.
    ///
    /// Example:
    ///     let ref1 = channel.on("event", do_stuff)
    ///     let ref2 = channel.on("event", do_other_stuff)
    ///     channel.off("event", ref1)
    ///
    /// This example will unsubscribe the "do_stuff" callback but
    /// not the "do_other_stuff" callback.
    ///
    /// - parameter event: Name of the event to subscribe to
    /// - parameter callback: Reveives payload of the event
    /// - return: The ref counter
    @discardableResult
    public func on(_ event: String, callback: @escaping ((Payload) -> Void)) -> Int {
        let ref = bindingRef
        self.bindingRef = ref + 1
        
        self.bindings.append((event: event, ref: ref, callback: callback))
        return ref
    }
    
    /// Unsubscribes from channel events.
    ///
    /// - parameter event: Event to unsubscribe from
    /// - paramter ref: Ref counter returned when subscribing. Can be omitted
    public func off(_ event: String, ref: Int? = nil) {
        self.bindings = bindings.filter({ !($0.event == event && (ref == nil || ref == $0.ref)) })
    }
    
    /// Push a payload to the Channel
    ///
    /// - parameter event: Event to push
    /// - parameter payload: Payload to push
    /// - parameter timeout: Optional timeout
    public func push(_ event: String, payload: Payload, timeout: Int = PHOENIX_DEFAULT_TIMEOUT) -> Push {
        guard joinedOnce else { fatalError("Tried to push \(event) to \(self.topic) before joining. Use channel.join() before pushing events") }
        
        let pushEvent = Push(channel: self, event: event, payload: payload, timeout: timeout)
        if canPush {
            pushEvent.send()
        } else {
            pushEvent.startTimeout()
            pushBuffer.append(pushEvent)
        }
        
        return pushEvent
    }
    
    /// Leavess the channel,
    ///
    /// Unsubscibres from server events and instructs Channel to terminate on server
    ///
    /// Triggers .onClose() hooks
    ///
    /// To receive leave acknowledgements, use the a receive hook to bind to the server ack.
    ///
    /// Example:
    ///     channel.leave().receive("ok") { _ in { print("left") }
    ///
    /// - parameter timeout: Optional timeout
    /// - return: Push that can add receive hooks
    @discardableResult
    public func leave(timeout: Int = PHOENIX_DEFAULT_TIMEOUT) -> Push {
        self.state = .leaving
        
        let onClose: ((Payload) -> Void) = { [weak self] (_) in
            self?.socket.logItems("channel", "leave \(self?.topic ?? "unknown")")
            self?.trigger(event: ChannelEvent.leave, with: [:], ref: "")
        }
        
        let leavePush = Push(channel: self, event: ChannelEvent.leave, timeout: timeout)
        leavePush
            .receive("ok", callback: onClose)
            .receive("timeout", callback: onClose)
        
        leavePush.send()
        if !canPush { leavePush.trigger("ok", payload: [:]) }
        return leavePush
    }
    
    /// Overridable message hook. Receives all events for specialized message
    /// handling before dispatching to the channel callbacks.
    ///
    /// - parameter event: The event the message was for
    /// - parameter payload: The payload for the message
    /// - parameter ref: The reference of the message
    /// - return: Must return the payload, modified or unmodified
    public func onMessage(_ callback: @escaping ((_ event: String, _ payload: Payload, _ ref: String) -> Payload)) {
        self.onMessage = callback
    }


    //----------------------------------------------------------------------
    // MARK: - Internal
    //----------------------------------------------------------------------

    /// Checks if an event received by the Socket belongs to this Channel
    func isMember(_ topic: String, event: String, payload: Payload, joinRef: String? = nil) -> Bool {
        guard topic == self.topic else { return false }
        
        let isLifecycleEvent = ChannelEvent.isLifecyleEvent(event)
        if let safeJoinRef = joinRef, isLifecycleEvent, safeJoinRef != self.joinRef {
            self.socket.logItems("channel", "dropping outdated message", topic, event, payload, safeJoinRef)
            return false
        }
        
        return true
    }
    
    var joinRef: String {
        return self.joinPush.ref ?? ""
    }
    
    func sendJoin(_ timeout: Int) {
        self.state = ChannelState.joining
        self.joinPush.resend(timeout)
    }
    
    func rejoin(_ timeout: Int? = nil) {
        self.sendJoin(timeout ?? self.timeout)
    }
    
    /// Triggers an event to the correct event bindings created by `channel.on("event")`.
    ///
    /// - parameter event: Event to trigger
    /// - parameter payload: Payload of the event
    /// - parameter ref: Ref of the event
    /// - parameter joinRef: Ref of the join event. Defaults to nil
    func trigger(event: String, with payload: Payload, ref: String, joinRef: String? = nil) {
        let handledPayload = self.onMessage(event, payload, ref)
        
        self.bindings
            .filter( { return $0.event == event } )
            .forEach( { $0.callback(handledPayload) } )
    }
    
    
    /// - parameter ref: The ref of the event push
    /// - return: The event name of the reply
    func replyEventName(_ ref: String) -> String {
        return "chan_reply_\(ref)"
    }
    
    /// - return: True if the Channel can push messages, meaning the socket
    ///           is connected and the channel is joined
    var canPush: Bool {
        return self.socket.isConnected && self.isJoined
    }
    
    /// - return: True if the Channel has been closed
    var isClosed: Bool {
        return state == .closed
    }
    
    /// - return: True if the Channel experienced an error
    var isErrored: Bool {
        return state == .errored
    }
    
    /// - return: True if the channel has joined
    var isJoined: Bool {
        return state == .joined
    }
    
    /// - return: True if the channel has requested to join
    var isJoining: Bool {
        return state == .joining
    }
    
    /// - return: True if the channel has requested to leave
    var isLeaving: Bool {
        return state == .leaving
    }
}
