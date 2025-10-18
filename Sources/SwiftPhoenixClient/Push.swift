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


import Foundation

struct ReceiveHook {
    let status: String
    let callback: SubscriptionCallback
}


/// Represnts pushing data to a `Channel` through the `Socket`
public class Push {
    
    /// The channel sending the Push
    public weak var channel: Channel?
    
    /// The event, for example `phx_join`
    public let event: String
    
    /// The topic of the channel that is performing the Push
    public let topic: String
    
    /// The payload, for example ["user_id": "abc123"], expressed as Data
    public var payload: OutgoingPayload
    
    /// The push timeout. Default is 10.0 seconds
    public var timeout: TimeInterval
    
    /// The server's response to the Push
    var receivedMessage: IncomingMessage?
    
    /// Task which tracks timing out a Push
    var timeoutTask: Task<Void, Never>?
        
    /// Hooks into a Push. Where .receive("ok", callback(Payload)) are stored
    var receiveHooks: LockIsolated<[ReceiveHook]>
    
    /// The Callback wrapping the continuation of an await
    var awaitCallback: SubscriptionCallback?
    
    /// True if the Push has been sent
    var sent: Bool
    
    /// The reference ID of the Push
    var ref: String?
    
    /// The event that is associated with the reference ID of the Push
    var refEvent: String?
    
    var decoder: PayloadDecoder {
        return self.channel?.socket?.decoder ?? PhoenixPayloadDecoder()
    }
    
    var encoder: PayloadEncoder {
        return self.channel?.socket?.encoder ?? PhoenixPayloadEncoder()
    }
    
    /// Initializes a Push
    ///
    /// - parameter channel: The Channel
    /// - parameter event: The event, for example ChannelEvent.join
    /// - parameter payload: Optional. The Payload to send, e.g. ["user_id": "abc123"]
    /// - parameter timeout: Optional. The push timeout. Default is 10.0s
    init(channel: Channel,
         event: String,
         payload: OutgoingPayload,
         timeout: TimeInterval
    ) {
        self.channel = channel
        self.event = event
        self.topic = channel.topic
        self.payload = payload
        self.timeout = timeout
        self.receivedMessage = nil
        self.receiveHooks = LockIsolated([])
        self.awaitCallback = nil
        self.sent = false
        self.ref = nil
    }

    /// Resets and sends the Push
    /// - parameter timeout: Optional. The push timeout. Default is 10.0s
    public func resend(_ timeout: TimeInterval = Defaults.timeoutInterval) {
        self.timeout = timeout
        self.reset()
        self.send()
    }
    
    /// Sends the Push. If it has already timed out, then the call will
    /// be ignored and return early. Use `resend` in this case.
    public func send() {
        guard !hasReceived(status: "timeout") else { return }
        
        self.startTimeout()
        self.sent = true
        
        let message = OutgoingMessage(
            joinRef: self.channel?.joinRef,
            ref: self.ref,
            topic: self.topic,
            event: self.event,
            payload: self.payload
        )
        
        self.channel?.socket?.push(outgoing: message)
    }
    
    /// Receive a specific event when sending an Outbound message. Subscribing
    /// to status events with this method does not guarantees no retain cycles.
    /// 
    /// Example:
    ///
    ///     channel
    ///         .send(event:"custom", payload: ["body": "example"])
    ///         .receive("error") { [weak self] payload in
    ///             print("Error: ", payload)
    ///         }
    ///
    /// - parameter status: Status to receive
    /// - parameter callback: Callback to fire when the status is recevied
    @discardableResult
    public func receive(_ status: String,
                        callback: @escaping (ChannelMessage<Any>?, Error?) -> Void) -> Push {
        let subscriptionCallback = JsonSubscriptionCallback(callback: callback)
        return appendReceive(status, callback: subscriptionCallback)
    }
    
    @discardableResult
    public func receiveData(_ status: String,
                            callback: @escaping (ChannelMessage<Data>?, Error?) -> Void) -> Push {
        let subscriptionCallback = DataSubscriptionCallback(callback: callback)
        return appendReceive(status, callback: subscriptionCallback)
    }
    
    @discardableResult
    public func receiveDecodable<T: Codable>(_ status: String,
                                             of type: T.Type,
                                             callback: @escaping (ChannelMessage<T>?, Error?) -> Void) -> Push {
        let subscriptionCallback = DecodableSubscriptionCallback(type: type, callback: callback)
        return appendReceive(status, callback: subscriptionCallback)
    }
    
