//
//  PhoenixSerializer.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 2/23/24.
//  Copyright © 2024 SwiftPhoenixClient. All rights reserved.
//

import Foundation

///
/// Decode text and binary messages received from the transport layer into `IncomingMessage` before
/// the message is passed to the rest of the Client. Encodes`OutgoingMessage` into text or binary
/// messages before being sent through a Websocket Transport to the Server.
///
public protocol TransportSerializer {
    
    /// Encodes `OutgoingMessage` into a `String` to be sent to a Phoenix server as raw text
    ///
    /// - parameter message: `OutgoingMessage` to be encoded.
    /// - returns: Raw text to send back to the server.
    /// - throws: If the `OutgoingMessage` could not be encoded to text.
    func encode(message: OutgoingMessage) throws -> String
    
    /// Encodes a `OutgoingMessage` into `Data` to be sent to a Phoenix server as binary data
    ///
    /// - parameter message `OutgoingMessage` to be encoded.
    /// - returns Binary data to send back to the server
    /// - throws: If the `OutgoingMessage` could not be encoded to binary data.
    func binaryEncode(message: OutgoingMessage) throws -> Data
    
    /// Decodes a raw `String` text from a Phoenix server into an `IncomingMessage`.
    ///
    /// - parameter text: The raw `String` text from a Phoenix server
    /// - returns: The `SocketMessage` decoded from the raw text
    /// - throws: If the text could not be decoded into an `IncomingMessage`
    func decode(text: String) throws -> IncomingMessage
    
    /// Decodes binary  `Data` from a Phoenix server into a `SocketMessage` structure
    ///
    /// - parameter data: The binary `Data` from a Phoenix server
    /// - returns The `IncomingMessage` decoded from the binary data.
    /// - throws: If the binary data could not be decoded into an `IncomingMessage`.
    func binaryDecode(data: Data) throws -> IncomingMessage
    
}

///
/// The default implementation of `TransportSerializer` for encoding and decoding messages. Matches
/// the JS client behavior. You can implement a custom `TransportSerializer` and pass set it on the
/// `Socket`.
///
public class PhoenixTransportSerializer: TransportSerializer {
    
    private let HEADER_LENGTH: Int = 1
    private let META_LENGTH: Int = 4
    
    private let KIND_PUSH: UInt8 = 0
    private let KIND_REPLY: UInt8 = 1
    private let KIND_BROADCAST: UInt8 = 2
    
    private let payloadEncoder: PayloadEncoder
    private let payloadDecoder: PayloadDecoder
    
    init(payloadEncoder: PayloadEncoder = PhoenixPayloadEncoder(),
         payloadDecoder: PayloadDecoder = PhoenixPayloadDecoder()) {
        self.payloadEncoder = payloadEncoder
        self.payloadDecoder = payloadDecoder
    }
    
    public func encode(message: OutgoingMessage) throws -> String {
        switch message.payload {
        case .binary(_): throw TransportSerializerError.binarySentAsText(message)
            
        case .encodable(let encodablePayload):
            let outgoingShape = OutgoingShape(message: message, payload: encodablePayload)
            let outgoingJsonData = try self.payloadEncoder.encode(outgoingShape)
            guard let outgoingText = String(data: outgoingJsonData, encoding: .utf8) else {
                throw TransportSerializerError.stringFromDataFailed(
                    string: "Expected json object to serialize to a String. \(outgoingShape)"
                )
            }
            return outgoingText
            
            
        case .json(let outgoingJsonPayload):
            let outgoingShape: [Any] = [
                message.joinRef as Any,
                message.ref as Any,
                message.topic,
                message.event,
                outgoingJsonPayload
            ]
            
            let outgoingJsonData = try self.payloadEncoder.encode(any: outgoingShape)
            guard let outgoingText = String(data: outgoingJsonData, encoding: .utf8) else {
                throw TransportSerializerError.stringFromDataFailed(
                    string: "Expected json object to serialize to a String. \(outgoingShape)"
                )
            }
            
            return outgoingText
        }
    }
    
