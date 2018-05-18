//
//  ChannelSpec.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 5/18/18.
//

import Quick
import Nimble
@testable import SwiftPhoenixClient

class ChannelSpec: QuickSpec {
    
    override func spec() {
    
        /// Mocks
        var mockSocket: SocketMock!
        var onCloseCalledCount: Int!
        var onErrorCalledCount: Int!
        
        
        /// UUT
        var channel: Channel!
        
        beforeEach {
            mockSocket = SocketMock()
            channel = Channel(topic: "topic", params: ["one": 2], socket: mockSocket)
        }
        
        
        describe(".init(topic:, parms:, socket:)") {
            it("sets defaults", closure: {
                expect(channel.state).to(equal(ChannelState.closed))
                expect(channel.topic).to(equal("topic"))
                expect(channel.params["one"] as? Int).to(equal(2))
                expect(channel.socket).to(beAKindOf(SocketMock.self))
                expect(channel.timeout).to(equal(PHOENIX_DEFAULT_TIMEOUT))
                expect(channel.joinedOnce).to(beFalse())
                expect(channel.pushBuffer).to(beEmpty())
            })
            
            it("handles nil params", closure: {
                channel = Channel(topic: "topic", params: nil, socket: mockSocket)
                expect(channel.params).toNot(beNil())
                expect(channel.params).to(beEmpty())
            })
            
            it("sets up the joinPush", closure: {
                let joinPush = channel.joinPush
                expect(joinPush?.channel.topic).to(equal(channel.topic))
                expect(joinPush?.payload["one"] as? Int).to(equal(2))
                expect(joinPush?.event).to(equal(ChannelEvent.join))
                expect(joinPush?.timeout).to(equal(PHOENIX_DEFAULT_TIMEOUT))
            })
        }
        
        describe("message") {
            it("defaults to return just the given message", closure: {
                let message = Message(ref: "ref", topic: "topic", event: "event", payload: [:])
                let result = channel.onMessage(message)
                
                expect(result.ref).to(equal("ref"))
                expect(result.topic).to(equal("topic"))
                expect(result.event).to(equal("event"))
                expect(result.payload).to(beEmpty())
            })
        }
        
        describe(".join(joinParams:, timout:)") {
            it("should override the joinPush params if given", closure: {
                let push = channel.join(joinParams: ["override": true])
                expect(push.payload["one"]).to(beNil())
                expect(push.payload["override"] as? Bool).to(beTrue())
                expect(channel.joinedOnce).to(beTrue())
            })
        }
        
        
        describe("on(event:, callback:)") {
            it("should add a binder and then remove that same binder", closure: {
                let bindingsCountBefore = channel.bindings.count
                let closeRef = channel.onClose({ (_) in })
                
                expect(closeRef).to(equal(channel.bindingRef - 1))
                expect(channel.bindings).to(haveCount(bindingsCountBefore + 1))
                
                // Now remove just the closeRef binding
                channel.off(ChannelEvent.close, ref: closeRef)
                expect(channel.bindings).to(haveCount(bindingsCountBefore))
            })
        }
        
        describe(".off(event:)") {
            it("should remove all bindings of an event type", closure: {
                channel.on("test", callback: { (_) in })
                channel.on("test", callback: { (_) in })
                channel.on("test", callback: { (_) in })
                expect(channel.bindings.filter({$0.event == "test"}).count).to(equal(3))
                
                channel.off("test")
                expect(channel.bindings.filter({$0.event == "test"}).count).to(equal(0))
            })
        }
        
    }
}
