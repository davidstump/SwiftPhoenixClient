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
        
        /// Mocks
        var mockSocket: SocketMock!
        var onCloseCalledCount: Int!
        var onErrorCalledCount: Int!
        
        
        /// UUT
        var channel: Channel!
        var presence: Presence!
        
        beforeEach {
            mockSocket = SocketMock()
            channel = Channel(topic: "topic", params: ["one": 2], socket: mockSocket)
            presence = Presence(channel: channel)
        }
        
        /// Utility method to easily filter the bindings for a channel by their event
        func eventBindings(_ event: String) -> [(event: String, ref: Int, callback: (Message) -> Void)]? {
            return channel.bindings.filter( { $0.event == event } )
        }
        
        describe(".init(channel:, options:)") {
            it("sets defaults") {
                expect(presence.joinRef).to(beNil())
                expect(presence.state).to(beEmpty())
                expect(presence.pendingDiffs).to(beEmpty())
                expect(presence.onJoin).to(beNil())
                expect(presence.onLeave).to(beNil())
                expect(presence.onSync).to(beNil())
                expect(channel.bindings.filter { $0.event == "presence_state" }).to(haveCount(1))
                expect(channel.bindings.filter { $0.event == "presence_diff" }).to(haveCount(1))
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
        }
    }
}
