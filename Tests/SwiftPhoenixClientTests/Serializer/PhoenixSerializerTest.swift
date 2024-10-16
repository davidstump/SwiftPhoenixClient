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

final class PhoenixSerializerTest {
    
    private let serializer: Serializer = PhoenixSerializer()
    
    // - - - - - encode(.json) - - - - -
    @Test func test_encodePush() throws {
        let message = Message.message(
            joinRef: "0",
            ref: "1",
            topic: "t",
            event: "e",
            payload: .json("{\"foo\": 1}")
        )
        let actual = serializer.encode(message: message)
        let expected = """
        ["0","1","t","e","{\\"foo\\": 1}"]
        """
        #expect(expected == actual)
    }
    
    // - - - - - binaryEncode(.binary) - - - - -
    @Test func test_binaryEncode() {
        // "\0\x01\x01\x01\x0101te\x01"
        let expectedBuffer: [UInt8] = [0x00, 0x01, 0x01, 0x01, 0x01]
        + "01te".utf8.map { UInt8($0) }
        + [0x01]
        
        
        let message = Message.message(
            joinRef: "0",
            ref: "1",
            topic: "t",
            event: "e",
            payload: .binary(Data(bytes: [0x01] as [UInt8], count: 1))
        )
        
        let data = serializer.binaryEncode(message: message)
        let binary = [UInt8](data)
        #expect(expectedBuffer == binary)
    }
    
    @Test func test_binaryEncode_variableLengthSegments() {
        // "\0\x02\x01\x03\x02101topev\x01"
        let expectedBuffer: [UInt8] = [0x00, 0x02, 0x01, 0x03, 0x02]
        + "101topev".utf8.map { UInt8($0) }
        + [0x01]
        
        
        let message = Message.message(
            joinRef: "10",
            ref: "1",
            topic: "top",
            event: "ev",
            payload: .binary(Data(bytes: [0x01] as [UInt8], count: 1))
        )
        
        let data = serializer.binaryEncode(message: message)
        let binary = [UInt8](data)
        #expect(expectedBuffer == binary)
    }
    
    
    // - - - - - decode(text) - - - - -
    @Test func test_decodeMessage() throws {
        let text = """
        ["1","2","topic","event",{"foo":"bar"}]
        """
        
        let message = try serializer.decode(text: text)
        #expect(message.joinRef == "1")
        #expect(message.ref == "2")
        #expect(message.topic == "topic")
        #expect(message.event == "event")
        #expect(message.status == nil)
        #expect(message.payload == .json("{\"foo\":\"bar\"}"))
    }
    
    @Test func test_decodeMessageWithNumbers() throws {
        let text = """
        ["1","2", "topic","event",{"int":1,"float":1.1}]
        """
        
        let message = try serializer.decode(text: text)
        
        let jsonResult = message.payload.asJson()
        let excpetedResultsContainJsonResult = [
            "{\"int\":1,\"float\":1.1}",
            "{\"float\":1.1,\"int\":1}"
        ].contains(jsonResult)
        
        #expect(excpetedResultsContainJsonResult)
    }
    
    @Test func test_decodeMessageWithoutJsonPayload() throws {
        // NOTE: Since NSNumber can be a float or an int, `1.0` will convert to `1`
        // but should be able to map `1` back into a float property.
        let text = """
        ["1","2", "topic","event","payload"]
        """
        
        let message = try serializer.decode(text: text)
        
        #expect(message.payload == .json("payload"))
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
        #expect(reply.payload == .json("foo"))
    }
    
    @Test func test_decodeReplyWithBody() throws {
        let text = """
        [null,"2", "topic","phx_reply",{"response":{"foo":"bar"},"status":"ok"}]
        """
        
        let reply = try serializer.decode(text: text)
        
        #expect(reply.payload == .json("{\"foo\":\"bar\"}"))
    }
    
    @Test func test_decodeBroadcast() throws {
        let text = """
        [null,null,"topic","event",{"user":"foo"}]
        """
        
        let broadcast = try serializer.decode(text: text)
        #expect(broadcast.joinRef == nil)
        #expect(broadcast.ref == nil)
        #expect(broadcast.topic == "topic")
        #expect(broadcast.event == "event")
        #expect(broadcast.status == nil)
        #expect(broadcast.payload == .json("{\"user\":\"foo\"}"))
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
        
        let binary = [UInt8](message.payload.asBinary())
        #expect([0x01, 0x01] == binary)
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
        
        let binary = [UInt8](reply.payload.asBinary())
        #expect([0x01, 0x01] == binary)
    }
    
    @Test func test_binaryDecode_broadcast() throws{
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
        
        let binary = [UInt8](broadcast.payload.asBinary())
        #expect([0x01, 0x01] == binary)
    }
}