    public func binaryEncode(message: OutgoingMessage) throws -> Data {
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
        
        switch message.payload {
        case .binary(let binaryPayload):
            byteArray.append(contentsOf: binaryPayload)
            
        case .encodable(let encodable):
            let binaryPayload = try self.payloadEncoder.encode(encodable)
            byteArray.append(contentsOf: binaryPayload)

        case .json(let json):
            let binaryPayload = try self.payloadEncoder.encode(any: json)
            byteArray.append(contentsOf: binaryPayload)
        }
        
        return Data(byteArray)
    }
    
    
    public func decode(text: String) throws -> IncomingMessage {
        guard let jsonData = text.data(using: .utf8) else {
            throw TransportSerializerError.dataFromStringFailed(string: text)
        }
        
        let partialMessage = try payloadDecoder.decode(PartialMessage.self, from: jsonData)
        

        let joinRef = partialMessage.joinRef
        let ref = partialMessage.ref
        let topic = partialMessage.topic
        let event = partialMessage.event
        
        // For phx_reply events, parse the payload from {"response": payload, "status": "ok"}.
        // Note that `payload` can be any primitive or another object
        if event == ChannelEvent.reply {
            guard
                let status = partialMessage.status
            else {
                throw TransportSerializerError.invalidReplyStructure(string: text)
            }
            
            return buildIncomingMessage(
                joinRef: joinRef,
                ref: ref,
                topic: topic,
                event: ChannelEvent.reply,
                status: status,
                payload: .deferred(jsonData),
                rawText: text
            )
        } else if joinRef != nil || ref != nil {
            return buildIncomingMessage(
                joinRef: joinRef,
                ref: ref,
                topic: topic,
                event: event,
                payload: .deferred(jsonData),
                rawText: text
            )
        } else {
            return buildIncomingMessage(
                topic: topic,
                event: event,
                payload: .deferred(jsonData),
                rawText: text
            )
        }
    }
    
    
    public func binaryDecode(data: Data) throws -> IncomingMessage {
        let binary = [UInt8](data)
        return switch binary[0] {
        case KIND_PUSH: try decodePush(buffer: binary, rawData: data)
        case KIND_REPLY: try decodeReply(buffer: binary, rawData: data)
        case KIND_BROADCAST: try decodeBroadcast(buffer: binary, rawData: data)
        default:
            throw TransportSerializerError.invalidBinaryKind(
                string: "Expected binary data to include a KIND of push, reply, or broadcast. Got \(binary[0])"
            )
        }
    }
    
    // MARK: - Private -
    private func decodePush(buffer: [UInt8], rawData: Data) throws -> IncomingMessage {
        let joinRefSize = Int(buffer[1])
        let topicSize = Int(buffer[2])
        let eventSize = Int(buffer[3])
        var offset = HEADER_LENGTH + META_LENGTH - 1 // pushes have no ref
        
        let joinRef = String(bytes: buffer[offset ..< offset + joinRefSize], encoding: .utf8)
        offset += joinRefSize
        guard let topic = String(bytes: buffer[offset ..< offset + topicSize], encoding: .utf8) else {
            throw TransportSerializerError.decodeMissingTopic
        }
        offset += topicSize
        guard let event = String(bytes: buffer[offset ..< offset + eventSize], encoding: .utf8) else {
            throw TransportSerializerError.decodeMissingEvent
        }
        offset += eventSize
        let data = Data(buffer[offset ..< buffer.count])
        
        return buildIncomingMessage(
            joinRef: joinRef,
            topic: topic,
            event: event,
            payload: .decided(data),
            rawBinary: rawData
        )
    }
    
    private func decodeReply(buffer: [UInt8], rawData: Data) throws -> IncomingMessage {
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
            throw TransportSerializerError.decodeMissingTopic
        }
        offset += topicSize
        guard let event = String(bytes: buffer[offset ..< offset + eventSize], encoding: .utf8) else {
            throw TransportSerializerError.decodeMissingEvent
        }
        offset += eventSize
        let data = Data(buffer[offset ..< buffer.count])
        
        // for binary messages, payload = {status: event, response: data}
        return buildIncomingMessage(
            joinRef: joinRef,
            ref: ref,
            topic: topic,
            event: ChannelEvent.reply,
            status: event,
            payload: .decided(data),
            rawBinary: rawData
        )
    }
    
    private func decodeBroadcast(buffer: [UInt8], rawData: Data) throws -> IncomingMessage {
        let topicSize = Int(buffer[1])
        let eventSize = Int(buffer[2])
        var offset = HEADER_LENGTH + 2
        
        guard let topic = String(bytes: buffer[offset ..< offset + topicSize], encoding: .utf8) else {
            throw TransportSerializerError.decodeMissingTopic
        }
        offset += topicSize
        guard let event = String(bytes: buffer[offset ..< offset + eventSize], encoding: .utf8) else {
            throw TransportSerializerError.decodeMissingEvent
        }
        offset += eventSize
        let data = Data(buffer[offset ..< buffer.count])
        
        return buildIncomingMessage(
            topic: topic,
            event: event,
            payload: .decided(data),
            rawBinary: rawData
        )
    }
    
    private func buildIncomingMessage(
        joinRef: String? = nil,
        ref: String? = nil,
        topic: String,
        event: String,
        status: String? = nil,
        payload: IncomingPayload,
        rawText: String? = nil,
        rawBinary: Data? = nil
    ) -> IncomingMessage {
        return IncomingMessage(
            joinRef: joinRef,
            ref: ref,
            topic: topic,
            event: event,
            status: status,
            payload: payload,
            rawText: rawText,
            rawBinary: rawBinary)
    }
    
}
