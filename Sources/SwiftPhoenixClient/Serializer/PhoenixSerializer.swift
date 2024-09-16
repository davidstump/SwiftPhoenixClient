//
//  PhoenixSerializer.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 2/23/24.
//  Copyright © 2024 SwiftPhoenixClient. All rights reserved.
//

///
/// The default implementation of [Serializer] for encoding and decoding messages. Matches the JS
/// client behavior. You can build your own if you'd like by implementing `Serializer` and passing
/// your custom Serializer to Socket


class PhoenixSerializer: Serializer {
    
    private let HEADER_LENGTH: Int = 1
    private let META_LENGTH: Int = 4
    
    private let KIND_PUSH: UInt8 = 0
    private let KIND_REPLY: UInt8 = 1
    private let KIND_BROADCAST: UInt8 = 2
    
    func encode(message: MessageV6) -> String {
        switch message.payload {
        case .json(let json):
            let jsonArray = [
                message.joinRef,
                message.ref,
                message.topic,
                message.event,
                json
            ]
            
            return convertToString(encodable: jsonArray)
        default:
            preconditionFailure("Expected message to have a json payload.")
        }
    }
    
    func binaryEncode(message: MessageV6) -> Data {
        switch message.payload {
        case .binary(let data):
            var byteArray: [UInt8] = []
            
            // Add the KIND, which is always a PUSH from the client to the server
            byteArray.append(KIND_PUSH)
            
            // Add the lengths of each piece of the message
            byteArray.append(UInt8(message.joinRef?.utf8.count ?? 0) )
            byteArray.append(UInt8(message.ref?.utf8.count ?? 0) )
            byteArray.append(UInt8(message.topic.utf8.count) )
            byteArray.append(UInt8(message.event.utf8.count) )
            
            
            // Add the message's meta fields + payload
            if let joinRef = message.joinRef {
                byteArray.append(contentsOf: joinRef.utf8.map { UInt8($0) })
            }
            
            if let ref = message.ref {
                byteArray.append(contentsOf: ref.utf8.map { UInt8($0) })
            }
            
            byteArray.append(contentsOf: message.topic.utf8.map { UInt8($0) })
            byteArray.append(contentsOf: message.event.utf8.map { UInt8($0) })
            byteArray.append(contentsOf: data)

            return Data(byteArray)
        default:
            preconditionFailure("Expected message to have a binary payload.")
        }
    }
    
    
    func decode(text: String) -> SocketMessage {
        guard 
            let jsonData = text.data(using: .utf8),
            let decodedMessage = try? JSONDecoder().decode(DecodedMessage.self, from: jsonData)
        else {
            preconditionFailure("Could not parse message. Expected array of size 5, got. \(text)")
        }
            
        let joinRef = decodedMessage.joinRef
        let ref = decodedMessage.ref
        let topic = decodedMessage.topic
        let event = decodedMessage.event
        let payload = decodedMessage.payload
        
        // For phx_reply events, parse the payload from {"response": payload, "status": "ok"}. 
        // Note that `payload` can be any primitive or another object
        if event == ChannelEvent.reply, case .object(let payloadMap) = payload  {
            guard 
                let response = payloadMap["response"],
                case .string(let status) = payloadMap["status"]
            else {
                preconditionFailure("Reply was missing valid response an status. \(text)")
            }
            
            let responseAsJsonString = convertToString(rawJsonValue: response)
            
            return .reply(
                Reply(
                    joinRef: joinRef,
                    ref: ref,
                    topic: topic,
                    status: status,
                    payload: .json(responseAsJsonString)
                )
            )
        } else if joinRef != nil || ref != nil {
            let payloadAsJsonString = convertToString(rawJsonValue: payload)
            
            return .message(
                MessageV6(
                    joinRef: joinRef,
                    ref: ref,
                    topic: topic,
                    event: event,
                    payload: .json(payloadAsJsonString)
                )
            )
        } else {
            let payloadAsJsonString = convertToString(encodable: payload)
            
            return .broadcast(
                Broadcast(
                    topic: topic,
                    event: event,
                    payload: .json(payloadAsJsonString)
                )
            )
        }
    }
    
    
    func binaryDecode(data: Data) -> SocketMessage {
        let binary = [UInt8](data)
        return switch binary[0] {
        case KIND_PUSH: decodePush(buffer: binary)
        case KIND_REPLY: decodeReply(buffer: binary)
        case KIND_BROADCAST: decodeBroadcast(buffer: binary)
        default: preconditionFailure("Expected binary data to include a KIND of push, reply, or broadcast. Got \(binary[0])")
        }
    }
    
