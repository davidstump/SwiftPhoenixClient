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
@testable import SwiftPhoenixClient

enum TestError: Error {
    case stub
}
//
//func toWebSocketText(data: [Any?]) -> String {
//  let encoded = Defaults.encode(data)
//  return String(decoding: encoded, as: UTF8.self)
//}

/// Transforms two Dictionaries into NSDictionaries so they can be conpared
func transform(_ lhs: [AnyHashable: Any],
               and rhs: [AnyHashable: Any]) -> (lhs: NSDictionary, rhs: NSDictionary) {
    return (NSDictionary(dictionary: lhs), NSDictionary(dictionary: rhs))
}

func buildIncomingMessage(
    joinRef: String? = nil,
    ref: String? = nil,
    topic: String = "t",
    event: String = "e",
    payload: IncomingPayload = .deferred(Data())
) -> IncomingMessage {
        return IncomingMessage(
            joinRef: joinRef,
            ref: ref,
            topic: topic,
            event: event,
            status: nil,
            payload: payload,
            rawText: nil,
            rawBinary: nil
        )
    }

func buildIncomingJsonMessage(
    joinRef: String? = nil,
    ref: String? = nil,
    topic: String = "t",
    event: String = "e",
    jsonPayload: [String: Any] = [:]
) -> IncomingMessage {
    let outgoingShape: [Any] = [
        joinRef as Any,
        ref as Any,
        topic,
        event,
        jsonPayload
    ]
    
    let payloadEncoder = PhoenixPayloadEncoder()
    let outgoingJsonData = try! payloadEncoder.encode(any: outgoingShape)
    return buildIncomingMessage(
        joinRef: joinRef,
        ref: ref,
        topic: topic,
        event: event,
        payload: .deferred(outgoingJsonData)
    )
}

func buildOutgoingMessage(
    joinRef: String? = nil,
    ref: String? = nil,
    topic: String,
    event: String,
    payload: OutgoingPayload
) -> OutgoingMessage {
    return OutgoingMessage(
        joinRef: joinRef,
        ref: ref,
        topic: topic,
        event: event,
        payload: payload
    )
}

func expectJson(_ payload: OutgoingPayload?, block: (Any) -> Void) {
    guard let payload else { fatalError("expected json payload") }
    if case .json(let value) = payload {
        block(value)
    } else {
        fatalError("expected json payload")
    }
}

struct TestData: Codable {
    let foo: Int
}

extension Channel {
    /// Utility method to easily filter the bindings for a channel by their event
    func getChannelSubscription(_ event: String) -> [ChannelSubscription] {
        var subscriptions = [ChannelSubscription]()
        self.subscriptions.forEach { subscription in
            guard subscription.event == event else { return }
            subscriptions.append(subscription)
        }
        
        return subscriptions
      }
}
