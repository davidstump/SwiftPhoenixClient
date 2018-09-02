
//
//  Outbound.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 2/10/18.
//

import Foundation

public class Push {
    
    /// The channel
    weak var channel: Channel?
    
    /// The event, for example ChannelEvent.join
    let event: String
    
    /// The payload, for example ["user_id": "abc123"]
    var payload: Payload
    
    /// The push timeout, in milliseconds
    var timeout: Int
    
    /// The server's response to the Push
    var receivedMessage: Message?
    
    /// Timer which triggers a timeout event
    var timeoutTimer: Timer?
    
    /// Hooks into a Push. Where .receive("ok", callback(Payload)) are stored
    var receiveHooks: [String: [(Message) -> ()]]
    
    /// True if the Push has been sent
    var sent: Bool
    
    /// The reference ID of the Push
    var ref: String?
    
    /// The event that is associated with the reference ID of the Push
    var refEvent: String?
    
    
    //----------------------------------------------------------------------
    // MARK: - Initializer
    //----------------------------------------------------------------------
    /// Initializes a Push
    ///
    /// - parameter channel: The Channel
    /// - parameter event: The event, for example ChannelEvent.join
    /// - parameter payload: Optional. The Payload to send, e.g. ["user_id": "abc123"]
    /// - parameter timeout: Optional. The push timeout in millisecionds. Defalt is 10000ms
    init(channel: Channel,
         event: String,
         payload: Payload = [:],
         timeout: Int = PHOENIX_DEFAULT_TIMEOUT) {
        self.channel = channel
        self.event = event
        self.payload = payload
        self.timeout = timeout
        self.receivedMessage = nil
        self.timeoutTimer = nil
        self.receiveHooks = [:]
        self.sent = false
        self.ref = nil
    }
    
    
    
    //----------------------------------------------------------------------
    // MARK: - Public
    //----------------------------------------------------------------------
    /// Resend a Push.
    ///
    /// - parameter timeout: Optional. The push timeout in millisecionds. Defalt is 10000ms
    public func resend(_ timeout: Int = PHOENIX_DEFAULT_TIMEOUT) {
        self.timeout = timeout
        self.reset()
        self.send()
    }
    
    /// Receive a specific event when sending an Outbound message
    ///
    /// Example:
    ///     channel
    ///         .send(event:"custom", payload: ["body": "example"])
    ///         .receive("error") { payload in
    ///             print("Error: ", payload)
    ///         }
    ///
    /// - parameter status: Status to receive
    /// - parameter callback: Callback to fire when the status is recevied
    @discardableResult
    public func receive(_ status: String, callback: @escaping ((Message) -> ())) -> Push {
        if hasReceived(status: status), let receivedMessage = self.receivedMessage {
            callback(receivedMessage)
        }
        
        /// Create a new array of hooks if no previous hook is associated with status
        if receiveHooks[status] == nil {
            receiveHooks[status] = [callback]
        } else {
        
            /// A previous hook for this status already exists. Just append the new hook
            receiveHooks[status]?.append(callback)
        }
        
        return self
    }
    
    
    /// Updates the payload to be sent on subsequent resends
    ///
    /// - parameter payload: Payload to update to
    public func updatePayload(_ payload: Payload) {
        self.payload = payload
    }
    
    
    //----------------------------------------------------------------------
    // MARK: - Library Private
    //----------------------------------------------------------------------
    func send() {
        guard let channel = channel else { return }
        if hasReceived(status: "timeout") { return }
        self.startTimeout()
        self.sent = true
        
        channel.socket?.push(
            topic: channel.topic,
            event: self.event,
            payload: self.payload,
            ref: self.ref,
            joinRef: channel.joinRef
        )
    }
    
    
    //----------------------------------------------------------------------
    // MARK: - Library Internal
    //----------------------------------------------------------------------
    /// Resets the Push as it was after it was first tnitialized.
    func reset() {
        self.cancelRefEvent()
        self.ref = nil
        self.refEvent = nil
        self.receivedMessage = nil
        self.sent = false
    }
    
    
    /// Finds the receiveHook which needs to be informed of a status response
    ///
    /// - parameter status: Status which was received, e.g. "ok", "error", "timeout"
    /// - parameter response: Response that was received
    func matchReceive(_ status: String, message: Message) {
        receiveHooks[status]?.forEach( { $0(message) } )
    }
    
    /// Reverses the result on channel.on(ChannelEvent, callback) that spawned the Push
    func cancelRefEvent() {
        guard let refEvent = self.refEvent else { return }
        self.channel?.off(refEvent)
    }
    
    /// Cancel any ongoing Timeout Timer
    func cancelTimeout() {
        self.timeoutTimer?.invalidate()
        self.timeoutTimer = nil
    }
    
    /// Starts the Timer which will trigger a timeout after a specific _timeout_
    /// time, in milliseconds, is reached.
    func startTimeout() {
        if let _ = self.timeoutTimer { self.cancelTimeout() }
        guard let channel = channel, let socket = channel.socket else { return }
        
        let ref = socket.makeRef()
        self.ref = ref
        let refEvent = channel.replyEventName(ref)
        self.refEvent = refEvent
        
        /// If a response is received  before the Timer triggers, cancel timer
        /// and match the recevied event to it's corresponding hook
        channel.on(refEvent) { [weak self] (message) in
            guard let strongSelf = self else { return }

            strongSelf.cancelRefEvent()
            strongSelf.cancelTimeout()
            strongSelf.receivedMessage = message
            
            /// Check if there is event a status available
            guard let status = message.status else { return }
            strongSelf.matchReceive(status, message: message)
        }
        
        /// Start the Timeout timer.
        let timeoutInSeconds = TimeInterval(timeout / 1000)
        if #available(iOS 10.0, *) {
            self.timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeoutInSeconds,
                                                     repeats: false) { (timer) in
                                                        self.trigger("timeout", payload: [:])
                                                     }
        } else {
            self.timeoutTimer = Timer.scheduledTimer(timeInterval: timeoutInSeconds,
                                                     target: self,
                                                     selector: #selector(onTimerTriggered),
                                                     userInfo: nil, repeats: false)
        }
    }
    
    /// Selector for iOS < 10
    @objc func onTimerTriggered() {
        self.trigger("timeout", payload: [:])
    }
    
    /// Checks if a status has already been received by the Push.
    ///
    /// - parameter status: Status to check
    /// - return: True if given status has been received by the Push.
    func hasReceived(status: String) -> Bool {
        guard
            let receivedStatus = self.receivedMessage?.status,
            receivedStatus == status
            else { return false }
        
        return true
    }
    
    /// Triggers an event to be sent though the Channel
    func trigger(_ status: String, payload: Payload) {
        /// If there is no ref event, then there is nothing to trigger on the channel
        guard let refEvent = self.refEvent else { return }
        
        var mutPayload = payload
        mutPayload["status"] = status
        
        let message = Message(ref: refEvent, payload: mutPayload)
        self.channel?.trigger(message)
    }
}
