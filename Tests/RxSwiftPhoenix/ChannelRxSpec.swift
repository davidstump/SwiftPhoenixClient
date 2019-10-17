//
//  ChannelRxSpec.swift
//  RxSwiftPhoenix
//
//  Created by Daniel Rees on 10/16/19.
//

import Quick
import Nimble
import RxSwift
@testable import SwiftPhoenix
import RxSwiftPhoenix

final class ChannelRxSpec: QuickSpec {
  
  override func spec() {
    
    // Mocks
    var mockClient: WebSocketClientMock!
    var mockSocket: SocketMock!
    
    // Constants
    let kDefaultRef = "1"
    let kDefaultTimeout: TimeInterval = 10.0
    
    // UUT
    var channel: Channel!
    
    beforeEach {
      mockClient = WebSocketClientMock()
      
      mockSocket = SocketMock("/socket")
      mockSocket.connection = mockClient
      mockSocket.timeout = kDefaultTimeout
      mockSocket.makeRefReturnValue = kDefaultRef
      mockSocket.reconnectAfter = { tries -> TimeInterval in
        return tries > 3 ? 10 : [1, 2, 5, 10][tries - 1]
      }
      
      channel = Channel(topic: "topic", params: ["one": "two"], socket: mockSocket)
      mockSocket.channelParamsReturnValue = channel
    }
    
    
    describe("rx.on") {
      
      beforeEach {
        mockSocket.makeRefClosure = nil
        mockSocket.makeRefReturnValue = kDefaultRef
      }
      
      it("sets up callback for event", closure: {
        var onCallCount = 0
        
        channel.trigger(event: "event", ref: kDefaultRef)
        expect(onCallCount).to(equal(0))
        
        let _ = channel.rx.on("event")
          .subscribe(onNext: { (message) in
            onCallCount += 1
          })
        
        channel.trigger(event: "event", ref: kDefaultRef)
        expect(onCallCount).to(equal(1))
      })
      
      it("other event callbacks are ignored", closure: {
        var onCallCount = 0
        var ignoredOnCallCount = 0
        
        channel.trigger(event: "event", ref: kDefaultRef)
        expect(ignoredOnCallCount).to(equal(0))
        
        let _ = channel.rx.on("event")
        .subscribe(onNext: { (message) in
          onCallCount += 1
        })
        
        let _ = channel.rx.on("ignored_event")
        .subscribe(onNext: { (message) in
          ignoredOnCallCount += 1
        })
        
        channel.trigger(event: "event", ref: kDefaultRef)
        channel.trigger(event: "event", ref: kDefaultRef)
        channel.trigger(event: "ignored_event", ref: kDefaultRef)
        expect(onCallCount).to(equal(2))
        expect(ignoredOnCallCount).to(equal(1))
      })
      
      it("does not emit events to disposed subscriptions") {
        var callCount1 = 0
        var callCount2 = 0
        
        let sub1 = channel.rx.on("event")
          .subscribe(onNext: { (message) in
            callCount1 += 1
          })
        
        let sub2 = channel.rx.on("event")
          .subscribe(onNext: { (message) in
            callCount2 += 1
          })
        
        // Trigger event to both
        channel.trigger(event: "event", ref: kDefaultRef)
        
        // Dispose of sub1
        sub1.dispose()
        
        // Trigger event only to sub2
        channel.trigger(event: "event", ref: kDefaultRef)
        
        sub2.dispose()
        
        // Trigger event neithers
        channel.trigger(event: "event", ref: kDefaultRef)
        
        expect(callCount1).to(equal(1))
        expect(callCount2).to(equal(2))
      }
    }
  }
}
