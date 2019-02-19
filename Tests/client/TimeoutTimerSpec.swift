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
                var callbackTimes: [Double] = []
                timer.callback.delegate(to: self) { (_) in
                    callbackTimes.append(Date().timeIntervalSince1970)
                }
                
                timer.timerCalculation.delegate(to: self) { (_, tries) -> TimeInterval in
                    return tries > 2 ? 1 : [1, 5, 10][tries - 1]
                }
                
                
                let startTime0 = Date()
                timer.scheduleTimeout()
                
                let duration0 = timer.underlyingTimer?.fireDate
                timer.underlyingTimer?.fire()
                
                expect(self.secondsBetweenDates(startTime0, duration0!)).to(beCloseTo(1.0001))
                
                
                let startTime1 = Date()
                timer.scheduleTimeout()
                
                let duration1 = timer.underlyingTimer?.fireDate
                timer.underlyingTimer?.fire()
                
                expect(self.secondsBetweenDates(startTime1, duration1!)).to(beCloseTo(5.0001))
                
                
                let startTime2 = Date()
                timer.reset()
                timer.scheduleTimeout()
                
                let duration2 = timer.underlyingTimer?.fireDate
                timer.underlyingTimer?.fire()
                
                expect(self.secondsBetweenDates(startTime2, duration2!)).to(beCloseTo(1.0001))
                
                expect(callbackTimes).to(haveCount(3))
            })
            
            it("does not start timer if no interval is provided", closure: {
                timer.scheduleTimeout()
                expect(timer.underlyingTimer).to(beNil())
            })
        }
    }
}

