//
//  SocketSpy.swift
//  SwiftPhoenixClientTests
//
//  Created by Daniel Rees on 9/3/19.
//

@testable import SwiftPhoenixClient

class SocketSpy: Socket {
  
  private(set) var pushCalled: Bool?
  private(set) var pushCallCount: Int = 0
  private(set) var pushArgs: [Int: (topic: String, event: String, payload: Payload, ref: String?, joinRef: String?)] = [:]
  
  override func push(topic: String,
                     event: String,
                     payload: Payload,
                     ref: String? = nil,
                     joinRef: String? = nil) {
    self.pushCalled = true
    self.pushCallCount += 1
    self.pushArgs[pushCallCount] = (topic: topic, event: event, payload: payload, ref: ref, joinRef: joinRef)
    super.push(topic: topic,
               event: event,
               payload: payload,
               ref: ref,
               joinRef: joinRef)
  }

  
}
