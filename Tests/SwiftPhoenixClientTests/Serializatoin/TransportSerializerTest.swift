//
//  PhoenixSerializerTest.swift
//  SwiftPhoenixClientTests
//
//  Created by Daniel Rees on 2/23/24.
//  Copyright © 2024 SwiftPhoenixClient. All rights reserved.
//

import Testing
import XCTest
@testable import SwiftPhoenixClient

final class PhoenixTransportSerializerTest {
    
    private let serializer: TransportSerializer = PhoenixTransportSerializer()
    private let payloadEncoder: PayloadEncoder = PhoenixPayloadEncoder()
    
    // - - - - - encode - - - - -
    @Test func test_encode_json_returns_string() throws {
        let message = OutgoingMessage(
            joinRef: "0",
            ref: "1",
            topic: "t",
            event: "e",
            payload: .json(["foo": 1])
        )
        
        let actual = try serializer.encode(message: message)
        let expected = """
        ["0","1","t","e",{"foo":1}]
        """
        #expect(expected == actual)
    }
    
    @Test func test_encode_encodable_returns_string() throws {
        let payload = TestData(foo: 1)

        let message = OutgoingMessage(
            joinRef: "0",
            ref: "1",
            topic: "t",
            event: "e",
            payload: .encodable(payload)
        )
        
        let actual = try serializer.encode(message: message)
        let expected = """
        ["0","1","t","e",{"foo":1}]
        """
        #expect(expected == actual)
    }
    
