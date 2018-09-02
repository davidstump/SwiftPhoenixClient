//
//  Response.swift
//  SwiftPhoenixClient
//
//  All the credit in the world to the Birdsong repo for a good swift
//  implementation of Presence. Please check out that repo/library for
//  a good Swift Channels alternative
//
//  Created by Simon Manning on 6/07/2016.
//

import Foundation

/// Represents a Message that has been received by the client from the Server. You should
/// never need to create this class, only ever consume it's values.
public class Message {
    
    /// The unique string ref. Empty if not present
    public let ref: String
    
    /// The ref sent during a join event. Empty if not present.
    /// Visible only to the library
    let joinRef: String?
    
    /// The string topic or topic:subtopic pair namespace, for example "messages", "messages:123"
    public let topic: String
    
    /// The string event name, for example "phx_join"
    public let event: String
    
    /// The message payload
    public var payload: Payload
    
    /// Convenience var to access the message's payload's status. Equivalent
    /// to checking message.payload["status"] yourself
    public var status: String? {
        return payload["status"] as? String
    }
    
    //----------------------------------------------------------------------
    // MARK: - Internal
    //----------------------------------------------------------------------
    init(ref: String = "",
         topic: String = "",
         event: String = "",
         payload: Payload = [:],
         joinRef: String? = nil) {
        self.ref = ref
        self.topic = topic
        self.event = event
        self.payload = payload
        self.joinRef = joinRef
    }
    
    
    init?(data: Data) {
        do {
            guard let jsonObject
                = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
                    as? Payload
                else { return nil }
            
            self.ref = jsonObject["ref"] as? String ?? ""
            self.joinRef = jsonObject["join_ref"] as? String
            
            if
                let topic = jsonObject["topic"] as? String,
                let event = jsonObject["event"] as? String,
                let payload = jsonObject["payload"] as? Payload {
                
                self.topic = topic
                self.event = event
                self.payload = payload
            } else {
                return nil
            }
        
        } catch {
            return nil
        }
    }
}
