//
//  PhoenixSpec.swift
//  SwiftPhoenix
//
//  Created by Daniel Rees on 10/16/19.
//

import Quick
import Nimble
@testable import SwiftPhoenix

final class PhoenixSpec: QuickSpec {
  
  override func spec() {
    
    describe("channel") {
      it("should return string") {
        let phoenix = Phoenix()
      
        expect(phoenix.channel()).to(equal("SwiftPhoenix"))
      }
    }
    
  }
}
