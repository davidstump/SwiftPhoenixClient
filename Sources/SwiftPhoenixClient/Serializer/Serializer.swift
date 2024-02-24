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
protocol Serializer {
    
    /// Decodes a raw [String] from a Phoenix server into a [SocketMessage] structure
    /// Throws a `preconditionFailure` if passed a malformed message
    ///
    /// - parameter text: The raw `String` from a Phoenix server
    /// - returns: The `SocketMessage` created from the raw `String`
    /// - throws: `preconditionFailure` if the text could not be converted to a `SocketMessage`
    func decode(text: String) -> SocketMessage
    
    
}
