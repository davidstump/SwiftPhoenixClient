//
//  IntermediateDeserializedMessage.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 9/13/24.
//  Copyright © 2024 SwiftPhoenixClient. All rights reserved.
//

/// Represents a Message received from the Server that has been decoded from the format
///     "[join_ref, ref, topic, event, payload]"
/// into a decodable structure. Will then further be converted into a `MessageV6` before being
/// passed into the rest of the client
struct DecodedMessage: Decodable {
    let joinRef: String?
    let ref: String?
    let topic: String
    let event: String
    let payload: RawJsonValue
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        joinRef = try? container.decode(String?.self)
        ref = try? container.decode(String?.self)
        topic = try container.decode(String.self)
        event = try container.decode(String.self)
        payload = try container.decode(RawJsonValue.self)
    }
}
