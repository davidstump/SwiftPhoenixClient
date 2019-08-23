//
//  FakeTimerQueue.swift
//  SwiftPhoenixClientTests
//
//  Created by Daniel Rees on 3/7/19.
//

@testable import SwiftPhoenixClient


class FakeTimerQueue: TimerQueue {
  
  private var tickTime: TimeInterval = 0.0
  private var queue: [(deadline: TimeInterval, workItem: DispatchWorkItem)] = []
  
  func reset() {
    self.tickTime = 0.0
    self.queue = []
  }
  
  func tick(_ timeInterval: TimeInterval) {
    self.tickTime += timeInterval
    
    // Filter all work items that are due to be fired and have not been
    // cancelled. Return early if there are no items to fire
    let pastDue = queue
      .filter({ $0.deadline <= self.tickTime && !$0.workItem.isCancelled })
    guard !pastDue.isEmpty else { return }
    
    // Perform all work items that are due
    pastDue.forEach({ $0.workItem.perform() })
    
    // Remove all work items that are past due or canceled
    queue.removeAll(where: { $0.deadline <= self.tickTime || $0.workItem.isCancelled })
    print("Removed ")
  }
  
  override func queue(timeInterval: TimeInterval, execute: DispatchWorkItem) {
    let deadline = tickTime + timeInterval
    self.queue.append((deadline, execute))
  }
  
}
