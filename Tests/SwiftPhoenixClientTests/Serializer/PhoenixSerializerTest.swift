//
//  PhoenixSerializerTest.swift
//  SwiftPhoenixClientTests
//
//  Created by Daniel Rees on 2/23/24.
//  Copyright © 2024 SwiftPhoenixClient. All rights reserved.
//

import XCTest
@testable import SwiftPhoenixClient

final class PhoenixSerializerTest: XCTestCase {

    private let serializer: Serializer = PhoenixSerializer()
    
    // - - - - - encode(.json) - - - - -
    func test_encodePush() {
        let message = MessageV6(
            joinRef: "0",
            ref: "1",
            topic: "t",
            event: "e",
            payload: .json("{\"foo\": 1}")
        )
        let text = serializer.encode(message: message)
        XCTAssertEqual(text, """
        ["0","1","t","e","{\\"foo\\": 1}"]
        """
        )
      }
    
    // - - - - - binaryEncode(.binary) - - - - -
    func test_binaryEncode() {
        // "\0\x01\x01\x01\x0101te\x01"
        let expectedBuffer: [UInt8] = [0x00, 0x01, 0x01, 0x01, 0x01]
        + "01te".utf8.map { UInt8($0) }
        + [0x01]
        

        let message = MessageV6(
            joinRef: "0",
            ref: "1",
            topic: "t",
            event: "e",
            payload: .binary(Data(bytes: [0x01] as [UInt8], count: 1))
        )
        
        let data = serializer.binaryEncode(message: message)
        let binary = [UInt8](data)
        XCTAssertEqual(expectedBuffer, binary)
    }
    
    func test_binaryEncode_variableLengthSegments() {
        // "\0\x02\x01\x03\x02101topev\x01"
        let expectedBuffer: [UInt8] = [0x00, 0x02, 0x01, 0x03, 0x02]
        + "101topev".utf8.map { UInt8($0) }
        + [0x01]
        

        let message = MessageV6(
            joinRef: "10",
            ref: "1",
            topic: "top",
            event: "ev",
            payload: .binary(Data(bytes: [0x01] as [UInt8], count: 1))
        )
        
        let data = serializer.binaryEncode(message: message)
        let binary = [UInt8](data)
        XCTAssertEqual(expectedBuffer, binary)
    }
    
    
    // - - - - - decode(text) - - - - -
    func test_decodeMessage() throws {
        let text = """
        ["1","2","topic","event",{"foo":"bar"}]
        """
        
        switch serializer.decode(text: text) {
        case .message(let message):
            XCTAssertEqual(message.joinRef, "1")
            XCTAssertEqual(message.ref, "2")
            XCTAssertEqual(message.topic, "topic")
            XCTAssertEqual(message.event, "event")
            XCTAssertEqual(message.payload, .json("{\"foo\":\"bar\"}"))
        default:
            assertionFailure("Expected type .message")
        }
    }
    
    func test_decodeMessageWithNumbers() throws {
        let text = """
        ["1","2", "topic","event",{"int":1,"float":1.1}]
        """
        
        switch serializer.decode(text: text) {
        case .message(let message):
            XCTAssertEqual(message.payload, .json("{\"int\":1,\"float\":1.1}"))
        default:
            assertionFailure("Expected type .message")
        }
    }
    
    func test_decodeMessageWithoutJsonPayload() throws {
        // NOTE: Since NSNumber can be a float or an int, `1.0` will convert to `1`
        // but should be able to map `1` back into a float property.
        let text = """
        ["1","2", "topic","event","payload"]
        """
        
        switch serializer.decode(text: text) {
        case .message(let message):
            XCTAssertEqual(message.payload, .json("payload"))
        default:
            assertionFailure("Expected type .message")
        }
    }
    
    func test_decodeReply() throws {
        let text = """
        [null,"2", "topic","phx_reply",{"response":"foo","status":"ok"}]
        """
        
        switch serializer.decode(text: text) {
        case .reply(let reply):
            XCTAssertNil(reply.joinRef)
            XCTAssertEqual(reply.ref, "2")
            XCTAssertEqual(reply.topic, "topic")
            XCTAssertEqual(reply.status, "ok")
            XCTAssertEqual(reply.payload, .json("foo"))
        default:
            assertionFailure("Expected type .reply")
        }
    }
    
    func test_decodeReplyWithBody() throws {
        let text = """
        [null,"2", "topic","phx_reply",{"response":{"foo":"bar"},"status":"ok"}]
        """
        
        switch serializer.decode(text: text) {
        case .reply(let reply):
            XCTAssertEqual(reply.payload, .json("{\"foo\":\"bar\"}"))
        default:
            assertionFailure("Expected type .reply")
        }
    }
    
    func test_decodeBroadcast() throws {
        let text = """
        [null,null,"topic","event",{"user":"foo"}]
        """
        
        switch serializer.decode(text: text) {
        case .broadcast(let broadcast):
            XCTAssertEqual(broadcast.topic, "topic")
            XCTAssertEqual(broadcast.event, "event")
            XCTAssertEqual(broadcast.payload, .json("{\"user\":\"foo\"}"))
        default:
            assertionFailure("Expected type .broadcast")
        }
    }
    
    
    // - - - - - binaryDecode(data) - - - - -
    func test_binaryDecode_push() {
        // "\0\x03\x03\n123topsome-event\x01\x01"
        
        let bin: [UInt8] = [0x00, 0x03, 0x03, 0x0A]
        + "123topsome-event".utf8.map { UInt8($0) }
        + [0x01, 0x01]
        

        switch serializer.binaryDecode(data: Data(bin)) {
        case .message(let message):
            XCTAssertEqual(message.joinRef, "123")
            XCTAssertNil(message.ref)
            XCTAssertEqual(message.topic, "top")
            XCTAssertEqual(message.event, "some-event")
                        
            let binary = [UInt8](message.payload.asBinary())
            XCTAssertEqual([0x01, 0x01], binary)
            
        default:
            assertionFailure("Expected type .message")
        }
      }

      
    func test_binaryDecode_reply() {
        // "\x01\x03\x02\x03\x0210012topok\x01\x01"
        let bin: [UInt8] = [0x01, 0x03, 0x02, 0x03, 0x02]
        + "10012topok".utf8.map { UInt8($0) }
        + [0x01, 0x01]
        

        switch serializer.binaryDecode(data: Data(bin)) {
        case .reply(let reply):
            XCTAssertEqual(reply.joinRef, "100")
            XCTAssertEqual(reply.ref, "12")
            XCTAssertEqual(reply.topic, "top")
            XCTAssertEqual(reply.status, "ok")
            
            let binary = [UInt8](reply.payload.asBinary())
            XCTAssertEqual([0x01, 0x01], binary)
            
        default:
            assertionFailure("Expected type .reply")
        }
      }

    func test_binaryDecode_broadcast() {
        // "\x02\x03\ntopsome-event\x01\x01"
        let bin: [UInt8] = [0x02, 0x03, 0x0A]
        + "topsome-event".utf8.map { UInt8($0) }
        + [0x01, 0x01]
        

        switch serializer.binaryDecode(data: Data(bin)) {
        case .broadcast(let broadcast):
            XCTAssertEqual(broadcast.topic, "top")
            XCTAssertEqual(broadcast.event, "some-event")
            
            let binary = [UInt8](broadcast.payload.asBinary())
            XCTAssertEqual([0x01, 0x01], binary)
            
        default:
            assertionFailure("Expected type .broadcast")
        }
      }
}
