//
//  PhxError.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 10/28/24.
//  Copyright © 2024 SwiftPhoenixClient. All rights reserved.
//

import Foundation

public enum ChannelError: LocalizedError {
    case alreadyJoined
    
    public var errorDescription: String? {
        switch self {
        case .alreadyJoined:
            NSLocalizedString(
                "tried to join multiple times. 'join' can only be called a single time per channel instance",
                comment: "Already Joined")
        }
    }
    
    
}

public enum PhxError: Error {
    
    public enum SerializerReason {
        
        /// The string could not be converted to data
        case dataFromStringFailed(string: String)
        
        /// The string could not be creating from data
        case stringFromDataFailed(string: String)
        
        /// The received message was intended as a reply but failed validation
        case invalidReplyStructure(string: String)
        
        /// Attempted to decode a binary message but the KIND was unknown
        case invalidBinaryKind(string: String)
        
        /// The received message could not be parsed as a channels message (i.e. "[join_ref, ref, topic, event, payload]")
        case invalidStructure(string: String)
        
        /// Whle decoding, topic was missing
        case decodeMissingTopic
        
        /// Whle decoding, event was missing
        case decodeMissingEvent
        
        /// Binary payload was sent to text encode
        case binarySentAsText(OutgoingMessage)
    }
    
    case serializerError(reason: SerializerReason)
    
}
