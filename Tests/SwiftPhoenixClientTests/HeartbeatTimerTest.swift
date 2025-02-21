//
//  HeartbeatTimerTest.swift
//  SwiftPhoenixClientTests
//
//  Created by Daniel Rees on 2/21/25.
//  Copyright © 2025 SwiftPhoenixClient. All rights reserved.
//

import Testing
@testable import SwiftPhoenixClient

@Suite("HeartbeatTimer")
struct HeartbeatTimerTest {

    @Suite("isValid")
    struct IsValidSuite {
        
        let queue = DispatchQueue(label: "heartbeat.timer.spec")
        let timer: HeartbeatTimer
        
        init() {
            timer = HeartbeatTimer(timeInterval: 10, queue: queue)
        }
        
        @Test("returns false if not started")
        func notStarted() async throws {
            #expect(timer.isValid == false)
        }
        
        @Test("returns true if started")
        func started() async throws {
            timer.start { /* no-op*/ }
            #expect(timer.isValid == true)
        }
        
        @Test("returns false if stopped")
        func stopped() async throws {
            timer.start { /* no-op*/ }
            timer.stop()
            #expect(timer.isValid == false)
        }
    }
    
    @Suite("fire")
    struct FireSuite {
        let queue = DispatchQueue(label: "heartbeat.timer.spec")
        let timer: HeartbeatTimer
        
        init() {
            timer = HeartbeatTimer(timeInterval: 10, queue: queue)
        }
        
        @Test("calls the event handler")
        func callsTheEventHandler() async throws {
            var timerCalled = 0
            timer.start { timerCalled += 1 }
            #expect(timerCalled == 0)
            
            timer.fire()
            #expect(timerCalled == 1) 
        }
        
        @Test("does not call the event handler if stopped")
        func doesNotCallTheEventHandlerIfStopped() async throws {
            var timerCalled = 0
            timer.start { timerCalled += 1 }
            #expect(timerCalled == 0)
            
            timer.stop()
            timer.fire()
            #expect(timerCalled == 0)
        }
    }
    

}
