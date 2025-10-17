//
//  Channel+OnData.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 3/29/25.
//  Copyright © 2025 SwiftPhoenixClient. All rights reserved.
//

import Foundation

extension Channel {
    
    /// Subscribes on channel events with a `Data` payload.
    ///
    /// Example:
    ///
    ///     channel.onData("event") { [weak self] (message) in
    ///         print(try! message.payload.get())
    ///         // "32 bytes"
    ///     }
    ///
    /// - parameter event: Event to receive
    /// - parameter callback: Called with the event's message
    /// - return: Ref counter of the subscription. See `channel.off(_:, ref:)`.
    @discardableResult
    public func onData(_ event: String,
                       callback: @escaping (ChannelMessage<Data>?, Error?) -> Void) -> Int {
        let ref = bindingRef
        self.bindingRef = ref + 1
        
        let subscription = ChannelSubscription(event: event, ref: ref, callback: callback)
        self.subscriptions.withValue { subscriptions in
            subscriptions.append(subscription)
        }
        
        return subscription.ref
    }
    
    /// Hook into when the Channel is closed.
    /// Same as `onData`, but for the `phx_error` event
    @discardableResult
    public func onCloseData(_ callback: @escaping (ChannelMessage<Data>?, Error?) -> Void) -> Int {
        return self.onData(ChannelEvent.close, callback: callback)
    }
    
    /// Hook into when the Channel receives an Error.
    /// Same as `onData`, but for the `phx_error` event
    @discardableResult
    public func onErrorData(_ callback: @escaping (ChannelMessage<Data>?, Error?) -> Void) -> Int {
        return self.onData(ChannelEvent.close, callback: callback)
    }
}
