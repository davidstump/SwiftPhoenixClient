//
//  PayloadDecoder.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 10/28/24.
//  Copyright © 2024 SwiftPhoenixClient. All rights reserved.
//

import Foundation

///
/// Decodes `Data` payloads into a `Decodable` or a generic `Any` JsonObject
///
public protocol PayloadDecoder: Sendable {
    
    /// Decodes `Data` into a JsonObject of type `Any`
    ///
    /// - returns: The decoded `Any` JsonObject
    /// - throws: Any error caused during decoding
    func decode(from data: Data) throws -> Any
    
    /// Decodes `Data` into a typed `Decodable`
    ///
    /// - returns: The decoded `T.Type`
    /// - throws: Any error caused during decoding
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable
    
}


///
/// A default implementtion of `PayloadDecoder` which works out of the box with a
/// standard Phoenix server.
///
public final class PhoenixPayloadDecoder: PayloadDecoder {
    
    /// The options for reading payloads as JSON data.
    public let options: JSONSerialization.ReadingOptions
    
    /// `JSONDecoder` used to decode payloads.
    public let decoder: JSONDecoder

    /// Creates an instance using the specified `WritingOptions` and `JsonEncoder`.
    ///
    /// - Parameter decoder: The `JSONDecoder`. `JSONDecoder()` by default.
    /// - Parameter options: `JSONSerialization.WritingOptions` to use.
    public init(
        decoder: JSONDecoder = JSONDecoder(),
        options: JSONSerialization.ReadingOptions = [.fragmentsAllowed]
    ) {
        self.decoder = decoder
        self.options = options
    }
    
    public func decode(from data: Data) throws -> Any {
        return try JSONSerialization.jsonObject(with: data, options: self.options)
    }
    
    public func decode<T>(_ type: T.Type,
                                   from data: Data) throws -> T where T : Decodable {
        return try self.decoder.decode(type, from: data)
    }
}
