//
//  DefaultSerializerSpec.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 1/17/19.
//

import Quick
import Nimble
@testable import SwiftPhoenixClient

class DefaultSerializerSpec: QuickSpec {
  
  override func spec() {
    describe("encode and decode message") {
      it("converts dictionary to Data and back to Message", closure: {
        let body: [Any] = ["join_ref", "ref", "topic", "event", ["user_id": "abc123"]]
        let data = Defaults.encode(body)
        expect(String(data: data, encoding: .utf8)).to(equal("[\"join_ref\",\"ref\",\"topic\",\"event\",{\"user_id\":\"abc123\"}]"))
        
        let json = Defaults.decode(data) as? [Any]
        
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

