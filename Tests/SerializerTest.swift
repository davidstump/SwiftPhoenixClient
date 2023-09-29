//
//  ExampleTest.swift
//  SwiftPhoenixClientTests
//
//  Created by Daniel Rees on 7/4/23.
//  Copyright © 2023 SwiftPhoenixClient. All rights reserved.
//

import XCTest
@testable import SwiftPhoenixClient

final class SerializerTest: XCTestCase {

    private var serializer: Serializer = VSN2Serializer()
    private let exampleMsg = MessageV6(joinRef: "0", ref: "1", topic: "t", event: "e", payload: .text("{\"foo\": 1}"))
    
    func testJsonEncodesGeneralPush() throws {
        XCTAssertEqual(
            serializer.encode(message: exampleMsg),
            "[\"0\",\"1\",\"t\",\"e\",{\"foo\":1}]"
        )
    }
    
    func testJsonDecodesMessage() throws {
        let payload = "[\"0\",\"1\",\"t\",\"e\",{\"foo\":1}]"
        let message = serializer.decode(text: payload)
        
        
        XCTAssertEqual(message.joinRef, "0")
        XCTAssertEqual(message.ref, "1")
        XCTAssertEqual(message.topic, "t")
        XCTAssertEqual(message.event, "e")
        
        XCTAssertNil(message.status)
        XCTAssertEqual(message.textPayload, "{\"foo\":1}")
    }
    
    func testJsonDecodesAbnormalMessage() throws {
        let payload = "[\"0\",\"1\",\"t\",\"e\",\"foobar\"]"
        let message = serializer.decode(text: payload)
        
        
        XCTAssertEqual(message.joinRef, "0")
        XCTAssertEqual(message.ref, "1")
        XCTAssertEqual(message.topic, "t")
        XCTAssertEqual(message.event, "e")
        
        XCTAssertNil(message.status)
        XCTAssertEqual(message.textPayload, "{\"foo\":1}")
    }
    
    func testJsonDecodesEmptyReply() throws {
        let payload = "[null,\"1\",\"t\",\"e\",{\"response\":{},\"status\":\"ok\"}]"
        let message = serializer.decode(text: payload)
        
        XCTAssertNil(message.joinRef)
        XCTAssertEqual(message.ref, "1")
        XCTAssertEqual(message.topic, "t")
        XCTAssertEqual(message.event, "e")
        
        XCTAssertEqual(message.status, "ok")
        XCTAssertEqual(message.textPayload, "{}")
    }
    
    func testJsonDecodesAbnormalReply() throws {
        let payload = "[null,\"1\",\"t\",\"e\",{\"response\":\"foobar\",\"status\":\"ok\"}]"
        let message = serializer.decode(text: payload)
        
        XCTAssertNil(message.joinRef)
        XCTAssertEqual(message.ref, "1")
        XCTAssertEqual(message.topic, "t")
        XCTAssertEqual(message.event, "e")
        
        XCTAssertEqual(message.status, "ok")
        XCTAssertEqual(message.textPayload, "{}")
    }
    
    func testJsonDecodesReply() throws {
        let payload = "[null,\"1\",\"t\",\"e\",{\"response\":{\"foo\":1},\"status\":\"ok\"}]"
        let message = serializer.decode(text: payload)
        
        XCTAssertNil(message.joinRef)
        XCTAssertEqual(message.ref, "1")
        XCTAssertEqual(message.topic, "t")
        XCTAssertEqual(message.event, "e")
        
        XCTAssertEqual(message.status, "ok")
        XCTAssertEqual(message.textPayload, "{\"foo\":1}")
    }
    
    func testJsonDecodesBroadcast() throws {
        let payload = "[null,null,\"t\",\"e\",{\"foo\":1]"
        let message = serializer.decode(text: payload)
        
        XCTAssertNil(message.joinRef)
        XCTAssertNil(message.ref)
        XCTAssertEqual(message.topic, "t")
        XCTAssertEqual(message.event, "e")
        
        XCTAssertNil(message.status)
        XCTAssertEqual(message.textPayload, "{\"foo\":1}")
    }
}

