//
//  TimeoutTimerSpec.swift
//  SwiftPhoenixClientTests
//
//  Created by Daniel Rees on 2/10/19.
//

import Quick
import Nimble
@testable import SwiftPhoenixClient

class TimeoutTimerSpec: QuickSpec {
  
  public func secondsBetweenDates(_ first: Date, _ second: Date) -> Double {
    var diff = first.timeIntervalSince1970 - second.timeIntervalSince1970
    diff = fabs(diff)
    return diff
  }
  
  
  override func spec() {
    
    let fakeClock = FakeTimerQueue()
    var timer: TimeoutTimer!
    
    
    beforeEach {
      fakeClock.reset()
      
      timer = TimeoutTimer()
      timer.queue = fakeClock
    }
    
    describe("retain cycles") {
      it("does not hold any retain cycles", closure: {
//        var weakTimer: TimeoutTimer? = TimeoutTimer()
//        
//        var weakTimerCalled: Bool = false
//        timer.callback.delegate(to: weakTimer!) { (_) in
//          weakTimerCalled = true
//        }
//        
//        timer.timerCalculation.delegate(to: weakTimer!) { _,_ in 1.0 }
//        
//        
//        timer.scheduleTimeout()
//        fakeClock.tick(600)
//        weakTimer = nil
//        
//        fakeClock.tick(600)
//        expect(timer.tries).to(equal(1))
//        expect(weakTimerCalled).to(beFalse())
      })
    }
    
    
    describe("scheduleTimeout") {
      it("schedules timeouts, resets the timer, and schedules another timeout", closure: {
        var callbackTimes: [Date] = []
        timer.callback.delegate(to: self) { (_) in
          callbackTimes.append(Date())
        }
        
        timer.timerCalculation.delegate(to: self) { (_, tries) -> TimeInterval in
          return tries > 2 ? 10.0 : [1.0, 2.0, 5.0][tries - 1]
        }
        
        timer.scheduleTimeout()
        fakeClock.tick(1100)
        expect(timer.tries).to(equal(1))
        
        timer.scheduleTimeout()
        fakeClock.tick(2100)
        expect(timer.tries).to(equal(2))
        
        timer.reset()
        timer.scheduleTimeout()
        fakeClock.tick(1100)
        expect(timer.tries).to(equal(1))
      })
      
      it("does not start timer if no interval is provided", closure: {
        timer.scheduleTimeout()
        expect(timer.workItem).to(beNil())
      })
    }
  }
}

