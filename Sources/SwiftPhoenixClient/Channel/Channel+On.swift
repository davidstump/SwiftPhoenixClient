//
//  Channel+Callbacks.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 1/30/25.
//  Copyright © 2025 SwiftPhoenixClient. All rights reserved.
//

import Foundation

// Collection of `on(event)` callbacks
extension Channel {
    
    // - - - - - Json - - - - -
    /// Subscribes on channel events.
    ///
    /// Subscription returns a ref counter, which can be used later to
    /// unsubscribe the exact event listener
    ///
    /// Example:
    ///
    ///     let channel = socket.channel("topic")
    ///     let ref1 = channel.on("event") { [weak self] (message) in
    ///         self?.print("do stuff")
    ///     }
    ///     let ref2 = channel.on("event") { [weak self] (message) in
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
    public func on(_ event: String, callback: @escaping (ChannelMessage<Any>) -> Void) -> Int {
        let ref = bindingRef
        self.bindingRef = ref + 1
        
        let subscription = ChannelSubscription(event: event, ref: ref, callback: callback)
        self.subscriptions.append(subscription)
        
        return subscription.ref
    }
    
    /// Hook into when the Channel is closed.
    ///
    /// Example:
    ///
    ///     let channel = socket.channel("topic")
    ///     channel.onClose() { [weak self] message in
    ///         self?.print("Channel \(message.topic) has closed"
    ///     }
    ///
    /// - parameter callback: Called when the Channel closes
    /// - return: Ref counter of the subscription. See `func off()`
    @discardableResult
    public func onClose(_ callback: @escaping (ChannelMessage<Any>) -> Void) -> Int {
        return self.on(ChannelEvent.close, callback: callback)
    }
    
    /// Hook into when the Channel receives an Error.
    ///
    /// Example:
    ///
    ///     let channel = socket.channel("topic")
    ///     channel.onError() { [weak self] (message) in
    ///         self?.print("Channel \(message.topic) has errored"
    ///     }
    ///
    /// - parameter callback: Called when the Channel closes
    /// - return: Ref counter of the subscription. See `func off()`
    @discardableResult
    public func onError(_ callback: @escaping (ChannelMessage<Any>) -> Void) -> Int {
        return self.on(ChannelEvent.error, callback: callback)
    }
    
    
    // - - - - - Data - - - - -
    @discardableResult
    public func onData(_ event: String,
                       callback: @escaping (ChannelMessage<Data>) -> Void) -> Int {
        let ref = bindingRef
        self.bindingRef = ref + 1
        
        let subscription = ChannelSubscription(event: event, ref: ref, callback: callback)
        self.subscriptions.append(subscription)
        
        return subscription.ref
    }
    
    @discardableResult
    public func onCloseData(_ callback: @escaping (ChannelMessage<Data>) -> Void) -> Int {
        return self.onData(ChannelEvent.close, callback: callback)
    }
    
    @discardableResult
    public func onErrorData(_ callback: @escaping (ChannelMessage<Data>) -> Void) -> Int {
        return self.onData(ChannelEvent.close, callback: callback)
    }
    
    
    // - - - - - Decodable - - - - -
    @discardableResult
    public func onDecodable<T: Decodable>(_ event: String,
                                          of type: T.Type,
                                          callback: @escaping (ChannelMessage<T>) -> Void) -> Int {
        let ref = bindingRef
        self.bindingRef = ref + 1
        
        let subscription = ChannelSubscription(event: event, ref: ref, type: type, callback: callback)
        self.subscriptions.append(subscription)
        
        return subscription.ref
    }
    
    @discardableResult
    public func onCloseDecodable<T: Decodable>(_ type: T.Type,
                                               callback: @escaping (ChannelMessage<T>) -> Void) -> Int {
        return self.onDecodable(ChannelEvent.close, of: type, callback: callback)
    }
    
    @discardableResult
    public func onErrorDecodable<T: Decodable>(_ type: T.Type,
                                               callback: @escaping (ChannelMessage<T>) -> Void) -> Int {
        return self.onDecodable(ChannelEvent.close, of: type, callback: callback)
    }
}
