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

import Swift
import Foundation

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

import Foundation

public class Channel {
    
    /// The topic of the Channel. e.g. "rooms:friends"
    public let topic: String
    
    /// The params sent when joining the channel
    public var params: OutgoingPayload {
        didSet { self.joinPush.payload = params }
    }
    
    /// The Socket that the channel belongs to
    weak var socket: Socket?
    
    var decoder: PayloadDecoder {
        return self.socket?.decoder ?? PhoenixPayloadDecoder()
    }
    
    var encoder: PayloadEncoder {
        return self.socket?.encoder ?? PhoenixPayloadEncoder()
    }
    
    /// Current state of the Channel
    var state: ChannelState
    
    /// Collection of subscriptions on the Channel
    let subscriptions: LockIsolated<[ChannelSubscription]>
    
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
    var rejoinTimer: ScheduleTimer
    
    /// Refs of stateChange hooks
    var stateChangeRefs: [String]
    
    convenience init(
        topic: String,
        params: [String: Any] = [:],
        socket: Socket
    ) {
        self.init(topic: topic, params: .json(params), socket: socket)
    }
    
    /// Initialize a Channel
    ///
    /// - parameter topic: Topic of the Channel
    /// - parameter params: Optional. Parameters to send when joining.
    /// - parameter socket: Socket that the channel is a part of
    init(
        topic: String,
        params: OutgoingPayload,
        socket: Socket
    ) {
        self.state = ChannelState.closed
        self.topic = topic
        self.params = params
        self.socket = socket
        self.subscriptions = LockIsolated([])
        self.bindingRef = 0
        self.timeout = socket.timeout
        self.joinedOnce = false
        self.pushBuffer = []
        self.stateChangeRefs = []
        self.rejoinTimer = TimeoutTimer()
        
        // Setup Timer delgation
        self.rejoinTimer.callback = { [weak self] in
            guard let self else { return }
            
            if self.socket?.isConnected == true {
                self.rejoin()
            }
        }
        
        self.rejoinTimer.timerCalculation = { [weak self] tries in
            self?.socket?.rejoinAfter(tries) ?? 5.0
        }
        
        // Respond to socket events
        let onErrorRef = self.socket?.onError { [weak self] (_, _) in
            self?.rejoinTimer.reset()
        }
        
        if let ref = onErrorRef { self.stateChangeRefs.append(ref) }
        
        let onOpenRef = self.socket?.onOpen { [weak self] in
            guard let self else { return }

            self.rejoinTimer.reset()
            if (self.isErrored) { self.rejoin() }
        }
        
        if let ref = onOpenRef { self.stateChangeRefs.append(ref) }
        
        // Setup Push Event to be sent when joining
        self.joinPush = Push(channel: self,
                             event: ChannelEvent.join,
                             payload: params,
                             timeout: self.timeout)
        
        /// Handle when a response is received after join()
        self.joinPush.receive("ok") { [weak self] _ in
            guard let self else { return }

            // Mark the Channel as joined
            self.state = ChannelState.joined
            
            // Reset the timer, preventing it from attempting to join again
            self.rejoinTimer.reset()
            
            // Send and buffered messages and clear the buffer
            self.pushBuffer.forEach( { $0.send() })
            self.pushBuffer = []
        }
        
        // Perform if Channel errors while attempting to joi
        self.joinPush.receive("error") { [weak self] _ in
            guard let self else { return }

            self.state = .errored
            if (self.socket?.isConnected == true) { self.rejoinTimer.scheduleTimeout() }
        }
        
        // Handle when the join push times out when sending after join()
        self.joinPush.receive("timeout") { [weak self] _ in
            guard let self else { return }

            // log that the channel timed out
            self.socket?.logItems("channel", "timeout \(self.topic) \(self.joinRef ?? "") after \(self.timeout)s")
            
            
            // Send a Push to the server to leave the channel
            let leavePush = Push(channel: self,
                                 event: ChannelEvent.leave,
                                 payload: .json([:]),
                                 timeout: self.timeout)
            leavePush.send()
            
            // Mark the Channel as in an error and attempt to rejoin if socket is connected
            self.state = ChannelState.errored
            self.joinPush.reset()
            
            if (self.socket?.isConnected == true) { self.rejoinTimer.scheduleTimeout() }
        }
        
        /// Perfom when the Channel has been closed
        self.onClose { [weak self] _ in
            guard let self else { return }
            
            // Reset any timer that may be on-going
            self.rejoinTimer.reset()
            
            // Log that the channel was left
            self.socket?.logItems("channel", "close topic: \(self.topic) joinRef: \(self.joinRef ?? "nil")")
            
            // Mark the channel as closed and remove it from the socket
            self.state = ChannelState.closed
            self.socket?.remove(self)
        }
        
        /// Perfom when the Channel errors
        self.onError { [weak self] message in
            guard let self else { return }

            // Log that the channel received an error
            self.socket?.logItems("channel", "error topic: \(self.topic) joinRef: \(self.joinRef ?? "nil") mesage: \(message)")
            
            // If error was received while joining, then reset the Push
            if (self.isJoining) {
                // Make sure that the "phx_join" isn't buffered to send once the socket
                // reconnects. The channel will send a new join event when the socket connects.
                if let safeJoinRef = self.joinRef {
                    self.socket?.removeFromSendBuffer(ref: safeJoinRef)
                }
                
                // Reset the push to be used again later
                self.joinPush.reset()
            }
            
            // Mark the channel as errored and attempt to rejoin if socket is currently connected
            self.state = ChannelState.errored
            if (self.socket?.isConnected == true) { self.rejoinTimer.scheduleTimeout() }
        }
        
        // Perform when the join reply is received
        self._on(ChannelEvent.reply) { [weak self] message in
            guard let self else { return }
            
            // Trigger bindings
            guard let ref = message.ref else { return }
            var replyEventMessage = message
            replyEventMessage.event = self.replyEventName(ref)
            
            self.trigger(replyEventMessage)
            
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
    public var onMessage: (_ message: IncomingMessage) -> IncomingMessage = { message in
        return message
    }
    
    /// Joins the channel
    ///
    /// - parameter timeout: Optional. Defaults to Channel's timeout
    /// - return: Push event
    /// - throws: If the channel has already tried to join
    @discardableResult
    public func join(timeout: TimeInterval? = nil) throws -> Push {
        guard !joinedOnce else {
            throw ChannelError.alreadyJoined
        }
        
        // Join the Channel
        if let safeTimeout = timeout { self.timeout = safeTimeout }
        
        self.joinedOnce = true
        self.rejoin()
        return joinPush
    }

    
    @discardableResult
    internal func _on(_ event: String, callback: @escaping (IncomingMessage) -> Void) -> Int {
        let ref = bindingRef
        self.bindingRef = ref + 1
        
        let subscription = ChannelSubscription(event: event, ref: ref, callback: callback)
        self.subscriptions.withValue { subscriptions in
            subscriptions.append(subscription)
        }
        
        return subscription.ref
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
        self.subscriptions.withValue { subscriptions in
            subscriptions.removeAll { subscription in
                subscription.event == event && (ref == nil || ref == subscription.ref)
            }
        }
    }
    
    
    
    /// Push a payload to the Channel
    ///
    /// Example:
    ///
    ///     channel
    ///         .push("event", payload: ["message": "hello"])
    ///         .receive("ok") { _ in { print("message sent") }
    ///
    /// - parameter event: Event to push
    /// - parameter payload: Payload to push
    /// - parameter timeout: Optional timeout
    @discardableResult
    public func push(_ event: String,
                     payload: Payload,
                     timeout: TimeInterval = Defaults.timeoutInterval) throws -> Push {
        guard joinedOnce else {
            throw ChannelError.pushTriedBeforeJoin(topic: self.topic, event: event)
        }
        
        let pushEvent = Push(channel: self,
                             event: event,
                             payload: .json(payload),
                             timeout: timeout)
        if canPush {
            pushEvent.send()
        } else {
            pushEvent.startTimeout()
            pushBuffer.append(pushEvent)
        }
        
        return pushEvent
    }
    
    /// Pushes a binary payload to the Channel
    ///
    /// Example:
    ///
    ///     channel
    ///         .binaryPush("event", payload: Data())
    ///         .receive("ok") { _ in { print("message sent") }
    ///
    /// - parameter event: Event to push
    /// - parameter payload: Binary data to push
    /// - parameter timeout: Optional timeout
    public func binaryPush(_ event: String,
                           payload: Data,
                           timeout: TimeInterval = Defaults.timeoutInterval) throws -> Push {
        guard joinedOnce else {
            throw ChannelError.pushTriedBeforeJoin(topic: self.topic, event: event)
        }
        
        let pushEvent = Push(channel: self,
                             event: event,
                             payload: .binary(payload),
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
    public func leave(timeout: TimeInterval = Defaults.timeoutInterval) -> Push {
        // If attempting a rejoin during a leave, then reset, cancelling the rejoin
        self.rejoinTimer.reset()
        
        // Now set the state to leaving
        self.state = .leaving
        
        let closeHandler: (IncomingMessage) -> Void = { [weak self] message in
            guard let self else { return }
            
            self.socket?.logItems("channel", "leave \(self.topic)")
            
            // Triggers onClose() hooks
            self.trigger(event: ChannelEvent.close, payload: ["reason": "leave"])
        }
        
        // Push event to send to the server
        let leavePush = Push(channel: self,
                             event: ChannelEvent.leave,
                             payload: .json([:]),
                             timeout: timeout)
        
        // Perform the same behavior if successfully left the channel
        // or if sending the event timed out
        leavePush
            ._receive("ok", callback: closeHandler)
            ._receive("timeout", callback: closeHandler)
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
    public func onMessage(callback: @escaping (IncomingMessage) -> IncomingMessage) {
        self.onMessage = callback
    }
    
    
    //----------------------------------------------------------------------
    // MARK: - Internal
    //----------------------------------------------------------------------
    /// Checks if an event received by the Socket belongs to this Channel
    func isMember(_ message: IncomingMessage) -> Bool {
        // Return false if the message's topic does not match the Channel's topic
        guard message.topic == self.topic else { return false }
        
        guard
            let safeJoinRef = message.joinRef,
            safeJoinRef != self.joinRef,
            ChannelEvent.isLifecyleEvent(message.event)
        else { return true }
        
        self.socket?.logItems("channel", "dropping outdated message", message.topic, message.event, message.rawText ?? "n/a", safeJoinRef)
        return false
    }
    
    /// Sends the payload to join the Channel
    func sendJoin(_ timeout: TimeInterval) {
        self.state = ChannelState.joining
        self.joinPush.resend(timeout)
    }
    
    /// Rejoins the channel
    func rejoin(_ timeout: TimeInterval? = nil) {
        // Do not attempt to rejoin if the channel is in the process of leaving
        guard !self.isLeaving else { return }
        
        // Leave potentially duplicate channels
        self.socket?.leaveOpenTopic(topic: self.topic)
        
        // Send the joinPush
        self.sendJoin(timeout ?? self.timeout)
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
                 status: String? = nil) {
        // Trigger here is internal and pretty safe to force unwrap.
        let data = try! self.encoder.encode(any: payload)
        
        let message = IncomingMessage(
            joinRef: joinRef ?? self.joinRef,
            ref: nil,
            topic: self.topic,
            event: event,
            status: status,
            payload: .decided(data),
            rawText: String(data: data, encoding: .utf8),
            rawBinary: nil
        )
        
        self.trigger(message)
    }
    
    /// Triggers an event to the correct event bindings created by
    /// `channel.on("event")`.
    ///
    /// - parameter message: Message to pass to the event bindings
    func trigger(_ incomingMessage: IncomingMessage) {
        let handledMessage = self.onMessage(incomingMessage)
        
        self.subscriptions.value.forEach { subscription in
            if subscription.event == incomingMessage.event {
                subscription.trigger(handledMessage,
                                     payloadDecoder: self.decoder,
                                     payloadEncoder: self.encoder)
            }
        }
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
}


//----------------------------------------------------------------------
// MARK: - Public API
//----------------------------------------------------------------------
extension Channel {
    
    /// - return: True if the Channel has been closed
    public var isClosed: Bool {
        return state == .closed
    }
    
    /// - return: True if the Channel experienced an error
    public var isErrored: Bool {
        return state == .errored
    }
    
    /// - return: True if the channel has joined
    public var isJoined: Bool {
        return state == .joined
    }
    
    /// - return: True if the channel has requested to join
    public var isJoining: Bool {
        return state == .joining
    }
    
    /// - return: True if the channel has requested to leave
    public var isLeaving: Bool {
        return state == .leaving
    }
    
}
