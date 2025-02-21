//
//  PhxError.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 10/28/24.
//  Copyright © 2024 SwiftPhoenixClient. All rights reserved.
//

import Foundation

public enum TransportSerializerError: LocalizedError {
    
    /// The string could not be converted to data
    case dataFromStringFailed(string: String)
    
    /// The string could not be creating from data
    case stringFromDataFailed(string: String)
    
    /// Attempted to decode a binary message but the KIND was unknown
    case invalidBinaryKind(string: String)
    
    /// The received message was intended as a reply but failed validation
    case invalidReplyStructure(string: String)
    
    /// Whle decoding, topic was missing
    case decodeMissingTopic
    
    /// Whle decoding, event was missing
    case decodeMissingEvent
    
    /// Binary payload was sent to text encode
    case binarySentAsText(OutgoingMessage)
    
    public var errorDescription: String? {
        switch self {
        case .dataFromStringFailed(string: let string):
            return string
        case .stringFromDataFailed(string: let string):
            return string
        case .invalidBinaryKind(string: let string):
            return string
        case .invalidReplyStructure(string: let string):
            return string
        case .decodeMissingTopic:
            return NSLocalizedString(
                "tried to decode a message that was missing a topic",
                comment: "Missing Topic")
        case .decodeMissingEvent:
            return NSLocalizedString(
                "tried to decode a message that was missing an event",
                comment: "Missing Event")
        case .binarySentAsText(let outgoingMessage):
            return NSLocalizedString(
                "attempts to send a binary message as a string. \(outgoingMessage.topic):\(outgoingMessage.event)",
                comment: "Binary Sent as String")
        }
    }
    
}
