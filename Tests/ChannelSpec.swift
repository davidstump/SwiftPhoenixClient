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
        
        /// Utility method to easily filter the bindings for a channel by their event
        func eventBindings(_ event: String) -> [(event: String, ref: Int, callback: (Message) -> Void)]? {
            return channel.bindings.filter( { $0.event == event } )
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
                expect(joinPush?.channel?.topic).to(equal(channel.topic))
                expect(joinPush?.payload["one"] as? Int).to(equal(2))
                expect(joinPush?.event).to(equal(ChannelEvent.join))
                expect(joinPush?.timeout).to(equal(PHOENIX_DEFAULT_TIMEOUT))
            })

            it("should not introduce any retain cycles", closure: {
                weak var channel = Channel(topic: "topic", params: ["one": 2], socket: mockSocket)
                expect(channel).to(beNil())
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
        
        describe(".push(event:, payload:, timeout:)") {
            it("should send the push if the channel canp ush", closure: {
                channel.joinedOnce = true
                channel.state = ChannelState.joined
                mockSocket.isConnected = true
                
                let push = channel.push("test", payload: ["number": 1])
                expect(mockSocket.pushCalled).to(beTrue())
                let args = mockSocket.pushArgs
                expect(args?.topic).to(equal(channel.topic))
                expect(args?.event).to(equal(push.event))
                expect(args?.payload["number"] as? Int).to(equal(1))
            })
            
            it("should buffer the push if channel cannot push", closure: {
                channel.joinedOnce = true
                channel.state = ChannelState.closed
                mockSocket.isConnected = true
                mockSocket.makeRefReturnValue = "stubbed"
                
                let push = channel.push("test", payload: ["number": 1])
                expect(mockSocket.pushCalled).to(beFalse())
                
                expect(push.ref).to(equal("stubbed"))
                expect(push.refEvent).to(equal("chan_reply_stubbed"))
                
                let pushTimeoutBinding = eventBindings("chan_reply_stubbed")
                expect(pushTimeoutBinding).to(haveCount(1))
                
                expect(channel.pushBuffer).to(haveCount(1))
                expect(channel.pushBuffer[0].event).to(equal(push.event))
            })
        }
        
        //----------------------------------------------------------------------
        // MARK: - Internals
        //----------------------------------------------------------------------
        describe(".isMember(message:)") {
            it("should return false if the member's topic does not match the channel's topic", closure: {
                let message = Message(topic: "other_topic")
                expect(channel.isMember(message)).to(beFalse())
            })
            
            it("should return false if isLifecycleEvent and joinRefs are not equal", closure: {
                channel.joinPush.ref = "join_ref_1"
                let message = Message(topic: "topic", event: ChannelEvent.join, joinRef: "join_ref_2")
                expect(channel.isMember(message)).to(beFalse())
            })
            
            it("should return true if the message belongs in the channel", closure: {
                let message = Message(topic: "topic", event: "test_event")
                expect(channel.isMember(message)).to(beTrue())
            })
        }

        
        describe(".sendJoin()") {
            
        }
        
        describe(".trigger(message:)") {
            it("sends the message to the appropiate event binding", closure: {
                channel.onMessage({ (message) -> Message in
                    message.payload["other_number"] = 2
                    return message
                })
                
                
                var onTestEventCalled = false
                channel.on("test_event", callback: { (message) in
                    onTestEventCalled = true
                    expect(message.ref).to(equal("ref"))
                    expect(message.topic).to(equal("topic"))
                    expect(message.event).to(equal("test_event"))
                    expect(message.payload["number"] as? Int).to(equal(1))
                    expect(message.payload["other_number"] as? Int).to(equal(2))
                })
                
                let message = Message(ref: "ref", topic: "topic", event: "test_event", payload: ["number": 1])
                channel.trigger(message)
                expect(onTestEventCalled).to(beTrue())
            })
        }

        describe("canPush") {
            it("returns true if joined and connected", closure: {
                channel.state = .joined
                mockSocket.isConnected = true
                expect(channel.canPush).to(beTrue())
                
                channel.state = .joined
                mockSocket.isConnected = false
                expect(channel.canPush).to(beFalse())
                
                channel.state = .joining
                mockSocket.isConnected = true
                expect(channel.canPush).to(beFalse())
            })
        }
        
        
        describe("isClosed") {
            it("returns true if state is .closed", closure: {
                channel.state = .joined
                expect(channel.isClosed).to(beFalse())
                
                channel.state = .closed
                expect(channel.isClosed).to(beTrue())
            })
        }
        
        describe("isErrored") {
            it("returns true if state is .errored", closure: {
                channel.state = .joined
                expect(channel.isErrored).to(beFalse())
                
                channel.state = .errored
                expect(channel.isErrored).to(beTrue())
            })
        }
        
        describe("isJoined") {
            it("returns true if state is .joined", closure: {
                channel.state = .leaving
                expect(channel.isJoined).to(beFalse())
                
                channel.state = .joined
                expect(channel.isJoined).to(beTrue())
            })
        }
        
        describe("isJoining") {
            it("returns true if state is .joining", closure: {
                channel.state = .joined
                expect(channel.isJoining).to(beFalse())
                
                channel.state = .joining
                expect(channel.isJoining).to(beTrue())
            })
        }
        
        describe("isLeaving") {
            it("returns true if state is .leaving", closure: {
                channel.state = .joined
                expect(channel.isLeaving).to(beFalse())
                
                channel.state = .leaving
                expect(channel.isLeaving).to(beTrue())
            })
        }
        
    }
}