    // MARK: - Private -
    private func decodePush(buffer: [UInt8]) -> SocketMessage {
        let joinRefSize = Int(buffer[1])
        let topicSize = Int(buffer[2])
        let eventSize = Int(buffer[3])
        var offset = HEADER_LENGTH + META_LENGTH - 1 // pushes have no ref
        
        let joinRef = String(bytes: buffer[offset ..< offset + joinRefSize], encoding: .utf8)
        offset += joinRefSize
        guard let topic = String(bytes: buffer[offset ..< offset + topicSize], encoding: .utf8) else {
            preconditionFailure("Got nil when decoding topic. Topic is required")
        }
        offset += topicSize
        guard let event = String(bytes: buffer[offset ..< offset + eventSize], encoding: .utf8) else {
            preconditionFailure("Got nil when decoding event. Event is required")
        }
        offset += eventSize
        let data = Data(buffer[offset ..< buffer.count])
        
        return SocketMessage.message(
            MessageV6(
                joinRef: joinRef,
                ref: nil,
                topic: topic,
                event: event,
                payload: .binary(data)
            )
        )
    }
    
    private func decodeReply(buffer: [UInt8]) -> SocketMessage {
        let joinRefSize = Int(buffer[1])
        let refSize = Int(buffer[2])
        let topicSize = Int(buffer[3])
        let eventSize = Int(buffer[4])
        var offset = HEADER_LENGTH + META_LENGTH
        
        let joinRef = String(bytes: buffer[offset ..< offset + joinRefSize], encoding: .utf8)
        offset += joinRefSize
        let ref = String(bytes: buffer[offset ..< offset + refSize], encoding: .utf8)
        offset += refSize
        guard let topic = String(bytes: buffer[offset ..< offset + topicSize], encoding: .utf8) else {
            preconditionFailure("Got nil when decoding topic. Topic is required")
        }
        offset += topicSize
        guard let event = String(bytes: buffer[offset ..< offset + eventSize], encoding: .utf8) else {
            preconditionFailure("Got nil when decoding event. Event is required")
        }
        offset += eventSize
        let data = Data(buffer[offset ..< buffer.count])
        
        // for binary messages, payload = {status: event, response: data}
        return SocketMessage.reply(
            Reply(
                joinRef: joinRef,
                ref: ref,
                topic: topic,
                status: event,
                payload: .binary(data)
            )
        )
    }
    
    private func decodeBroadcast(buffer: [UInt8]) -> SocketMessage {
        let topicSize = Int(buffer[1])
        let eventSize = Int(buffer[2])
        var offset = HEADER_LENGTH + 2
        
        guard let topic = String(bytes: buffer[offset ..< offset + topicSize], encoding: .utf8) else {
            preconditionFailure("Got nil when decoding topic. Topic is required")
        }
        offset += topicSize
        guard let event = String(bytes: buffer[offset ..< offset + eventSize], encoding: .utf8) else {
            preconditionFailure("Got nil when decoding event. Event is required")
        }
        offset += eventSize
        let data = Data(buffer[offset ..< buffer.count])
        
        return SocketMessage.broadcast(
            Broadcast(
                topic: topic,
                event: event,
                payload: .binary(data)
            )
        )
    }
    
    private func convertToString(rawJsonValue: RawJsonValue) -> String {
        switch rawJsonValue {
        case .string(let rawString): 
            return rawString
        default:
            return convertToString(encodable: rawJsonValue)
        }
    }
    
    private func convertToString(encodable: Encodable) -> String {
        guard
            let jsonData = try? JSONEncoder().encode(encodable),
            let jsonString = String(data: jsonData, encoding: .utf8)
        else {
            preconditionFailure("Expected json object to serialize to a String.")
        }
        
        return jsonString
//        try!
//        if json is String {
//            return json as! String
//        } else {
//            guard let jsonData = try? JSONSerialization
//                .data(withJSONObject: json,
//                      options: JSONSerialization.WritingOptions()),
//                  let jsonString = String(data: jsonData, encoding: .utf8) else {
//                preconditionFailure("Expected json object to serialize to a String.")
//            }
//            return jsonString
//        }
    }
}

