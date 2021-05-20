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

import Quick
import Nimble
import RxSwift
import RxSwiftPhoenixClient
@testable import SwiftPhoenixClient


@available(iOS 13, *)
final class ChannelRxSpec: QuickSpec {
  
  override func spec() {
    
    // Mocks
    var mockClient: PhoenixTransportMock!
    var mockSocket: SocketMock!
    
    // Constants
    let kDefaultRef = "1"
    let kDefaultTimeout: TimeInterval = 10.0
    
    // UUT
    var channel: Channel!
    
    beforeEach {
      mockClient = PhoenixTransportMock()
      
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
