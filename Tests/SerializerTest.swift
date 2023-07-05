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
        let message = serializer.decode(text: "[\"0\",\"1\",\"t\",\"e\",{\"foo\":1}]")
    }
    
    func testJsonDecodesReply() throws {
        let message = serializer.decode(text: "[\"0\",\"1\",\"t\",\"e\",{\"foo\":1}]")
    }
    
    func testJsonDecodesBroadcast() throws {
        let message = serializer.decode(text: "[null,\"1\",\"t\",\"e\",{\"foo\":1}]")
        
    }
    
    
}

