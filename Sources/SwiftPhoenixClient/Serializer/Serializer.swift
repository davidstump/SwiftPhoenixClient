//
//  Serializer.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 2/23/24.
//  Copyright © 2024 SwiftPhoenixClient. All rights reserved.
//

import Foundation

///
/// Converts JSON received from the server into Messages and Messages into JSON to be sent to
/// the Server
///
public protocol Serializer {
    
    /// Encodes MessageV6 into a `String` to be sent back to a Phoenix server as raw text
    ///
    /// - parameter message: `MessageV6` with a json payload to encode
    /// - returns: Raw text to send back to the server
    func encode(message: MessageV6) -> String
    
    ///
    /// Encodes a `MessageV6` into `Data` to be sent back to a Phoenix server as binary data
    ///
    /// - parameter message `SocketMessage` with a binary payload to encode
    /// - returns Binary data to send back to the server
    ///
    func binaryEncode(message: MessageV6) -> Data
    
    /// Decodes a raw `String` from a Phoenix server into a `SocketMessage` structure
    /// Throws a `preconditionFailure` if passed a malformed message
    ///
    /// - parameter text: The raw `String` from a Phoenix server
    /// - returns: The `SocketMessage` created from the raw `String`
    /// - throws: `preconditionFailure` if the text could not be converted to a `SocketMessage`
    func decode(text: String) -> SocketMessage
    

    /// Decodes binary  `Data` from a Phoenix server into a `SocketMessage` structure
    ///
    /// - parameter data: The binary `Data` from a Phoenix server
    /// - returns The `SocketMessage` created from the raw `Data`
    /// - throws `preconditionFailure` if the data could not be converted to a `SocketMessage`
    func binaryDecode(data: Data) -> SocketMessage
    
    
}
