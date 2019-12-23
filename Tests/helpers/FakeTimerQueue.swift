//
//  FakeTimerQueue.swift
//  SwiftPhoenixClientTests
//
//  Created by Daniel Rees on 3/7/19.
//

import Foundation
@testable import SwiftPhoenixClient


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
//
//    guard !pastDue.isEmpty else { return }
//
//    // Perform all work items that are due
//    pastDue.forEach({ $0.workItem.perform() })
//
//    // Remove all work items that are past due or canceled
//    workItems.removeAll(where: { $0.deadline <= self.tickTime
//      || $0.workItem.isCancelled })
    
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
