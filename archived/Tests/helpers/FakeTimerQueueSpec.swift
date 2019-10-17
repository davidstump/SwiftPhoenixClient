//
//  FakeTimerQueueSpec.swift
//  SwiftPhoenixClientTests
//
//  Created by Daniel Rees on 9/3/19.
//



import Quick
import Nimble
@testable import SwiftPhoenixClient

/// Tests the FakeTimerQueue that is used in all other tests to verify that
/// the fake timer is behaving as expected in all tests to prevent false
/// negatives or positives when writing tests
class FakeTimerQueueSpec: QuickSpec {
  
  override func spec() {
    
    var queue: FakeTimerQueue!
    
    beforeEach {
      queue = FakeTimerQueue()
    }
    
    afterEach {
      queue.reset()
    }
    
    describe("reset") {
      it("resets the queue", closure: {
        var task100msCalled = false
        var task200msCalled = false
        var task300msCalled = false
        
        queue.queue(timeInterval: 0.1, execute: { task100msCalled = true })
        queue.queue(timeInterval: 0.2, execute: { task200msCalled = true })
        queue.queue(timeInterval: 0.3, execute: { task300msCalled = true })
        
        queue.tick(0.250)
        expect(queue.tickTime).to(equal(0.250))
        expect(queue.workItems).to(haveCount(1))
        expect(task100msCalled).to(beTrue())
        expect(task200msCalled).to(beTrue())
        expect(task300msCalled).to(beFalse())
        
        queue.reset()
        expect(queue.tickTime).to(equal(0))
        expect(queue.workItems).to(beEmpty())
      })
    }
    
    describe("triggers") {
      it("triggers work that is passed due", closure: {
        var task100msCalled = false
        var task200msCalled = false
        var task300msCalled = false
        
        queue.queue(timeInterval: 0.1, execute: { task100msCalled = true })
        queue.queue(timeInterval: 0.2, execute: { task200msCalled = true })
        queue.queue(timeInterval: 0.3, execute: { task300msCalled = true })
        
        queue.tick(0.100)
        expect(queue.tickTime).to(equal(0.100))
        expect(task100msCalled).to(beTrue())
        
        queue.tick(0.100)
        expect(queue.tickTime).to(equal(0.200))
        expect(task200msCalled).to(beTrue())
        
        queue.tick(0.050)
        expect(queue.tickTime).to(equal(0.250))
        expect(task300msCalled).to(beFalse())
      })
      
      it("triggers all work that is passed due", closure: {
        var task100msCalled = false
        var task200msCalled = false
        var task300msCalled = false
        
        queue.queue(timeInterval: 0.1, execute: { task100msCalled = true })
        queue.queue(timeInterval: 0.2, execute: { task200msCalled = true })
        queue.queue(timeInterval: 0.3, execute: { task300msCalled = true })
        
        queue.tick(0.250)
        expect(queue.tickTime).to(equal(0.250))
        expect(queue.workItems).to(haveCount(1))
        expect(task100msCalled).to(beTrue())
        expect(task200msCalled).to(beTrue())
        expect(task300msCalled).to(beFalse())
      })
      
      it("triggers work that is scheduled for a time that is after tick", closure: {
        var task100msCalled = false
        var task200msCalled = false
        var task300msCalled = false
        
        queue.queue(timeInterval: 0.1, execute: {
          task100msCalled = true
          
          queue.queue(timeInterval: 0.1, execute: {
            task200msCalled = true
          })

        })
        
        queue.queue(timeInterval: 0.3, execute: { task300msCalled = true })
        
        queue.tick(0.250)
        expect(queue.tickTime).to(equal(0.250))
        expect(task100msCalled).to(beTrue())
        expect(task200msCalled).to(beTrue())
        expect(task300msCalled).to(beFalse())
      })
      
      it("does not triggers nested work that is scheduled outside of the tick", closure: {
        var task100msCalled = false
        var task200msCalled = false
        var task300msCalled = false
        
        queue.queue(timeInterval: 0.1, execute: {
          task100msCalled = true
          
          queue.queue(timeInterval: 0.1, execute: {
            task200msCalled = true
            
            queue.queue(timeInterval: 0.1, execute: {
              task300msCalled = true
            })
            
          })
          
        })
        
        queue.tick(0.250)
        expect(queue.tickTime).to(equal(0.250))
        expect(task100msCalled).to(beTrue())
        expect(task200msCalled).to(beTrue())
        expect(task300msCalled).to(beFalse())
      })
    }
  }
}

