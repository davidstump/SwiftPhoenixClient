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
            XCTAssertEqual(message.payload, "{\"foo\":\"bar\"}")
        default:
            assertionFailure("Expected type .message")
        }
    }
    
    func test_decodeMessageWithNumbers() throws {
        // TODO: `1.0` will convert to `1` and `1.1` to `1.0001`
    
//        let text = """
//        ["1","2", "topic","event",{"int":1,"float":1.1}]
//        """
//        
//        switch serializer.decode(text: text) {
//        case .message(let message):
//            XCTAssertEqual(message.payload, "{\"int\":1,\"float\":1.1}")
//        default:
//            assertionFailure("Expected type .message")
//        }
    }
    
    func test_decodeMessageWithoutJsonPayload() throws {
        // NOTE: Since NSNumber can be a float or an int, `1.0` will convert to `1`
        // but should be able to map `1` back into a float property.
        let text = """
        ["1","2", "topic","event","payload"]
        """
        
        switch serializer.decode(text: text) {
        case .message(let message):
            XCTAssertEqual(message.payload, "payload")
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
            XCTAssertEqual(reply.payload, "foo")
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
            XCTAssertEqual(reply.payload, "{\"foo\":\"bar\"}")
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
            XCTAssertEqual(broadcast.payload, "{\"user\":\"foo\"}")
        default:
            assertionFailure("Expected type .broadcast")
        }
    }

}
