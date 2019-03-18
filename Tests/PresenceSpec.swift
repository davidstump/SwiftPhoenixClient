//
//  PresenceSpec.swift
//  SwiftPhoenixClient
//
//  Created by Simon Bergström on 2018-10-03.
//

import Quick
import Nimble
@testable import SwiftPhoenixClient

class PresenceSpec: QuickSpec {
    
    override func spec() {
        
        /// Fixtures
        let fixJoins: Presence.State = ["u1": ["metas": [["id":1, "phx_ref": "1.2"]]]]
        let fixLeaves: Presence.State = ["u2": ["metas": [["id":2, "phx_ref": "2"]]]]
        let fixState: Presence.State = [
            "u1": ["metas": [["id":1, "phx_ref": "1"]]],
            "u2": ["metas": [["id":2, "phx_ref": "2"]]],
            "u3": ["metas": [["id":3, "phx_ref": "3"]]]
        ]
        
        /// Mocks
        var mockSocket: SocketMock!
        var channel: Channel!
        
        /// UUT
        var presence: Presence!
        
        beforeEach {
            let mockClient = WebSocketClientMock()
            mockSocket = SocketMock("/socket")
            mockSocket.connection = mockClient
            mockSocket.timeout = 10.0
            mockSocket.makeRefReturnValue = "1"
            mockSocket.reconnectAfter = { _ in return 1 }
            
            channel = Channel(topic: "topic", params: [:], socket: mockSocket)
            presence = Presence(channel: channel)
        }
        
        
        describe("init") {

            it("sets defaults", closure: {
                expect(presence.state).to(beEmpty())
                expect(presence.pendingDiffs).to(beEmpty())
                expect(presence.channel === channel).to(beTrue())
                expect(presence.joinRef).to(beNil())
            })

            it("binds to channel with default options", closure: {
                expect(presence.channel?.getBindings("presence_state")).to(haveCount(1))
                expect(presence.channel?.getBindings("presence_diff")).to(haveCount(1))
            })

            it("binds to channel with custom options ", closure: {
                let channel = Channel(topic: "topic", socket: mockSocket)
                let customOptions
                    = Presence.Options(events: [.state: "custom_state",
                                                .diff: "custom_diff"])
                let p = Presence(channel: channel, opts: customOptions)
                
                expect(p.channel?.getBindings("presence_state")).to(beEmpty())
                expect(p.channel?.getBindings("presence_diff")).to(beEmpty())
                expect(p.channel?.getBindings("custom_state")).to(haveCount(1))
                expect(p.channel?.getBindings("custom_diff")).to(haveCount(1))
            })
        }
        
        
        describe("syncState") {
            it("syncs empty state", closure: {
                let newState: Presence.State = ["u1": ["metas": [["id":1, "phx_ref": "1"]]]]
                var state: Presence.State = [:]
                let stateBefore = state
                
                Presence.syncState(state, newState: newState)
                
                let t1 = transform(state, and: stateBefore)
                expect(t1.lhs).to(equal(t1.rhs))

                state = Presence.syncState(state, newState: newState)
                let t2 = transform(state, and: newState)
                expect(t2.lhs).to(equal(t2.rhs))
            })
            
            it("onJoins new presences and onLeave's left presences", closure: {
                let newState = fixState
                var state = ["u4": ["metas": [["id":4, "phx_ref": "4"]]]]
                var joined: Presence.State = [:]
                var left: Presence.State = [:]
                let onJoin: Presence.OnJoin = { key, current, newPres in
                    curren
                    joined[key] = ["current": current!, "newPres": newPres]
                }
                
                let onLeave: Presence.OnLeave = { key, current, leftPres in
                    left[key] = ["current": current, "leftPres": leftPres]!
                }
                
                let stateBefore = state
                Presence.syncState(state, newState: newState,
                                   onJoin: onJoin, onLeave: onLeave)
                let t1 = transform(state, and: stateBefore)
                expect(t1.lhs).to(equal(t1.rhs))
                
                state = Presence.syncState(state, newState: newState,
                                           onJoin: onJoin, onLeave: onLeave)
                let t2 = transform(state, and: newState)
                expect(t2.lhs).to(equal(t2.rhs))
                

                
            })
        }
        
        
        
        
        
        
        
        
//            it("handle initial state") {
//                expect(mockSocket.pushCallsCount).to(equal(0))
//                channel.join()
//                    .receive("ok") { _ in
//                        print("kekler - ok")
//                    }
//                    .receive("error") { (message: SwiftPhoenixClient.Message) in
//                        print("kekler - error")
//                }
//                channel.joinedOnce = true
//                mockSocket.push(topic: "topic", event: "presence_state", payload: [:], ref: nil, joinRef: nil)
//                expect(mockSocket.pushCallsCount).to(equal(2))
//                expect(presence.state).to(beEmpty())
//                let diff: Payload = [
//                    "leaves": [:],
//                    "joins":
//                        ["uuid":
//                            ["metas":
//                                [
//                                    ["phx_ref": "ref", "connected_at":"1538637530"]
//                                ]
//                            ]
//                        ]
//                ]
//                mockSocket.push(topic: "topic", event: "presence_diff", payload: diff, ref: nil, joinRef: nil)
//                expect(mockSocket.pushCallsCount).to(equal(2))
//                expect(presence.state).to(haveCount(1))
//            }
//        }
    }
}
