//
//  TimeoutTimerTest.swift
//  SwiftPhoenixClientTests
//
//  Created by Daniel Rees on 2/21/25.
//  Copyright © 2025 SwiftPhoenixClient. All rights reserved.
//

import Testing
@testable import SwiftPhoenixClient

@Suite("TimeoutTimer")
struct TimeoutTimerTest {
    
    @Suite("scheduleTimeout")
    struct ScheduleTimeoutSuite {
        
        let fakeClock = FakeTimerQueue()
        let timer: TimeoutTimer
        
        init() {
            timer = TimeoutTimer()
            timer.queue = fakeClock
            timer.timerCalculation = Defaults.rejoinSteppedBackOff
        }
        
        
        @Test("schedules a timeout, resets, and schedules another")
        func scheudlesATimeout() async throws {
            timer.scheduleTimeout()
            fakeClock.tick(1100)
            #expect(timer.tries == 1)
            
            timer.scheduleTimeout()
            fakeClock.tick(2100)
            #expect(timer.tries == 2)
            
            timer.reset()
            timer.scheduleTimeout()
            fakeClock.tick(1100)
            #expect(timer.tries == 1)
        }
        
        @Test("does not start timer if no interval is provided")
        func requiresInterval() async throws {
            timer.timerCalculation = nil
            timer.scheduleTimeout()
            #expect(timer.workItem == nil)
        }
    }
}
