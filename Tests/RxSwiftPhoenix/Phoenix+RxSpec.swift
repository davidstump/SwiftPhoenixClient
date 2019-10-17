//
//  Phoenix+RxSpec.swift
//  SwiftPhoenixTests
//
//  Created by Daniel Rees on 10/16/19.
//

import Quick
import Nimble
import RxSwift
import RxTest
import SwiftPhoenix
@testable import RxSwiftPhoenix

final class PhoenixRxSpec: QuickSpec {
  
  override func spec() {
    
    describe("channel") {
      it("should return string") {
        let phoenix = Phoenix()
        
        var emittedValue: String? = nil
        let _ = phoenix.rx.channel()
          .subscribe(onSuccess: { (value) in
            emittedValue = value
          }) { (error) in }
        
        
        expect(emittedValue).to(equal("RxSwiftPhoenix"))
        
      }
    }
    
  }
}
