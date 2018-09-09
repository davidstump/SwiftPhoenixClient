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
    public let topic: String
    
    /// The params sent when joining the channel
    var params: Payload

    /// The Socket that the channel belongs to
    weak var socket: Socket?

    
    
    /// Current state of the Channel
    var state: ChannelState
    
    /// Collection of event bindings
    var bindings: [(event: String, ref: Int, callback: (Message) -> Void)]
    
    /// Tracks event binding ref counters
    var bindingRef: Int
    
    /// Timout when attempting to join a Channel
    var timeout: Int
    
    /// Set to true once the channel calls .join()
    var joinedOnce: Bool
    
    /// Push to send when the channel calls .join()
    var joinPush: Push!
    
    /// Buffer of Pushes that will be sent once the Channel's socket connects
    var pushBuffer: [Push]
    
    /// Timer to attempt to rejoin
    var rejoinTimer: PhxTimer!
    


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
        self.joinPush = Push(channel: self,
                             event: ChannelEvent.join,
                             payload: self.params,
                             timeout: self.timeout)
        
        self.rejoinTimer = PhxTimer(callback: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.rejoinTimer?.scheduleTimeout()
            if strongSelf.socket?.isConnected == true { strongSelf.rejoin() }
        }, timerCalc: { [weak self] tryCount in
            self?.socket?.reconnectAfterMs(tryCount) ?? 10000
        })
        
        /// Perfom once the Channel is joined
        self.joinPush.receive("ok") { [weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.state = ChannelState.joined
            strongSelf.rejoinTimer?.reset()
            strongSelf.pushBuffer.forEach( { $0.send() })
            strongSelf.pushBuffer = [Push]()
        }
        
        /// Perfom when the Channel has been closed
        self.onClose { [weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.rejoinTimer?.reset()
            strongSelf.socket?.logItems("channel", "close \(strongSelf.topic)")
            strongSelf.state = ChannelState.closed
            strongSelf.socket?.remove(strongSelf)
        }
        
        /// Perfom when the Channel errors
        self.onError { [weak self] (_) in
            guard let strongSelf = self else { return }
            guard strongSelf.isLeaving || !strongSelf.isClosed else { return }
            strongSelf.socket?.logItems("channel", "error \(strongSelf.topic)")
            strongSelf.state = ChannelState.errored
            strongSelf.rejoinTimer?.scheduleTimeout()
        }
        
        self.joinPush.receive("timeout") { [weak self] (_) in
            guard let strongSelf = self else { return }
            guard !strongSelf.isJoining else { return }
            strongSelf.socket?.logItems("channel", "timeout \(strongSelf.topic) \(strongSelf.joinRef) after \(strongSelf.timeout)ms")
            
            let leavePush = Push(channel: strongSelf, event: ChannelEvent.leave, payload: [:], timeout: strongSelf.timeout)
            leavePush.send()
            
            strongSelf.state = ChannelState.errored
            strongSelf.joinPush.reset()
            strongSelf.rejoinTimer?.scheduleTimeout()
        }
        
        self.on(ChannelEvent.reply) { [weak self] (message) in
            guard let strongSelf = self else { return }
            let replyEventName = strongSelf.replyEventName(message.ref)
            let replyMessage = Message(ref: message.ref, topic: message.topic, event: replyEventName, payload: message.payload)
            strongSelf.trigger(replyMessage)
        }
    }

    deinit {
        rejoinTimer.reset()
    }
    
    /// Overridable message hook. Receives all events for specialized message
    /// handling before dispatching to the channel callbacks.
    ///
    /// - parameter msg: The Message received by the client from the server
    /// - return: Must return the message, modified or unmodified
    public var onMessage: (_ message: Message) -> Message = { (message) in
        return message
    }
    
    
    //----------------------------------------------------------------------
    // MARK: - Public
    //----------------------------------------------------------------------
    /// Joins the channel
    ///
    /// - parameter joinParams: Overrides the params given when creating the Channel.
    ///                         If not provided, then initial params will be used.
    /// - parameter timeout: Optional timeout override. If not provided, default is used
    /// - return: Push which can receive hooks can be applied to
    public func join(joinParams: Payload? = nil, timeout: Int? = nil) -> Push {
        guard !joinedOnce else { fatalError("Tried to join channel multiple times. 'join()' can only be called once per channel instance")}
        
        /// Allow the User to update the payload send when a channel joins
        if let updatedJoinParams = joinParams {
            self.joinPush.payload = updatedJoinParams
        }
        
        self.joinedOnce = true
        self.rejoin(timeout)
        return joinPush
    }
    
    
    /// Hook into channel close
    ///
    /// - parameter callback: Callback to be informed when channel closes
    /// - return: The ref counter of the subscription
    @discardableResult
    public func onClose(_ callback: @escaping ((_ msg: Message) -> Void)) -> Int {
        return self.on(ChannelEvent.close, callback: callback)
    }
    
    /// Hook into channel error
    ///
    /// - parameter callback: Callback to be informed when channel errors
    /// - return: The ref counter of the subscription
    @discardableResult
    public func onError(_ callback: @escaping ((_ msg: Message) -> Void)) -> Int {
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
    public func on(_ event: String, callback: @escaping ((Message) -> Void)) -> Int {
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
        
        let onClose: ((Message) -> Void) = { [weak self] (message) in
            self?.socket?.logItems("channel", "leave \(self?.topic ?? "unknown")")
            self?.trigger(message)
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
    public func onMessage(_ callback: @escaping (_ message: Message) -> Message) {
        self.onMessage = callback
    }


    //----------------------------------------------------------------------
    // MARK: - Internal
    //----------------------------------------------------------------------

    /// Checks if an event received by the Socket belongs to this Channel
    func isMember(_ message: Message) -> Bool {
        guard message.topic == self.topic else { return false }
        
        let isLifecycleEvent = ChannelEvent.isLifecyleEvent(message.event)
        if let safeJoinRef = message.joinRef, isLifecycleEvent, safeJoinRef != self.joinRef {
            self.socket?.logItems("channel", "dropping outdated message", message.topic, message.event, message.payload, safeJoinRef)
            return false
        }
        
        return true
    }
    
    /// Sends the payload to join the Channel
    func sendJoin(_ timeout: Int) {
        self.state = ChannelState.joining
        self.joinPush.resend(timeout)
    }
    
    /// Rejoins the channel
    func rejoin(_ timeout: Int? = nil) {
        self.sendJoin(timeout ?? self.timeout)
    }
    
    /// Triggers an event to the correct event bindings created by `channel.on("event")`.
    ///
    /// - parameter event: Event to trigger
    /// - parameter payload: Payload of the event
    /// - parameter ref: Ref of the event
    /// - parameter joinRef: Ref of the join event. Defaults to nil
    func trigger(_ message: Message) {
        let handledMessage = self.onMessage(message)
        
        self.bindings
            .filter( { return $0.event == message.event } )
            .forEach( { $0.callback(handledMessage) } )
    }
    
    
    /// - parameter ref: The ref of the event push
    /// - return: The event name of the reply
    func replyEventName(_ ref: String) -> String {
        return "chan_reply_\(ref)"
    }
    
    /// The Ref send during the join message.
    var joinRef: String {
        return self.joinPush.ref ?? ""
    }
    
    /// - return: True if the Channel can push messages, meaning the socket
    ///           is connected and the channel is joined
    var canPush: Bool {
        return self.socket?.isConnected == true && self.isJoined
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
