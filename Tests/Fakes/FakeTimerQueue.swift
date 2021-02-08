// Copyright (c) 2021 David Stump <david@davidstump.net>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation


import Foundation
@testable import SwiftPhoenixClient


/**
 Provides a fake TimerQueue that allows tests to manipulate the clock without
 actually waiting on a real Timer.
 */
class FakeTimerQueue: TimerQueue {
  
  var tickTime: TimeInterval = 0.0
  var workItems: [(deadline: TimeInterval, workItem: DispatchWorkItem)] = []
  
  func reset() {
    self.tickTime = 0.0
    self.workItems = []
  }
  
  func tick(_ timeInterval: TimeInterval) {
    // calculate what time to advance to
    let advanceTo = self.tickTime + timeInterval
    
    // Filter all work items that are due to be fired and have not been
    // cancelled. Return early if there are no items to fire
    var pastDue = workItems
      .filter({ $0.deadline <= advanceTo && !$0.workItem.isCancelled })
    
    // Keep looping until there are no more work items that are passed the
    // advance to time
    while !pastDue.isEmpty {
      
      // Perform all work items that are due
      pastDue.forEach({
        self.tickTime = $0.deadline
        $0.workItem.perform()
      })
      
      // Remove all work items that are past due or canceled
      workItems.removeAll(where: { $0.deadline <= self.tickTime
        || $0.workItem.isCancelled })
      pastDue = workItems
        .filter({ $0.deadline <= advanceTo && !$0.workItem.isCancelled })
    }
    
    // Now that all work has been performed, advance the clock
    self.tickTime = advanceTo
    
  }
  
  override func queue(timeInterval: TimeInterval, execute: DispatchWorkItem) {
    let deadline = tickTime + timeInterval
    self.workItems.append((deadline, execute))
  }
  
  // Helper for writing tests
  func queue(timeInterval: TimeInterval, execute work: @escaping () -> Void) {
    self.queue(timeInterval: timeInterval, execute: DispatchWorkItem(block: work))
  }
}

