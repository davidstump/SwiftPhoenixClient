//
//  RawJsonValue.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 9/13/24.
//  Copyright © 2024 SwiftPhoenixClient. All rights reserved.
//

///
/// Allows for parsing an unknown payload value and preserving number precision
/// when encoding the payload back to a JSON String
///
enum RawJsonValue {
    case boolean(Bool)
    case number(Double)
    case string(String)
    case array([RawJsonValue?])
    case object([String: RawJsonValue])
}

extension RawJsonValue: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let boolValue = try? container.decode(Bool.self) {
            self = .boolean(boolValue)
        } else if let numberValue = try? container.decode(Double.self) {
            self = .number(numberValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let arrayValue = try? container.decode([RawJsonValue?].self) {
            self = .array(arrayValue)
        } else {
            let objectValue = try container.decode([String: RawJsonValue].self)
            self = .object(objectValue)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .boolean(let boolValue):
            try container.encode(boolValue)
        case .number(let numberValue):
            try container.encode(numberValue)
        case .string(let stringValue):
            try container.encode(stringValue)
        case .array(let arrayValue):
            try container.encode(arrayValue)
        case .object(let objectValue):
            try container.encode(objectValue)
        }
    }
}
