//
//  DecodablePayloadParserTest.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 1/28/25.
//  Copyright © 2025 SwiftPhoenixClient. All rights reserved.
//

import Testing
@testable import SwiftPhoenixClient



final class DecodablePayloadParserTest {

    @Suite("parse")
    struct ParseSuite {
        let encoder = PhoenixPayloadEncoder()
        let decoder = PhoenixPayloadDecoder()
        private let parser = DecodablePayloadParser(type: TestData.self)
        
        @Test("decided data")
        func decidedData() throws {
            // ["foo": 1]
            let expectedPayload = Data([0x7B, 0x22, 0x66, 0x6f, 0x6f, 0x22, 0x3A, 0x31, 0x7D])
            let message = buildIncomingMessage(payload: .decided(expectedPayload))
            let result = self.parser.parse(message,
                                           payloadDecoder: self.decoder,
                                           payloadEncoder: self.encoder)
            
            if case .success(let success) = result {
                #expect(success.foo == 1)
            } else {
                fatalError("expected success")
            }
        }
        
        @Test("deferred reply")
        func deferredReply() throws {
            let incomingMessageData = """
            ["0","1","t","phx_reply",{"status":"ok","response":{"foo":1}}]
            """.data(using: .utf8)!
            
            let message = buildIncomingMessage(
                event: "phx_reply",
                payload: .deferred(incomingMessageData)
            )
            let result = self.parser.parse(message,
                                           payloadDecoder: self.decoder,
                                           payloadEncoder: self.encoder)
            
            if case .success(let success) = result {
                #expect(success.foo == 1)
            } else {
                fatalError("expected success")
            }
        }
        
        @Test("deferred message")
        func deferredMessage() throws {
            let incomingMessageData = """
            ["0","1","t","e",{"foo":1}]
            """.data(using: .utf8)!
            
            let message = buildIncomingMessage(payload: .deferred(incomingMessageData))
            let result = self.parser.parse(message,
                                           payloadDecoder: self.decoder,
                                           payloadEncoder: self.encoder)
            
            if case .success(let success) = result {
                #expect(success.foo == 1)
            } else {
                fatalError("expected success")
            }
        }
    }
}
