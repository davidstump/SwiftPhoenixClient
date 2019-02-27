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
        var timer: TimeoutTimer!
        
        beforeEach {
            timer = TimeoutTimer()
        }
        
        describe("retain cycles") {
            it("does not hold any retain cycles", closure: {
                var weakTimer: TimeoutTimer? = TimeoutTimer()
                
                var weakTimerCalled: Bool = false
                timer.callback.delegate(to: weakTimer!) { (_) in
                    weakTimerCalled = true
                }
                
                weakTimer = nil
                timer.scheduleTimeout()
                timer.underlyingTimer?.fire()
                
                expect(weakTimerCalled).to(beFalse())
            })
        }
        
        
        describe("scheduleTimeout") {
            it("schedules timeouts, resets the timer, and schedules another timeout", closure: {
                var callbackTimes: [Date] = []
                timer.callback.delegate(to: self) { (_) in
                    callbackTimes.append(Date())
                }
                
                timer.timerCalculation.delegate(to: self) { (_, tries) -> TimeInterval in
                    return tries > 2 ? 0.1 : [0.01, 0.05, 0.1][tries - 1]
                }
                
                
                let startTime0 = Date()
                timer.scheduleTimeout()
                expect(timer.tries).toEventually(equal(1))
                expect(self.secondsBetweenDates(startTime0, callbackTimes[0]))
                    .to(beGreaterThanOrEqualTo(0.01))
                
                let startTime1 = Date()
                timer.scheduleTimeout()
                expect(timer.tries).toEventually(equal(2))
                expect(self.secondsBetweenDates(startTime1, callbackTimes[1]))
                    .to(beGreaterThanOrEqualTo(0.05))

                let startTime2 = Date()
                timer.reset()
                timer.scheduleTimeout()
                expect(timer.tries).toEventually(equal(1))
                expect(self.secondsBetweenDates(startTime2, callbackTimes[2]))
                    .to(beGreaterThanOrEqualTo(0.01))
            })
            
            it("does not start timer if no interval is provided", closure: {
                timer.scheduleTimeout()
                expect(timer.workItem).to(beNil())
            })
        }
    }
}

