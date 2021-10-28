//
//  MessageSpec.swift
//  SwiftPhoenixClientTests
//
//  Created by Daniel Rees on 10/27/21.
//  Copyright © 2021 SwiftPhoenixClient. All rights reserved.
//

import Quick
import Nimble
@testable import SwiftPhoenixClient


class MessageSpec: QuickSpec {
  
  override func spec() {
        
    describe("json parsing") {
      
      it("parses a normal message") {
        let json: [String: Any] = [
          "event": "update",
          "payload": [
            "user": "James S.",
            "message": "This is a test"
          ],
          "ref": "6",
          "topic": "my-topic"
        ]
        
        let message = Message(json: json)
        expect(message?.ref).to(equal("6"))
        expect(message?.joinRef).to(beNil())
        expect(message?.topic).to(equal("my-topic"))
        expect(message?.event).to(equal("update"))
        expect(message?.payload["user"] as? String).to(equal("James S."))
        expect(message?.payload["message"] as? String).to(equal("This is a test"))
        expect(message?.status).to(beNil())
      }
      
      it("parses a reply") {
        let json: [String: Any] = [
          "event": "phx_reply",
          "payload": [
            "response": [
              "user": "James S.",
              "message": "This is a test"
            ],
            "status": "ok"
          ],
          "ref": "6",
          "topic": "my-topic"
        ]
        
        let message = Message(json: json)
        expect(message?.ref).to(equal("6"))
        expect(message?.joinRef).to(beNil())
        expect(message?.topic).to(equal("my-topic"))
        expect(message?.event).to(equal("phx_reply"))
        expect(message?.payload["user"] as? String).to(equal("James S."))
        expect(message?.payload["message"] as? String).to(equal("This is a test"))
        expect(message?.status).to(equal("ok"))
      }
    }
  }
}
