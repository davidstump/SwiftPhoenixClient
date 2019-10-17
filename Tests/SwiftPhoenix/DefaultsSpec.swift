//
//  DefaultsSpec.swift
//  SwiftPhoenixTests
//
//  Created by Daniel Rees on 10/16/19.
//

import Quick
import Nimble
@testable import SwiftPhoenix

final class DefaultSpec: QuickSpec {
  
  override func spec() {
    
    describe("timeoutInterval") {
      it("is 10s") {
        expect(Defaults.timeoutInterval).to(equal(10.0))
      }
    }
    
    describe("encode/decode") {
      it("converts dictionary to Data and back to Message", closure: {
        let body: [String: Any] = [
          "ref": "ref",
          "join_ref": "join_ref",
          "topic": "topic",
          "event": "event",
          "payload": ["user_id": "abc123"]
        ]
        
        
        let data = Defaults.encode(body)
        expect(data).toNot(beNil())
        
        let json = Defaults.decode(data)
        
        let message = Message(json: json!)
        expect(message?.ref).to(equal("ref"))
        expect(message?.joinRef).to(equal("join_ref"))
        expect(message?.topic).to(equal("topic"))
        expect(message?.event).to(equal("event"))
        expect(message?.payload["user_id"] as? String).to(equal("abc123"))
      })
    }
    
  }
}
