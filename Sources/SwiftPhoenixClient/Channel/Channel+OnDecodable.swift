//
//  Channel+OnDecodable.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 3/29/25.
//  Copyright © 2025 SwiftPhoenixClient. All rights reserved.
//

import Foundation

extension Channel {
    
    /// Subscribes on channel events with a `Decodable` payload.
    ///
    /// Example:
    ///
    ///     struct Person {
    ///         let name: String
    ///     }
    ///
    ///     channel.onDecodable("event", type: Person.self) { [weak self] (message) in
    ///         print(try! message.payload.get())
    ///         // "Person(name: "Matt")"
    ///     }
    ///
    /// - parameter event: Event to receive
    /// - parameter type: Type to decode the payload to.
    /// - parameter callback: Called with the event's message
    /// - return: Ref counter of the subscription. See `channel.off(_:, ref:)`.
    @discardableResult
    public func onDecodable<T: Decodable>(_ event: String,
                                          of type: T.Type,
                                          callback: @escaping (ChannelMessage<T>?, Error?) -> Void) -> Int {
        let ref = bindingRef
        self.bindingRef = ref + 1
        
        let subscription = ChannelSubscription(event: event, ref: ref, type: type, callback: callback)
        self.subscriptions.withValue { subscriptions in
            subscriptions.append(subscription)
        }
        
        return subscription.ref
    }
    
    /// Hook into when the Channel is closed.
    /// Same as `onDecodable`, but for the `phx_close` event
    @discardableResult
    public func onCloseDecodable<T: Decodable>(_ type: T.Type,
                                               callback: @escaping (ChannelMessage<T>?, Error?) -> Void) -> Int {
        return self.onDecodable(ChannelEvent.close, of: type, callback: callback)
    }
    
    /// Hook into when the Channel receives an Error.
    /// Same as `onDecodable`, but for the `phx_error` event
    @discardableResult
    public func onErrorDecodable<T: Decodable>(_ type: T.Type,
                                               callback: @escaping (ChannelMessage<T>?, Error?) -> Void) -> Int {
        return self.onDecodable(ChannelEvent.close, of: type, callback: callback)
    }
}
