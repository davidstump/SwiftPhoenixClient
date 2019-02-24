//
//  Defaults.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 2/24/19.
//

/// A collection of default values and behaviors used accross the Client
class Defaults {
    
    /// Default timeout when sending messages
    static let timeoutInterval: TimeInterval = 10.0
    
    /// Default interval to send heartbeats on
    static let heartbeatInterval: TimeInterval = 30.0
    
    /// Default reconnect function
    static let steppedBackOff: (Int) -> TimeInterval = { tries in
        return tries > 4 ? 10 : [1, 2, 5, 10][tries - 1]
    }
    
    /// Default encode function, utilizing JSONSerialization.data
    static let encode: ([String: Any]) -> Data = { json in
        return try! JSONSerialization
            .data(withJSONObject: json,
                  options: JSONSerialization.WritingOptions())
    }
    
    /// Default decode function, utilizing JSONSerialization.jsonObject
    static let decode: (Data) -> [String: Any]? = { data in
        guard
            let json = try? JSONSerialization
                .jsonObject(with: data,
                            options: JSONSerialization.ReadingOptions())
                as? [String: Any]
            else { return nil }
        return json
    }
}
