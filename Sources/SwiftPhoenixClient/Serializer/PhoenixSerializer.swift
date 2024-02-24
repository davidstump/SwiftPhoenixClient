//
//  PhoenixSerializer.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 2/23/24.
//  Copyright © 2024 SwiftPhoenixClient. All rights reserved.
//

import Foundation

///
/// The default implementation of [Serializer] for encoding and decoding messages. Matches the JS
/// client behavior. You can build your own if you'd like by implementing `Serializer` and passing
/// your custom Serializer to Socket
///
class PhoenixSerializer: Serializer {
    
    func decode(text: String) -> SocketMessage {
        
        guard
            let textData = text.data(using: .utf8),
            let textJson = try? JSONSerialization
                .jsonObject(with: textData,
                        options: JSONSerialization.ReadingOptions()),
            let jsonArray = textJson as? [Any?],
            jsonArray.count == 5
        else {
            preconditionFailure("Could not parse message. Expected array of size 5, got. \(text)")
        }
        
        let joinRef = jsonArray[0] as? String
        let ref = jsonArray[1] as? String
        let topic = jsonArray[2] as! String
        let event = jsonArray[3] as! String
        let payload = jsonArray[4]! // JsonObject
        
        // For phx_reply events, parse the payload from {"response": payload, "status": "ok"}. 
        // Note that `payload` can be any primitive or another object
        if event == ChannelEvent.reply {
            let payloadMap = payload as! [String: Any]
            let response = convertToString(json: payloadMap["response"]!)
            let status = payloadMap["status"] as! String

            return .reply(
                Reply(
                    joinRef: joinRef,
                    ref: ref,
                    topic: topic,
                    status: status,
                    payload: response
                )
            )
        } else if joinRef == nil && ref == nil {
            
            return .broadcast(
                Broadcast(
                    topic: topic,
                    event: event,
                    payload: convertToString(json: payload)
                )
            )
        } else {
            return .message(
                MessageV6(
                    joinRef: joinRef,
                    ref: ref,
                    topic: topic,
                    event: event,
                    payload: convertToString(json: payload)
                )
            )
        }
    }
    
    private func convertToString(json: Any) -> String {
        if json is [String: Any] {
            guard let jsonData = try? JSONSerialization
                .data(withJSONObject: json,
                      options: JSONSerialization.WritingOptions()),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                preconditionFailure("Expected json object to serialize to a String.")
            }
                
            return jsonString
        } else if json is String {
            return json as! String
        } else {
            preconditionFailure("Expected json to be a string or a dictionary. Got \(json)")
        }
    }
}

