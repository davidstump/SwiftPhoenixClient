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

/// Maps the data from a Websocket into a Response
public class Response {
    
    /// The unique string ref
    public let ref: String
    
    /// The string topic or topic:subtopic pair namespace, for example "messages", "messages:123"
    public let topic: String
    
    /// The string event name, for example "phx_join"
    public let event: String
    
    /// The message payload
    public let payload: Socket.Payload
    
    init?(data: Data) {
        do {
            guard let jsonObject
                = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
                    as? Socket.Payload
                else { return nil }
            
            self.ref = jsonObject["ref"] as? String ?? ""
            
            if
                let topic = jsonObject["topic"] as? String,
                let event = jsonObject["event"] as? String,
                let payload = jsonObject["payload"] as? Socket.Payload {
                
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
    
    
    public var description: String {
        return "ref:\"\(ref)\", event:\"\(event)\", topic:\"\(topic)\", payload:\(payload)"
    }
    
}
