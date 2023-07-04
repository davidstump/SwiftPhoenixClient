////
////  HeartbeatTimerSpec.swift
////  SwiftPhoenixClientTests
////
////  Created by Daniel Rees on 8/24/21.
////  Copyright © 2021 SwiftPhoenixClient. All rights reserved.
////
//
//import Quick
//import Nimble
//@testable import SwiftPhoenixClient
//
//class HeartbeatTimerSpec: QuickSpec {
//
//  override func spec() {
//
//    let queue = DispatchQueue(label: "heartbeat.timer.spec")
//    var timer: HeartbeatTimer!
//
//
//    beforeEach {
//      timer = HeartbeatTimer(timeInterval: 10, queue: queue)
//    }
//
//    describe("isValid") {
//      it("returns false if is not started") {
//        expect(timer.isValid).to(beFalse())
//      }
//
//      it("returns true if the timer has started") {
//        timer.start { /* no-op */ }
//        expect(timer.isValid).to(beTrue())
//      }
//
//      it("returns false if timer has been stopped") {
//        timer.start { /* no-op */ }
//        timer.stop()
//        expect(timer.isValid).to(beFalse())
//      }
//    }
//
//    describe("fire") {
//      it("calls the event handler") {
//        var timerCalled = 0
//        timer.start { timerCalled += 1 }
//        expect(timerCalled).to(equal(0))
//
//        timer.fire()
//        expect(timerCalled).to(equal(1))
//      }
//
//      it("does not call event handler if stopped") {
//        var timerCalled = 0
//        timer.start { timerCalled += 1 }
//        expect(timerCalled).to(equal(0))
//
//        timer.stop()
//        timer.fire()
//        expect(timerCalled).to(equal(0))
//      }
//    }
//
//    describe("equatable") {
//      it("equates different timers correctly", closure: {
//        let timerA = HeartbeatTimer(timeInterval: 10, queue: queue)
//        let timerB = HeartbeatTimer(timeInterval: 10, queue: queue)
//
//        expect(timerA).to(equal(timerA))
//        expect(timerA).toNot(equal(timerB))
//
//      })
//    }
//  }
//}