    @Test func test_encode_binary_throws_error() throws {
        let message = OutgoingMessage(
            joinRef: "0",
            ref: "1",
            topic: "t",
            event: "e",
            payload: .binary(Data())
        )
        
        #expect(performing: {
            try serializer.encode(message: message)
        }, throws: { error in
            switch error as! TransportSerializerError {
            case .binarySentAsText(let message):
                #expect(message.ref == "1")
                return true
            default: return false
            }
        })
    }
    
    
    // - - - - - binaryEncode(.binary) - - - - -
    @Test func test_binaryEncode_sends_raw_binary() throws {
        // "\0\x01\x01\x01\x0101te\x01"
        let expectedBuffer: [UInt8] = [0x00, 0x01, 0x01, 0x01, 0x01]
        + "01te".utf8.map { UInt8($0) }
        + [0x01]
        
        let payload = Data(bytes: [0x01] as [UInt8], count: 1)
        let message = OutgoingMessage(
            joinRef: "0",
            ref: "1",
            topic: "t",
            event: "e",
            payload: .binary(payload)
        )
        
        let data = try serializer.binaryEncode(message: message)
        let binary = [UInt8](data)
        #expect(expectedBuffer == binary)
    }
    
    @Test func test_binaryEncode_sends_encodable() throws {
        // "\0\x01\x01\x01\x0101te\x01"
        let expectedBuffer: [UInt8] = [0x00, 0x01, 0x01, 0x01, 0x01]
        + "01te".utf8.map { UInt8($0) }
        // The below array is the value of TestData(foo: 1) as Data
        + [0x7B, 0x22, 0x66, 0x6f, 0x6f, 0x22, 0x3A, 0x31, 0x7D]
        
        let payload = TestData(foo: 1)
        let payloadData = try self.payloadEncoder.encode(payload)
        
        let message = OutgoingMessage(
            joinRef: "0",
            ref: "1",
            topic: "t",
            event: "e",
            payload: .binary(payloadData)
        )
        
        let data = try serializer.binaryEncode(message: message)
        let binary = [UInt8](data)
        #expect(expectedBuffer == binary)
    }
    
    @Test func test_binaryEncode_sends_json() throws {
        // "\0\x01\x01\x01\x0101te\x01"
        let expectedBuffer: [UInt8] = [0x00, 0x01, 0x01, 0x01, 0x01]
        + "01te".utf8.map { UInt8($0) }
        // The below array is the value of ["foo":1] as Data
        + [0x7B, 0x22, 0x66, 0x6f, 0x6f, 0x22, 0x3A, 0x31, 0x7D]
        
        let payload = ["foo": 1]
        let payloadData = try self.payloadEncoder.encode(payload)
        
        let message = OutgoingMessage(
            joinRef: "0",
            ref: "1",
            topic: "t",
            event: "e",
            payload: .binary(payloadData)
        )
        
        let data = try serializer.binaryEncode(message: message)
        let binary = [UInt8](data)
        #expect(expectedBuffer == binary)
    }

    @Test func test_binaryEncode_variableLengthSegments() throws {
        // "\0\x02\x01\x03\x02101topev\x01"
        let expectedBuffer: [UInt8] = [0x00, 0x02, 0x01, 0x03, 0x02]
        + "101topev".utf8.map { UInt8($0) }
        + [0x01]
        
        
        let message = OutgoingMessage(
            joinRef: "10",
            ref: "1",
            topic: "top",
            event: "ev",
            payload: .binary(Data(bytes: [0x01] as [UInt8], count: 1))
        )
        
        let data = try serializer.binaryEncode(message: message)
        let binary = [UInt8](data)
        #expect(expectedBuffer == binary)
    }
    
    // - - - - - decode(text) - - - - -
    @Test func test_decodeText() throws {
        let text = """
        ["1","2","topic","event",{"foo":"bar"}]
        """
        
        let message = try serializer.decode(text: text)
        #expect(message.joinRef == "1")
        #expect(message.ref == "2")
        #expect(message.topic == "topic")
        #expect(message.event == "event")
        #expect(message.status == nil)
        
        if case .deferred(let data) = message.payload {
            #expect(data == text.data(using: .utf8))
        } else {
            fatalError("expected deferred payload type")
        }
        
        #expect(message.rawText == text)
        #expect(message.rawBinary == nil)
    }
    
    @Test func test_decodeReply() throws {
        let text = """
        [null,"2", "topic","phx_reply",{"response":"foo","status":"ok"}]
        """
        
        let reply = try serializer.decode(text: text)
        #expect(reply.joinRef == nil)
        #expect(reply.ref == "2")
        #expect(reply.topic == "topic")
        #expect(reply.event == "phx_reply")
        #expect(reply.status == "ok")
        
        if case .deferred(let data) = reply.payload {
            #expect(data == text.data(using: .utf8))
        } else {
            fatalError("expected deferred payload type")
        }
        
        #expect(reply.rawText == text)
        #expect(reply.rawBinary == nil)
    }

    
    // - - - - - binaryDecode(data) - - - - -
    @Test func test_binaryDecode_push() throws {
        // "\0\x03\x03\n123topsome-event\x01\x01"
        
        let bin: [UInt8] = [0x00, 0x03, 0x03, 0x0A]
        + "123topsome-event".utf8.map { UInt8($0) }
        + [0x01, 0x01]
        
        
        let message = try serializer.binaryDecode(data: Data(bin))
        #expect(message.joinRef == "123")
        #expect(message.ref == nil)
        #expect(message.topic == "top")
        #expect(message.event == "some-event")
        #expect(message.status == nil)
        
        if case .decided(let data) = message.payload {
            let binary = [UInt8](data)
            #expect(binary == [0x01, 0x01])
        } else {
            fatalError("expected decided payload type")
        }
        
        #expect(message.rawText == nil)
        #expect(message.rawBinary == Data(bin))
    }
    
    
    @Test func test_binaryDecode_reply() throws {
        // "\x01\x03\x02\x03\x0210012topok\x01\x01"
        let bin: [UInt8] = [0x01, 0x03, 0x02, 0x03, 0x02]
        + "10012topok".utf8.map { UInt8($0) }
        + [0x01, 0x01]
        
        
        let reply = try serializer.binaryDecode(data: Data(bin))
        #expect(reply.joinRef == "100")
        #expect(reply.ref == "12")
        #expect(reply.topic == "top")
        #expect(reply.status == "ok")
        
        if case .decided(let data) = reply.payload {
            let binary = [UInt8](data)
            #expect(binary == [0x01, 0x01])
        } else {
            fatalError("expected decided payload type")
        }
        
        #expect(reply.rawText == nil)
        #expect(reply.rawBinary == Data(bin))
        
    }
    
    @Test func test_binaryDecode_broadcast() throws {
        // "\x02\x03\ntopsome-event\x01\x01"
        let bin: [UInt8] = [0x02, 0x03, 0x0A]
        + "topsome-event".utf8.map { UInt8($0) }
        + [0x01, 0x01]
        
        
        let broadcast = try serializer.binaryDecode(data: Data(bin))
        #expect(broadcast.joinRef == nil)
        #expect(broadcast.ref == nil)
        #expect(broadcast.topic == "top")
        #expect(broadcast.event == "some-event")
        #expect(broadcast.status == nil)
        
        if case .decided(let data) = broadcast.payload {
            let binary = [UInt8](data)
            #expect(binary == [0x01, 0x01])
        } else {
            fatalError("expected decided payload type")
        }
        
        #expect(broadcast.rawText == nil)
        #expect(broadcast.rawBinary == Data(bin))
    }
}
