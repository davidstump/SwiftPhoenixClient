//
//  Messages.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 2/23/24.
//  Copyright © 2024 SwiftPhoenixClient. All rights reserved.
//

import Foundation


enum PayloadV6: Equatable {
    case binary(Data)
    case json(String)
    
    
    func asBinary() -> Data {
        switch self {
        case .binary(let data):
            data
        default:
            preconditionFailure("Expected payload to be data. Was json")
        }
    }
    
    func asJson() -> String {
        switch self {
        case .json(let string):
            string
        default:
            preconditionFailure("Expected payload to be json. Was data")
        }
    }
    
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch lhs {
        case .binary(let lhsData):
            switch rhs {
            case .binary(let rhsData): return lhsData == rhsData
            default: return false
            }
        case .json(let lhsJson):
            switch rhs {
            case .json(let rhsJson):
                return lhsJson == rhsJson
            default: return false
            }
        }
    }
}


///
/// Defines a message dispatched over client to channels and vice-versa.
///
/// The serialized format to and from the server will be in the shape of
///
///     [join_ref,ref,topic,event,payload]
///
struct MessageV6 {
    
    /// The unique string ref when joining
    let joinRef: String?
    
    /// The unique string ref
    let ref: String?
    
    /// The string topic or topic:subtopic pair namespace, for example "messages", "messages:123"
    let topic: String
    
    /// The string event name, for example "phx_join"
    let event: String
    
    /// The message payload
    let payload: PayloadV6
}

///
/// Defines a reply sent from channels to client.
///
/// The serialized format to and from the server will be in the shape of
///
///     [join_ref,ref,topic,nil,%{"status": status, "response": payload}]
///
struct Reply {
    
    /// The unique string ref when joining
    let joinRef: String?
    
    /// The unique string ref
    let ref: String?
    
    /// The string topic or topic:subtopic pair namespace, for example "messages", "messages:123"
    let topic: String
    
    /// The reply status as a string
    let status: String
    
    /// The reply payload
    let payload: PayloadV6
}

///
/// Defines a message sent from pubsub to channels and vice-versa.
///
/// The serialized format to and from the server will be in the shape of
///
///     [nil,nil,topic,event,payload]
///
struct Broadcast {
    
    /// The string topic or topic:subtopic pair namespace, for example "messages", "messages:123"
    let topic: String
    
    /// The string event name, for example "phx_join"
    let event: String
    
    /// The reply payload
    let payload: PayloadV6
}


///
/// A single value which represents all possible messages from the socket
///
enum SocketMessage {
    case message(MessageV6)
    case reply(Reply)
    case broadcast(Broadcast)
}

