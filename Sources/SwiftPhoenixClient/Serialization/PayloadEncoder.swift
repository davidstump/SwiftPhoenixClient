//
//  PayloadEncoder.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 10/19/24.
//  Copyright © 2024 SwiftPhoenixClient. All rights reserved.
//

import Foundation

///
/// Encodes an `Encodable` or a generic `Any` JsonObject payload into `Data`
///
public protocol PayloadEncoder: Sendable {
    
    /// Encodes an `Encodable` into `Data`
    ///
    /// - returns: The encoded `encodable` as `Data`
    /// - throws: Any error caused during encoding
    func encode(_ encodable: Encodable) throws -> Data
    
    /// Encodes a JSON `Any` into `Data`
    ///
    /// - returns: The encoded `Any` as `Data`
    /// - throws: Any error caused during encoding
    func encode(any jsonObject: Any) throws -> Data
    
}

///
/// A default implementtion of `PayloadEncoder` which works out of the box with a
/// standard Phoenix server.
///
public final class PhoenixPayloadEncoder: PayloadEncoder {
    
    /// The options for writing payloads as JSON data.
    public let options: JSONSerialization.WritingOptions
    
    /// `JSONEncoder` used to encode payloads.
    public let encoder: JSONEncoder

    /// Creates an instance using the specified `WritingOptions` and `JsonEncoder`.
    ///
    /// - Parameter encoder: The `JSONEncoder`. `JSONEncoder()` by default.
    /// - Parameter options: `JSONSerialization.WritingOptions` to use.
    public init(
        encoder: JSONEncoder = JSONEncoder(),
        options: JSONSerialization.WritingOptions = [.fragmentsAllowed]
    ) {
        self.encoder = encoder
        self.options = options
    }
    
    public func encode(_ encodable: any Encodable) throws -> Data {
        return try self.encoder.encode(encodable)
    }
    
    public func encode(any jsonObject: Any) throws -> Data {
        try JSONSerialization.data(withJSONObject: jsonObject, options: self.options)
    }
}
