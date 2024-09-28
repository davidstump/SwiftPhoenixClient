//
//  PayloadEncoder.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 9/18/24.
//  Copyright © 2024 SwiftPhoenixClient. All rights reserved.
//


/// A type that can encode any `Encodable` type into a `Payload`
public protocol PayloadEncoder {
    
    /// Encode the provided `Encodable` into a `Payload`
    ///
    /// - Parameters:
    ///    - payload:   The `Encodable` payload value to convert into a `String`
    ///
    /// - Returns:      A `String` that represents the payload
    /// - Throws:       An `Error` when encoding fails.
    func encode(_ payload: Encodable) throws -> PayloadV6
    
    /// Encode the provided `[String: Any]` into a `Payload` using `JSONSerialization`
    ///
    /// - Parameters:
    ///    - payload:   The `[String: Any]` payload value to convert into a `String`
    ///
    /// - Returns:      A `String` that represents the payload
    /// - Throws:       An `Error` when encoding fails.
    func encode(_ payload: [String: Any]) throws -> PayloadV6
    
}

/// A `PayloadEncoder` that encodes types as  JSON string body
open class JSONPayloadEncoder: PayloadEncoder {
    
    /// Returns an encoder with default parameters
    public static var `default`: JSONPayloadEncoder { JSONPayloadEncoder() }
    
    /// The `JSONEncoder` used to encode the payload
    public let encoder: JSONEncoder
    
    /// The `String.Encoding` used to convert the json data into a String
    public let encoding: String.Encoding
    
    /// The options for writing the parameters as JSON data.
    public let options: JSONSerialization.WritingOptions
    
    /// Creates an instance with the provided `JSONEncoder`
    ///
    /// - Parameters:
    ///    - encoder: The `JsonEncoder`. `JsonEncoder()` by default.
    ///    - encoding: The `String.Encoding` used. `.utf8` by default.
    public init(
        encoder: JSONEncoder = JSONEncoder(),
        encoding: String.Encoding = .utf8,
        options: JSONSerialization.WritingOptions = []
    ) {
        self.encoder = encoder
        self.encoding = encoding
        self.options = options
    }
    
    open func encode(_ payload: Encodable) throws -> PayloadV6  {
        let data = try encoder.encode(payload)
        let jsonString = String(data: data, encoding: self.encoding)!
        
        return .json(jsonString)
    }
    
    open func encode(_ payload: [String: Any]) throws -> PayloadV6 {
        let data = try JSONSerialization.data(withJSONObject: payload, options: self.options)
        let jsonString = String(data: data, encoding: self.encoding)!
        
        return .json(jsonString)
    }
    
}
