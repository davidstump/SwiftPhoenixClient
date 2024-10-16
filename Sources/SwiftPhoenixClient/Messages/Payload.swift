//
//  Payload.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 10/15/24.
//  Copyright © 2024 SwiftPhoenixClient. All rights reserved.
//

import Foundation

typealias EncodablePayload = Encodable & Sendable
typealias DictionaryPayload = [String: any Any & Sendable]


///
/// Provides a messages payload as either a string or as binary data.
///
public enum MessagePayload: Equatable {
    
    case binary(Data)
    case json(String)
    
    
    /// Force unwraps the enum as a binary. Throws if it was json
    func asBinary() -> Data {
        switch self {
        case .binary(let data):
            data
        default:
            preconditionFailure("Expected payload to be data. Was json")
        }
    }
    
    /// Force unwraps the enum as json. Throws if it was binary
    func asJson() -> String {
        switch self {
        case .json(let string):
            string
        default:
            preconditionFailure("Expected payload to be json. Was data")
        }
    }
    
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
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
