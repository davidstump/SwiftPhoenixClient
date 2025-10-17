//
//  ChannelSubscription.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 1/27/25.
//  Copyright © 2025 SwiftPhoenixClient. All rights reserved.
//

import Foundation


protocol SubscriptionCallback {
    
    func trigger(_ decodedMessage: IncomingMessage,
                 payloadDecoder: PayloadDecoder,
                 payloadEncoder: PayloadEncoder)
}


extension SubscriptionCallback {
    
    func process<T>(parser: some PayloadParser<T>,
                 callback: (ChannelMessage<T>?, Swift.Error?) -> Void,
                 incomingMessage: IncomingMessage,
                 payloadDecoder: PayloadDecoder,
                 payloadEncoder: PayloadEncoder) {
        let result = parser.parse(incomingMessage,
                                  payloadDecoder: payloadDecoder,
                                  payloadEncoder: payloadEncoder)
    
        switch result {
        case .success(let payload):
            let channelMessage = ChannelMessage(from: incomingMessage, payload: payload)
            callback(channelMessage, nil)
        case .failure(let error):
            callback(nil, error)
        }
        
    }
    
    func process<T>(parser: some PayloadParser<T>,
                     continuation: CheckedContinuation<ChannelMessage<T>, Error>,
                     incomingMessage: IncomingMessage,
                     payloadDecoder: PayloadDecoder,
                     payloadEncoder: PayloadEncoder) {
        let result = parser.parse(incomingMessage,
                                  payloadDecoder: payloadDecoder,
                                  payloadEncoder: payloadEncoder)
    
        switch result {
        case .success(let payload):
            let channelMessage = ChannelMessage(from: incomingMessage, payload: payload)
            continuation.resume(returning: channelMessage)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
}

// MARK: - Callbacks
struct InternalSubscriptionCallback: SubscriptionCallback {
    let callback: (IncomingMessage) -> Void
    
    func trigger(_ incomingMessage: IncomingMessage,
                 payloadDecoder: PayloadDecoder,
                 payloadEncoder: PayloadEncoder) {
        callback(incomingMessage)
    }
}


struct DataSubscriptionCallback: SubscriptionCallback {
    
    let parser = DataPayloadParser()
    let callback: (ChannelMessage<Data>?, Swift.Error?) -> Void
    
    func trigger(_ incomingMessage: IncomingMessage,
                 payloadDecoder: PayloadDecoder,
                 payloadEncoder: PayloadEncoder) {
        process(parser: parser,
                callback: callback,
                incomingMessage: incomingMessage,
                payloadDecoder: payloadDecoder,
                payloadEncoder: payloadEncoder)
    }
}

struct JsonSubscriptionCallback: SubscriptionCallback {
    
    let parser = JsonPayloadParser()
    let callback: (ChannelMessage<Any>?, Error?) -> Void
    
    func trigger(_ incomingMessage: IncomingMessage,
                 payloadDecoder: PayloadDecoder,
                 payloadEncoder: PayloadEncoder) {
        process(parser: parser,
                callback: callback,
                incomingMessage: incomingMessage,
                payloadDecoder: payloadDecoder,
                payloadEncoder: payloadEncoder)
    }
}

struct DecodableSubscriptionCallback<T: Decodable>: SubscriptionCallback {
    
    let parser: DecodablePayloadParser<T>
    let callback: (ChannelMessage<T>?, Swift.Error?) -> Void
    
    init(
        type: T.Type,
        callback: @escaping (ChannelMessage<T>?, Swift.Error?) -> Void) {
            self.parser = DecodablePayloadParser(type: type)
            self.callback = callback
        }
    
    
    func trigger(_ incomingMessage: IncomingMessage,
                 payloadDecoder: PayloadDecoder,
                 payloadEncoder: PayloadEncoder) {
        process(parser: parser,
                callback: callback,
                incomingMessage: incomingMessage,
                payloadDecoder: payloadDecoder,
                payloadEncoder: payloadEncoder)
    }
}


// MARK: - Continuations
struct JsonContinuation: SubscriptionCallback {
    let parser = JsonPayloadParser()
    let continuation: CheckedContinuation<ChannelMessage<Any>, Error>
    
    func trigger(_ incomingMessage: IncomingMessage,
                 payloadDecoder: PayloadDecoder,
                 payloadEncoder: PayloadEncoder) {
        process(parser: parser,
                continuation: continuation,
                incomingMessage: incomingMessage,
                payloadDecoder: payloadDecoder,
                payloadEncoder: payloadEncoder)
    }
}

struct DataContinuation: SubscriptionCallback {
    let parser = DataPayloadParser()
    let continuation: CheckedContinuation<ChannelMessage<Data>, Error>
    
    func trigger(_ incomingMessage: IncomingMessage,
                 payloadDecoder: PayloadDecoder,
                 payloadEncoder: PayloadEncoder) {
        process(parser: parser,
                continuation: continuation,
                incomingMessage: incomingMessage,
                payloadDecoder: payloadDecoder,
                payloadEncoder: payloadEncoder)
    }
}

struct DecodableContinuation<T: Decodable>: SubscriptionCallback {
    
    let parser: DecodablePayloadParser<T>
    let continuation: CheckedContinuation<ChannelMessage<T>, Error>
    
    
    init(
        type: T.Type,
        continuation: CheckedContinuation<ChannelMessage<T>, Error>) {
            self.parser = DecodablePayloadParser(type: type)
            self.continuation = continuation
        }
    
    
    func trigger(_ incomingMessage: IncomingMessage,
                 payloadDecoder: PayloadDecoder,
                 payloadEncoder: PayloadEncoder) {
        process(parser: parser,
                continuation: continuation,
                incomingMessage: incomingMessage,
                payloadDecoder: payloadDecoder,
                payloadEncoder: payloadEncoder)
    }
    
}



public struct ChannelMessage<PayloadType> {
    
    /// The unique string ref when joining
    let joinRef: String?
    
    /// The unique string ref
    let ref: String?
    
    /// The string topic or topic:subtopic pair namespace, for example
    /// "messages", "messages:123"
    let topic: String
    
    /// The string event name, for example "phx_join"
    let event: String
    
    /// The reply status as a string
    public let status: String?
    
    /// The payload of the message to send or that was received
    public let payload: PayloadType
    
    init(from message: IncomingMessage, payload: PayloadType) {
        self.joinRef = message.joinRef
        self.ref = message.ref
        self.topic = message.topic
        self.event = message.event
        self.status = message.status
        self.payload = payload
    }
}

class ChannelSubscription {
    
    // The event to subscription is bound to
    let event: String
    
    // The subscriptions ref, used to cancel the subscription.
    let ref: Int
    
    let callback: SubscriptionCallback
    
    init(event: String, ref: Int, callback: SubscriptionCallback) {
        self.event = event
        self.ref = ref
        self.callback = callback
    }
    
    convenience init(event: String,
                     ref: Int,
                     callback: @escaping (ChannelMessage<Any>?, Swift.Error?) -> Void) {
        self.init(event: event,
                  ref: ref,
                  callback: JsonSubscriptionCallback(callback: callback))
    }
    
    convenience init(event: String,
                     ref: Int,
                     callback: @escaping (ChannelMessage<Data>?, Swift.Error?) -> Void) {
        self.init(event: event,
                  ref: ref,
                  callback: DataSubscriptionCallback(callback: callback))
    }
    
    convenience init<T: Decodable>(event: String,
                                   ref: Int,
                                   type: T.Type,
                                   callback: @escaping (ChannelMessage<T>?, Swift.Error?) -> Void) {
        self.init(event: event,
                  ref: ref,
                  callback: DecodableSubscriptionCallback(type: type, callback: callback))
    }
    
    convenience init(event: String,
                     ref: Int,
                     callback: @escaping (IncomingMessage) -> Void) {
        self.init(event: event,
                  ref: ref,
                  callback: InternalSubscriptionCallback(callback: callback))
    }

    func trigger(_ incomingMessage: IncomingMessage,
                 payloadDecoder: PayloadDecoder,
                 payloadEncoder: PayloadEncoder) {
            self.callback.trigger(incomingMessage,
                                         payloadDecoder: payloadDecoder,
                                         payloadEncoder: payloadEncoder)
    }
}


