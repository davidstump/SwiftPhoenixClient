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
    
  }
}
