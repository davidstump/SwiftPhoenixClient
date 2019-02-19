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
/// ### Example:
///
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
    var bindingsDel: [Binding]
    
    /// Tracks event binding ref counters
    var bindingRef: Int
    
    /// Timout when attempting to join a Channel
    var timeout: TimeInterval
    
    /// Set to true once the channel calls .join()
    var joinedOnce: Bool
    
    /// Push to send when the channel calls .join()
    var joinPush: Push!
    
    /// Buffer of Pushes that will be sent once the Channel's socket connects
    var pushBuffer: [Push]
    
    /// Timer to attempt to rejoin
    var rejoinTimer: TimeoutTimer
    


    //----------------------------------------------------------------------
    // MARK: - Initialization
    //----------------------------------------------------------------------
    /// Initialize a Channel
    ///
    /// - parameter topic: Topic of the Channel
    /// - parameter params: Optional. Parameters to send when joining.
    /// - parameter socket: Socket that the channel is a part of
    init(topic: String, params: [String: Any] = [:], socket: Socket) {
        self.state = ChannelState.closed
        self.topic = topic
        self.params = params
        self.socket = socket
        self.bindingsDel = []
        self.bindingRef = 0
        self.timeout = PHOENIX_DEFAULT_TIMEOUT_INTERVAL // socket.timeout
        self.joinedOnce = false
        self.pushBuffer = []
        self.rejoinTimer = TimeoutTimer()
    
        // Setup Timer delgation
        self.rejoinTimer.callback.delegate(to: self) { (_) in self.rejoinUntilConnected() }
        self.rejoinTimer.timerCalculation.delegate(to: self) { (_, tries) -> TimeInterval in
//            self.socket?.reconnectAfterMs(tries) ?? 10.0
            return tries > 2 ? 1 : [1, 5, 10][tries - 1]
        }
        
        
        self.joinPush = Push(channel: self,
                             event: ChannelEvent.join,
                             payload: self.params,
                             timeout: self.timeout)

        /// Handle when a response is received after join()
        self.joinPush.receive("ok", owner: self) { (self, _) in
            // Mark the Channel as joined
            self.state = ChannelState.joined
            
            // Reset the timer, preventing it from attempting to join again
            self.rejoinTimer.reset()
            
            // Send and buffered messages and clear the buffer
            self.pushBuffer.forEach( { $0.send() })
            self.pushBuffer = []
        }
        
        // Handle when the join push times out when sending after join()
        self.joinPush.receive("timeout", owner: self) { (self, _) in
            // Only handle a timeout if the Channel is in the 'joining' state
            guard self.isJoining else { return }
            
            // log that the channel timed out
            self.socket?.logItems("channel", "timeout \(self.topic) \(self.joinRef ?? "") after \(self.timeout)s")
            
            // Send a Push to the server to leave the channel
            let leavePush = Push(channel: self, event: ChannelEvent.leave, timeout: self.timeout)
            leavePush.send()
            
            // Mark the Channel as in an error and attempt to rejoin
            self.state = ChannelState.errored
            self.joinPush.reset()
            self.rejoinTimer.scheduleTimeout()
        }
        
        /// Perfom when the Channel has been closed
        self.onClose(self) { (self, _) in
            // Reset any timer that may be on-going
            self.rejoinTimer.reset()
            
            // Log that the channel was left
            self.socket?.logItems("channel", "close \(self.topic)")
            
            // Mark the channel as closed and remove it from the socket
            self.state = ChannelState.closed
            self.socket?.remove(self)
        }
        
        /// Perfom when the Channel errors
        self.onError(self) { (self, message) in
            // Do not emit error if the channel is in the process of leaving or already closed
            guard !self.isLeaving, !self.isClosed else { return }
            
            // Log that the channel received an error
            self.socket?.logItems("channel", "error topic: \(self.topic)  joinRef: \(self.joinRef ?? "nil") mesage: \(message)")
            
            // Mark the channel as errored and attempt to rejoin
            self.state = ChannelState.errored
            self.rejoinTimer.scheduleTimeout()
        }
        
        // Perform when the join reply is received
        self.on(ChannelEvent.reply, owner: self) { (self, message) in
            // Trigger bindings
            self.trigger(event: self.replyEventName(message.ref),
                         payload: message.payload,
                         ref: message.ref,
                         joinRef: message.joinRef)
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
    /// - parameter timeout: Optional. Defaults to Channel's timeout
    /// - return: Push event
    public func join(timeout: TimeInterval? = nil) -> Push {
        guard !joinedOnce else {
            fatalError("tried to join multiple times. 'join' "
                + "can only be called a single time per channel instance")
        }

        // Join the Channel
        self.joinedOnce = true
        self.rejoin(timeout)
        return joinPush
    }
    
    
    /// Hook into when the Channel is closed. Does not handles retain cycles.
    /// Use `onClose()` for automatic handling of retain cycles.
    ///
    /// Example:
    ///
    ///     let channel = socket.channel("topic")
    ///     channel.manualOnClose() { [weak self] message in
    ///         self?.print("Channel \(message.topic) has closed"
    ///     }
    ///
    /// - parameter callback: Called when the Channel closes
    /// - return: Ref counter of the subscription. See `func off()`
    @discardableResult
    public func manualOnClose(_ callback: @escaping ((Message) -> Void)) -> Int {
        return self.manualOn(ChannelEvent.close, callback: callback)
    }
    
    /// Hook into when the Channel is closed. Automatically handles retain
    /// cycles. Use `manualOnClose()` to handle yourself.
    ///
    /// Example:
    ///
    ///     let channel = socket.channel("topic")
    ///     channel.onClose(self) { (self, message) in
    ///         self.print("Channel \(message.topic) has closed"
    ///     }
    ///
    /// - parameter owner: Class containing the callback. Usually `self`
    /// - parameter callback: Called when the Channel closes
    /// - return: Ref counter of the subscription. See `func off()`
    @discardableResult
    public func onClose<Target: AnyObject>(_ owner: Target,
                                           callback: @escaping ((Target, Message) -> Void)) -> Int {
        return self.on(ChannelEvent.close, owner: owner, callback: callback)
    }
    
    /// Hook into when the Channel receives an Error. Does not handles retain
    /// cycles. Use `onError()` for automatic handling of retain cycles.
    ///
    /// Example:
    ///
    ///     let channel = socket.channel("topic")
    ///     channel.manualOnError() { [weak self] (message) in
    ///         self?.print("Channel \(message.topic) has errored"
    ///     }
    ///
    /// - parameter callback: Called when the Channel closes
    /// - return: Ref counter of the subscription. See `func off()`
    @discardableResult
    public func manualOnError(_ callback: @escaping ((_ message: Message) -> Void)) -> Int {
        return self.manualOn(ChannelEvent.error, callback: callback)
    }
    
    /// Hook into when the Channel receives an Error. Automatically handles
    /// retain cycles. Use `manualOnError()` to handle yourself.
    ///
    /// Example:
    ///
    ///     let channel = socket.channel("topic")
    ///     channel.onError(self) { (self, message) in
    ///         self.print("Channel \(message.topic) has closed"
    ///     }
    ///
    /// - parameter owner: Class containing the callback. Usually `self`
    /// - parameter callback: Called when the Channel closes
    /// - return: Ref counter of the subscription. See `func off()`
    @discardableResult
    public func onError<Target: AnyObject>(_ owner: Target,
                                           callback: @escaping ((Target, Message) -> Void)) -> Int {
        return self.on(ChannelEvent.error, owner: owner, callback: callback)
    }
    
    /// Subscribes on channel events. Does not handle retain cycles. Use `on()`
    /// for automatic handling of retain cycles.
    ///
    /// Subscription returns a ref counter, which can be used later to
    /// unsubscribe the exact event listener
    ///
    /// Example:
    /// 
    ///     let channel = socket.channel("topic")
    ///     let ref1 = channel.manualOn("event") { [weak self] (message) in
    ///         self?.print("do stuff")
    ///     }
    ///     let ref2 = channel.manualOn("event") { [weak self] (message) in
    ///         self?.print("do other stuff")
    ///     }
    ///     channel.off("event", ref1)
    ///
    /// Since unsubscription of ref1, "do stuff" won't print, but "do other
    /// stuff" will keep on printing on the "event"
    ///
    /// - parameter event: Event to receive
    /// - parameter callback: Called with the event's message
    /// - return: Ref counter of the subscription. See `func off()`
    @discardableResult
    public func manualOn(_ event: String, callback: @escaping ((Message) -> Void)) -> Int {
        var delegated = Delegated<Message, Void>()
        delegated.manuallyDelegate(with: callback)
        
        return self.on(event, delegated: delegated)
    }
    
    
    /// Subscribes on channel events. Automatically handles retain cycles. Use
    /// `manualOn()` to handle yourself.
    ///
    /// Subscription returns a ref counter, which can be used later to
    /// unsubscribe the exact event listener
    ///
    /// Example:
    ///
    ///     let channel = socket.channel("topic")
    ///     let ref1 = channel.on("event", owner: self) { (message) in
    ///         self?.print("do stuff")
    ///     }
    ///     let ref2 = channel.on("event", owner: self) { (message) in
    ///         self?.print("do other stuff")
    ///     }
    ///     channel.off("event", ref1)
    ///
    /// Since unsubscription of ref1, "do stuff" won't print, but "do other
    /// stuff" will keep on printing on the "event"
    ///
    /// - parameter event: Event to receive
    /// - parameter owner: Class containing the callback. Usually `self`
    /// - parameter callback: Called with the event's message
    /// - return: Ref counter of the subscription. See `func off()`
    @discardableResult
    public func on<Target: AnyObject>(_ event: String,
                                      owner: Target,
                                      callback: @escaping ((Target, Message) -> Void)) -> Int {
        var delegated = Delegated<Message, Void>()
        delegated.delegate(to: owner, with: callback)
        
        return self.on(event, delegated: delegated)
    }
    
    /// Shared method between `on` and `manualOn`
    @discardableResult
    private func on(_ event: String, delegated: Delegated<Message, Void>) -> Int {
        let ref = bindingRef
        self.bindingRef = ref + 1
        
        self.bindingsDel.append(Binding(event, ref, delegated))
        return ref
    }
    
    /// Unsubscribes from a channel event. If a `ref` is given, only the exact
    /// listener will be removed. Else all listeners for the `event` will be
    /// removed.
    ///
    /// Example:
    ///
    ///     let channel = socket.channel("topic")
    ///     let ref1 = channel.on("event") { _ in print("ref1 event" }
    ///     let ref2 = channel.on("event") { _ in print("ref2 event" }
    ///     let ref3 = channel.on("other_event") { _ in print("ref3 other" }
    ///     let ref4 = channel.on("other_event") { _ in print("ref4 other" }
    ///     channel.off("event", ref1)
    ///     channel.off("other_event")
    ///
    /// After this, only "ref2 event" will be printed if the channel receives
    /// "event" and nothing is printed if the channel receives "other_event".
    ///
    /// - parameter event: Event to unsubscribe from
    /// - paramter ref: Ref counter returned when subscribing. Can be omitted
    public func off(_ event: String, ref: Int? = nil) {
        self.bindingsDel.removeAll { (bind) -> Bool in
            !(bind.event == event && (ref == nil || ref == bind.ref))
        }
    }
    
    /// Push a payload to the Channel
    ///
    /// - parameter event: Event to push
    /// - parameter payload: Payload to push
    /// - parameter timeout: Optional timeout
    public func push(_ event: String,
                     payload: Payload,
                     timeout: TimeInterval = PHOENIX_DEFAULT_TIMEOUT_INTERVAL) -> Push {
        guard joinedOnce else { fatalError("Tried to push \(event) to \(self.topic) before joining. Use channel.join() before pushing events") }
        
        let pushEvent = Push(channel: self,
                             event: event,
                             payload: payload,
                             timeout: timeout)
        if canPush {
            pushEvent.send()
        } else {
            pushEvent.startTimeout()
            pushBuffer.append(pushEvent)
        }
        
        return pushEvent
    }
    
    /// Leaves the channel
    ///
    /// Unsubscribes from server events, and instructs channel to terminate on
    /// server
    ///
    /// Triggers onClose() hooks
    ///
    /// To receive leave acknowledgements, use the a `receive`
    /// hook to bind to the server ack, ie:
    ///
    /// Example:
    ////
    ///     channel.leave().receive("ok") { _ in { print("left") }
    ///
    /// - parameter timeout: Optional timeout
    /// - return: Push that can add receive hooks
    @discardableResult
    public func leave(timeout: TimeInterval = PHOENIX_DEFAULT_TIMEOUT_INTERVAL) -> Push {
        self.state = .leaving
        
        /// Delegated callback for a successful or a failed channel leave
        var onCloseDelegate = Delegated<Message, Void>()
        onCloseDelegate.delegate(to: self) { (self, message) in
            self.socket?.logItems("channel", "leave \(self.topic)")
            
            // Triggers onClose() hooks
            self.trigger(event: ChannelEvent.leave)
        }
        
        // Push event to send to the server
        let leavePush = Push(channel: self,
                             event: ChannelEvent.leave,
                             timeout: timeout)
        
        // Perform the same behavior if successfully left the channel
        // or if sending the event timed out
        leavePush
            .receive("ok", delegated: onCloseDelegate)
            .receive("timeout", delegated: onCloseDelegate)
        leavePush.send()
        
        // If the Channel cannot send push events, trigger a success locally
        if !canPush { leavePush.trigger("ok", payload: [:]) }
        
        // Return the push so it can be bound to
        return leavePush
    }
    
    /// Overridable message hook. Receives all events for specialized message
    /// handling before dispatching to the channel callbacks.
    ///
    /// - parameter event: The event the message was for
    /// - parameter payload: The payload for the message
    /// - parameter ref: The reference of the message
    /// - return: Must return the payload, modified or unmodified
    public func onMessage(callback: @escaping (Message) -> Message) {
        self.onMessage = callback
    }


    //----------------------------------------------------------------------
    // MARK: - Internal
    //----------------------------------------------------------------------
    /// Will continually attempt to rejoin the Channel on a timer.
    private func rejoinUntilConnected() {
        self.rejoinTimer.scheduleTimeout()
        if self.socket?.isConnected == true {
            self.rejoin()
        }
    }
    
    /// Checks if an event received by the Socket belongs to this Channel
    func isMember(_ message: Message) -> Bool {
        guard message.topic == self.topic else { return false }
        
        guard
            let safeJoinRef = message.joinRef,
            safeJoinRef != self.joinRef,
            ChannelEvent.isLifecyleEvent(message.event)
            else { return true }
        
        self.socket?.logItems("channel", "dropping outdated message", message.topic, message.event, message.payload, safeJoinRef)
        return false
    }
    
    /// Sends the payload to join the Channel
    func sendJoin(_ timeout: TimeInterval) {
        self.state = ChannelState.joining
        self.joinPush.resend(timeout)
    }
    
    /// Rejoins the channel
    func rejoin(_ timeout: TimeInterval? = nil) {
        self.sendJoin(timeout ?? self.timeout)
    }
    
    /// Triggers an event to the correct event bindings created by
    /// `channel.on("event")`.
    ///
    /// - parameter message: Message to pass to the event bindings
    func trigger(_ message: Message) {
        let handledMessage = self.onMessage(message)
        
        self.bindingsDel
            .filter( { return $0.event == message.event } )
            .forEach( { $0.callback.call(handledMessage) } )
    }
    
    /// Triggers an event to the correct event bindings created by
    //// `channel.on("event")`.
    ///
    /// - parameter event: Event to trigger
    /// - parameter payload: Payload of the event
    /// - parameter ref: Ref of the event. Defaults to empty
    /// - parameter joinRef: Ref of the join event. Defaults to nil
    func trigger(event: String,
                 payload: Payload = [:],
                 ref: String = "",
                 joinRef: String? = nil) {
        let message = Message(ref: ref,
                              topic: self.topic,
                              event: event,
                              payload: payload,
                              joinRef: joinRef ?? self.joinRef)
        self.trigger(message)
    }
    
    /// - parameter ref: The ref of the event push
    /// - return: The event name of the reply
    func replyEventName(_ ref: String) -> String {
        return "chan_reply_\(ref)"
    }
    
    /// The Ref send during the join message.
    var joinRef: String? {
        return self.joinPush.ref
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
