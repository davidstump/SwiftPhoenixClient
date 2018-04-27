//
//  Outbound.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 2/10/18.
//

import Foundation

public class Push {
    
    /// The channel
    private let channel: Channel
    
    /// The event, for example ChannelEvent.join
    private let event: String
    
    /// The payload, for example ["user_id": "abc123"]
    private var payload: Payload
    
    /// The push timeout, in milliseconds
    private var timeout: Int
    
    /// The server's response to the Push
    private var receivedResponse: Payload?
    
    /// Timer which triggers a timeout event
    private var timeoutTimer: Timer?
    
    /// Hooks into a Push. Where .receive("ok", callback(Payload)) are stored
    private var receiveHooks: [String: [(Payload) -> ()]]
    
    /// True if the Push has been sent
    private var sent: Bool
    
    /// The reference ID of the Push
    private var ref: String?
    
    /// The event that is associated with the reference ID of the Push
    private var refEvent: String?
    
    
    
    
//    /// Topic to send in an outbound message
//    public let topic: String
//
//    /// Event to send in an outbound message
//    public let event: String
//
//    /// Paylopad to send in an outbound message
//    public let payload: Payload
//
//    /// Ref ID of an outbound message
//    let ref: String
//
//
//    /// Caches a status if received before handler was registered
//    fileprivate var receivedStatus: String?
//
//    /// Caches a payload if received before handler was registered
//    fileprivate var receivedResponse: Payload?
//
//
//    /// Custom handlers which will fire when an outbound message is sent to the server
//    /// such as "ok", "error", etc
//    fileprivate var handlers: [String: [(Payload) -> ()]] = [:]
//
//    /// Custom handlers which will always fire on any send event
//    fileprivate var alwaysHandlers: [() -> ()] = []
    
    
    
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
        self.receivedResponse = nil
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
    public func receive(_ status: String, callback: @escaping ((Payload) -> ())) -> Push {
        if hasReceived(status: status), let receivedResponse = self.receivedResponse {
            callback(receivedResponse)
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
        if hasReceived(status: "timeout") { return }
        self.sent = true
        
        /// TODO: Send the Push through the channel
        //self.channel.push(<#T##event: String##String#>, payload: <#T##Payload#>)
    }
    
    
    //----------------------------------------------------------------------
    // MARK: - Class Private
    //----------------------------------------------------------------------
    /// Resets the Push as it was after it was first tnitialized.
    private func reset() {
        self.cancelRefEvent()
        self.ref = nil
        self.refEvent = nil
        self.receivedResponse = nil
        self.sent = false
    }
    
    
    /// Finds the receiveHook which needs to be informed of a status response
    ///
    /// - parameter status: Status which was received, e.g. "ok", "error", "timeout"
    /// - parameter response: Response that was received
    private func matchReceive(_ status: String, response: Payload) {
        receiveHooks[status]?.forEach( { $0(response) } )
    }
    
    /// Reverses the result on channel.on(ChannelEvent, callback) that spawned the Push
    private func cancelRefEvent() {
        guard let refEvent = self.refEvent else { return }
        self.channel.off(refEvent)
    }
    
    /// Cancel any ongoing Timeout Timer
    private func cancelTimeout() {
        self.timeoutTimer?.invalidate()
        self.timeoutTimer = nil
    }
    
    /// Starts the Timer which will trigger a timeout after a specific _timeout_
    /// time, in milliseconds, is reached.
    private func startTimeout() {
        if let _ = self.timeoutTimer { self.cancelTimeout() }
        self.ref = "" //self.channel.socket.makeRef()
        let refEvent = ChannelEvent.close // self.channel.replayEventName(self.ref)
        self.refEvent = refEvent
        
        /// If a response is received  before the Timer triggers, cancel timer
        /// and match the recevied event to it's corresponding hook
        self.channel.on(refEvent) { (payload) in
            self.cancelRefEvent()
            self.cancelTimeout()
            self.receivedResponse = payload
            
            /// Check if there is event a status available
            guard let status = payload["status"] as? String else { return }
            self.matchReceive(status, response: payload)
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
    
    @objc func onTimerTriggered() {
        self.trigger("timeout", payload: [:])
    }
    
    /// Checks if a status has already been received by the Push.
    ///
    /// - parameter status: Status to check
    /// - return: True if given status has been received by the Push.
    private func hasReceived(status: String) -> Bool {
        guard
            let receivedResponse = self.receivedResponse,
            let receivedStatus = receivedResponse["status"] as? String,
            receivedStatus == status
            else { return false }
        
        return true
    }
    
    /// Triggers an event to be sent though the Channel
    private func trigger(_ status: String, payload: Payload) {
        /// If there is no ref event, then there is nothing to trigger on the channel
        guard let refEvent = self.refEvent else { return }
        
        var mutPayload = payload
        mutPayload["status"] = status
        self.channel.trigger(event: refEvent, with: mutPayload, ref: "")
    }

    
    
    
    
    

    
//    /// Initializes a new Outbound message to be sent through the Socket
//    ///
//    /// - parameter topic: Topic to send to
//    /// - parameter event: Event to send
//    /// - parameter payload: Payload to send
//    /// - parameter ref: Optional. Ref number to send. Use socket.makeRef to get a reference number
//    public init(topic: String, event: String, payload: Payload, ref: String) {
//        self.topic = topic
//        self.event = event
//        self.payload = payload
//        self.ref = ref
//    }
//
//
//    /// Converts the object to JSON data
//    ///
//    /// - throws: If object could not be serialized into JSON data
//    /// - return: JSON data representation of the object
//    public func toJson() throws -> Data {
//        let dict = [
//            "topic": topic,
//            "event": event,
//            "payload": payload,
//            "ref": ref,
//            ] as [String : Any]
//
//        return try JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions())
//    }
//
//    //----------------------------------------------------------------------
//    // MARK: - Handler Registration
//    //----------------------------------------------------------------------
//    /// Receive a specific event when sending an Outbound message
//    ///
//    /// Example:
//    ///     channel
//    ///         .send(event:"custom", payload: ["body": "example"])
//    ///         .receive("error") { payload in
//    ///             print("Error: ", payload)
//    ///         }
//    ///
//    @discardableResult
//    public func receive(_ status: String, handler: @escaping ((Payload) -> Void)) -> Push {
//        if receivedStatus == status,
//            let receivedResponse = receivedResponse {
//            handler(receivedResponse)
//        } else {
//            if (handlers[status] == nil) {
//                handlers[status] = [handler]
//            } else {
//                handlers[status]?.append(handler)
//            }
//        }
//
//        return self
//    }
//
//    /// Always receive a callback on any event
//    @discardableResult
//    public func always(_ handler: @escaping () -> ()) -> Push {
//        alwaysHandlers.append(handler)
//        return self
//    }
//
//
//    //----------------------------------------------------------------------
//    // MARK: - Response Handling
//    //----------------------------------------------------------------------
//    func handleResponse(_ response: Response) {
//        receivedStatus = response.payload["status"] as? String
//        receivedResponse = response.payload
//
//        fireCallbacksAndCleanup()
//    }
//
//    func handleParseError() {
//        receivedStatus = "error"
//        receivedResponse = ["reason": "Invalid payload request." as AnyObject]
//
//        fireCallbacksAndCleanup()
//    }
//
//    func handleNotConnected() {
//        receivedStatus = "error"
//        receivedResponse = ["reason": "Not connected to socket." as AnyObject]
//
//        fireCallbacksAndCleanup()
//    }
//
//    func fireCallbacksAndCleanup() {
//        defer {
//            handlers.removeAll()
//            alwaysHandlers.removeAll()
//        }
//
//        guard let status = receivedStatus else { return }
//        alwaysHandlers.forEach({$0()})
//
//        if let matchingCallbacks = handlers[status], let receivedResponse = receivedResponse {
//                matchingCallbacks.forEach({$0(receivedResponse)})
//        }
//    }
}
