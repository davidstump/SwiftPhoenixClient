//
//  Channel+Callbacks.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 1/30/25.
//  Copyright © 2025 SwiftPhoenixClient. All rights reserved.
//

import Foundation

extension Channel {
    
    /// Subscribes on channel events with an `Any` payload.
    ///
    /// Example:
    ///
    ///     channel.on("event") { [weak self] (message) in
    ///         print(try! message.payload.get() as! [String: Any])
    ///         // ["foo": "bar"]
    ///     }
    ///
    /// - parameter event: Event to receive
    /// - parameter callback: Called with the event's message
    /// - return: Ref counter of the subscription. See `channel.off(_:, ref:)`.
    @discardableResult
    public func on(_ event: String,
                   callback: @escaping (ChannelMessage<Any>?, Error?) -> Void) -> Int {
        let ref = bindingRef
        self.bindingRef = ref + 1
        
        let subscription = ChannelSubscription(event: event, ref: ref, callback: callback)
        self.subscriptions.withValue { subscriptions in
            subscriptions.append(subscription)
        }
        
        return subscription.ref
    }
    
    public func awaitOn(_ event: String) -> AsyncStream<ChannelMessage<Any>> {
        let (stream, continuation) = AsyncStream<ChannelMessage<Any>>.makeStream()
        let ref = self.on(event) { message, error in
            guard let message else { return }
            continuation.yield(message)
        }
        
        continuation.onTermination = { _ in
            self.off(event, ref: ref)
        }
        
        return stream
    }
    
    /// Hook into when the Channel is closed.
    /// Same as `on`, but for the `phx_close` event
    @discardableResult
    public func onClose(_ callback: @escaping (ChannelMessage<Any>?, Error?) -> Void) -> Int {
        return self.on(ChannelEvent.close, callback: callback)
    }
    
    /// Hook into when the Channel receives an Error.
    /// Same as `on`, but for the `phx_error` event
    @discardableResult
    public func onError(_ callback: @escaping (ChannelMessage<Any>?, Error?) -> Void) -> Int {
        return self.on(ChannelEvent.error, callback: callback)
    }
}