    @discardableResult
    internal func _receive(_ status: String,
                         callback: @escaping (IncomingMessage) -> Void) -> Push {
        let subscriptionCallback = InternalSubscriptionCallback(callback: callback)
        return appendReceive(status, callback: subscriptionCallback)
    }
    
    
    public func awaitReply() async throws -> ChannelMessage<Any> {
        return try await withCheckedThrowingContinuation { continuation in
            self.awaitCallback = JsonContinuation(continuation: continuation)
        }
    }
    
    
    public func awaitReplyData() async throws -> ChannelMessage<Data> {
        return try await withCheckedThrowingContinuation { continuation in
            self.awaitCallback = DataContinuation(continuation: continuation)
        }
        
    }
    
    public func awaitReply<T: Codable>(of type: T.Type) async throws -> ChannelMessage<T> {
        return try await withCheckedThrowingContinuation { continuation in
            self.awaitCallback = DecodableContinuation(type: type,
                                                       continuation: continuation)
        }
    }
    
    private func appendReceive(_ status: String, callback: SubscriptionCallback) -> Self {
        let hook = ReceiveHook(status: status, callback: callback)
        
        // If the message has already been received, pass it to the callback immediately
        if hasReceived(status: status), let receivedMessage = self.receivedMessage {
            hook.callback.trigger(receivedMessage,
                                  payloadDecoder: self.decoder,
                                  payloadEncoder: self.encoder)
        }
        
        self.receiveHooks.withValue { hooks in
            hooks.append(hook)
        }
        
        return self
    }
    
    /// Resets the Push as it was after it was first tnitialized.
    internal func reset() {
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
    private func matchReceive(_ status: String, message: IncomingMessage) {
        // Pass the event to any hooks that are registered
        self.receiveHooks.value.forEach { hook in
            if hook.status == status {
                hook.callback.trigger(message,
                                      payloadDecoder: self.decoder,
                                      payloadEncoder: self.encoder)
            }
        }
        
        // Invoke any continuation
        self.awaitCallback?.trigger(message,
                                    payloadDecoder: self.decoder,
                                    payloadEncoder: self.encoder)
    }
    
    /// Reverses the result on channel.on(ChannelEvent, callback) that spawned the Push
    private func cancelRefEvent() {
        guard let refEvent = self.refEvent else { return }
        self.channel?.off(refEvent)
    }
    
    /// Cancel any ongoing Timeout Timer
    internal func cancelTimeout() {
        self.timeoutTask?.cancel()
        self.timeoutTask = nil
    }
    
    /// Starts the Timer which will trigger a timeout after a specific _timeout_
    /// time, in milliseconds, is reached.
    internal func startTimeout() {
        // Cancel any existing timeout before starting a new one
        if let timeoutTask, !timeoutTask.isCancelled {
            self.cancelTimeout()
        }
        
        guard
            let channel = channel,
            let socket = channel.socket else { return }
        
        let ref = socket.makeRef()
        let refEvent = channel.replyEventName(ref)
        
        self.ref = ref
        self.refEvent = refEvent
        
        /// If a response is received  before the Timer triggers, cancel timer
        /// and match the recevied event to it's corresponding hook
        channel._on(refEvent) { [weak self] incomingMessage in
            guard let self else { return }
            
            self.cancelRefEvent()
            self.cancelTimeout()
            self.receivedMessage = incomingMessage
            
            /// Check if there is event a status available
            guard let status = incomingMessage.status else { return }
            self.matchReceive(status, message: incomingMessage)
        }

        
        /// Setup and start the Timeout timer.
        let task = Task {
            try? await _clock.sleep(for: timeout)
            guard !Task.isCancelled else { return }

            self.trigger("timeout", payload: [:])
        }
         
        self.timeoutTask = task

    }
    
    /// Checks if a status has already been received by the Push.
    ///
    /// - parameter status: Status to check
    /// - return: True if given status has been received by the Push.
    internal func hasReceived(status: String) -> Bool {
        return self.receivedMessage?.status == status
    }
    
    /// Triggers an event to be sent though the Channel
    internal func trigger(_ status: String, payload: Payload) {
        /// If there is no ref event, then there is nothing to trigger on the channel
        guard let refEvent = self.refEvent else { return }
        
        self.channel?.trigger(
            event: refEvent,
            payload: payload,
            status: status
        )
    }
}
