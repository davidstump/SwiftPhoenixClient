//
//  QuickSpec.swift
//  SwiftPhoenixTests
//
//  Created by Daniel Rees on 10/16/19.
//

import Quick
import Nimble

final class QuickClassSpec: QuickSpec {
  
  override func spec() {
    
  
    describe("qucik and nimble") {
      it("should be false") {
        expect(true).to(beTrue())
      }
    }
    
  }
}

