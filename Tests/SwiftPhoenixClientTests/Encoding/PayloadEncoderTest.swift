//
//  payload.swift
//  SwiftPhoenixClientTests
//
//  Created by Daniel Rees on 9/18/24.
//  Copyright © 2024 SwiftPhoenixClient. All rights reserved.
//

import XCTest
@testable import SwiftPhoenixClient


struct TestEncodable: Codable {
    let foo: String
}

final class PayloadEncoderTest: XCTestCase {
    
    private let encoder: PayloadEncoder = JSONPayloadEncoder.default
    
    func test_encodeEncodable() throws {
        let testCodable = TestEncodable(foo: "bar")
        XCTAssertEqual(try encoder.encode(testCodable), .json("{\"foo\":\"bar\"}"))
    }
    
    func test_encodeString() throws {
        let testCodable = "test"
        XCTAssertEqual(try encoder.encode(testCodable), .json("\"test\""))
    }
    
    func test_encodeDictionary() throws {
        let testCodable: [String: Any] = ["foo": "bar"]
        XCTAssertEqual(try encoder.encode(testCodable), .json("{\"foo\":\"bar\"}"))
    }
}
