//
//  ChannelSpec.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 2/10/18.
//

import Quick
import Nimble
@testable import SwiftPhoenixClient

class ChannelSpec: QuickSpec {
    
    class FakeSocket: Socket {
        
        var leaveTopicPayloadCallsCount = 0
        var leaveTopicPayloadCalled: Bool { return leaveTopicPayloadCallsCount > 0 }
        var leaveTopicPayloadArguments: (topic: String, payload: Socket.Payload?)?
        override func leave(topic: String, payload: Socket.Payload?) {
            leaveTopicPayloadCallsCount += 1
            leaveTopicPayloadArguments = (topic: topic, payload: payload)
        }
        
        var sendEventTopicPayloadCallsCount = 0
        var sendEventTopicPayloadCalled: Bool { return sendEventTopicPayloadCallsCount > 0 }
        var sendEventTopicPayloadArguments: (event: String, topic: String, payload: Socket.Payload)?
        var sendEventTopicPayloadReturnValue: Outbound?
        override func send(event: String, topic: String, payload: Socket.Payload) -> Outbound {
            sendEventTopicPayloadCallsCount += 1
            sendEventTopicPayloadArguments = (event: event, topic: topic, payload: payload)
            return sendEventTopicPayloadReturnValue!
        }
    }
    
    override func spec() {
        
        // Fakes
        var fakeSocket: FakeSocket!
        
        // UUT
        var channel: Channel!
        
        beforeEach {
            fakeSocket = FakeSocket(url: "localhost:4000")
            
            channel = Channel(socket: fakeSocket,
                              topic: "topic",
                              payload: ["key":"value"],
                              joinClosure: { (_) in })
        }
        
        describe(".join()") {
            it("should send an Outbound message", closure: {
                channel = Channel(socket: fakeSocket,
                                  topic: "topic",
                                  payload: nil,
                                  joinClosure: { (_) in })
                
                fakeSocket.sendEventTopicPayloadReturnValue = Outbound(topic: "", event: "", payload: [:])
                
                channel.join()
                expect(fakeSocket.sendEventTopicPayloadArguments?.event).to(equal("phx_join"))
                expect(fakeSocket.sendEventTopicPayloadArguments?.topic).to(equal("topic"))
                expect(fakeSocket.sendEventTopicPayloadArguments?.payload).to(beEmpty())
            })
        }
        
        describe(".leave(payload:)") {
            it("should leave the socket and not receive new events", closure: {
                var handlerCallsCount: Int = 0
                var handlerCalled: Bool { return handlerCallsCount > 0 }
                channel.on(event: "event", handler: { (payload) in
                    handlerCallsCount += 1
                })
                
                
                channel.leave(payload: ["key": "value"])
                channel.triggerEvent(named: "event", with: ["event_key": "event_value"])
                expect(fakeSocket.leaveTopicPayloadCalled).to(beTrue())
                expect(fakeSocket.leaveTopicPayloadArguments?.topic).to(equal("topic"))
                expect(fakeSocket.leaveTopicPayloadArguments?.payload?["key"] as? String).to(equal("value"))
                expect(handlerCalled).to(beFalse())
            })
            
            it("should use a default payload size", closure: {
                var handlerCallsCount: Int = 0
                var handlerCalled: Bool { return handlerCallsCount > 0 }
                channel.on(event: "event", handler: { (payload) in
                    handlerCallsCount += 1
                })
                
                channel.leave(payload: nil)
                channel.triggerEvent(named: "event", with: ["event_key": "event_value"])
                expect(fakeSocket.leaveTopicPayloadArguments?.payload).to(beEmpty())
            })
        }
        
        describe(".send(event:, payload:)") {
            it("should send a message to the socket", closure: {
                fakeSocket.sendEventTopicPayloadReturnValue = Outbound(topic: "", event: "", payload: [:])
                
                let _ = channel.send(event: "event", payload: nil)
                expect(fakeSocket.sendEventTopicPayloadCalled).to(beTrue())
                expect(fakeSocket.sendEventTopicPayloadArguments?.event).to(equal("event"))
                expect(fakeSocket.sendEventTopicPayloadArguments?.topic).to(equal("topic"))
                expect(fakeSocket.sendEventTopicPayloadArguments?.payload).to(beEmpty())
            })
        }
        
        describe("on, trigger, and leaving and event") {
            it("should bind to an event, receive it, and then leave an event", closure: {
                var handlerCallsCount: Int = 0
                var handlerCalled: Bool { return handlerCallsCount > 0 }
                channel.on(event: "event", handler: { (payload) in
                    handlerCallsCount += 1
                })
                
                channel.triggerEvent(named: "event", with: ["event_key": "event_value"])
                channel.off(event: "event")
                channel.triggerEvent(named: "event", with: ["event_key": "event_value"])
                expect(handlerCallsCount).to(equal(1))
            })
        }
    }
}

