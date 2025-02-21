////
////  PresenceSpec.swift
////  SwiftPhoenixClient
////
////  Created by Simon Bergström on 2018-10-03.
////
//
//import Quick
//import Nimble
//@testable import SwiftPhoenixClient
//
//class PresenceSpec: QuickSpec {
//  
//  override func spec() {
//    
//    /// Fixtures
//    let fixJoins: Presence.State = ["u1": ["metas": [["id":1, "phx_ref": "1.2"]]]]
//    let fixLeaves: Presence.State = ["u2": ["metas": [["id":2, "phx_ref": "2"]]]]
//    let fixState: Presence.State = [
//      "u1": ["metas": [["id":1, "phx_ref": "1"]]],
//      "u2": ["metas": [["id":2, "phx_ref": "2"]]],
//      "u3": ["metas": [["id":3, "phx_ref": "3"]]]
//    ]
//    
//    let listByFirst: (_ key: String, _ presence: Presence.Map) -> Presence.Meta
//      = { key, pres in
//        return pres["metas"]!.first!
//    }
//    
//    /// Mocks
//    var mockSocket: SocketMock!
//    var channel: Channel!
//    
//    /// UUT
//    var presence: Presence!
//    
//    beforeEach {
//      let mockTransport = PhoenixTransportMock()
//      mockSocket = SocketMock(endPoint: "/socket", transport: { _ in mockTransport })
//      mockSocket.timeout = 10.0
//      mockSocket.makeRefReturnValue = "1"
//      mockSocket.reconnectAfter = { _ in return 1 }
//      
//      channel = Channel(topic: "topic", params: [:], socket: mockSocket)
//      channel.joinPush.ref = "1"
//      
//      presence = Presence(channel: channel)
//    }
//    
//    
//    describe("init") {
//      
//      it("sets defaults", closure: {
//        expect(presence.state).to(beEmpty())
//        expect(presence.pendingDiffs).to(beEmpty())
//        expect(presence.channel === channel).to(beTrue())
//        expect(presence.joinRef).to(beNil())
//      })
//      
//      it("binds to channel with default options", closure: {
//        expect(presence.channel?.getBindings("presence_state")).to(haveCount(1))
//        expect(presence.channel?.getBindings("presence_diff")).to(haveCount(1))
//      })
//      
//      it("binds to channel with custom options ", closure: {
//        let channel = Channel(topic: "topic", socket: mockSocket)
//        let customOptions
//          = Presence.Options(events: [.state: "custom_state",
//                                      .diff: "custom_diff"])
//        let p = Presence(channel: channel, opts: customOptions)
//        
//        expect(p.channel?.getBindings("presence_state")).to(beEmpty())
//        expect(p.channel?.getBindings("presence_diff")).to(beEmpty())
//        expect(p.channel?.getBindings("custom_state")).to(haveCount(1))
//        expect(p.channel?.getBindings("custom_diff")).to(haveCount(1))
//      })
//      
//      it("syncs state and diffs", closure: {
//        let user1: Presence.Map = ["metas": [["id": 1, "phx_ref": "1"]]]
//        let user2: Presence.Map = ["metas": [["id": 2, "phx_ref": "2"]]]
//        let newState: Presence.State = ["u1": user1, "u2": user2]
//        
//        
//        channel.trigger(event: "presence_state",
//                        payload: newState,
//                        ref: "1")
//        let s = presence.list(by: listByFirst)
//        expect(s).to(haveCount(2))
//        // can't check values because maps are lazy
//        //                expect(s[0]["id"] as? Int).to(equal(1))
//        //                expect(s[0]["phx_ref"] as? String).to(equal("1"))
//        //
//        //                expect(s[1]["id"] as? Int).to(equal(2))
//        //                expect(s[1]["phx_ref"] as? String).to(equal("2"))
//        
//        channel.trigger(event: "presence_diff",
//                        payload: ["joins": [:], "leaves": ["u1": user1]],
//                        ref: "2")
//        
//        let l = presence.list(by: listByFirst)
//        expect(l).to(haveCount(1))
//        expect(l[0]["id"] as? Int).to(equal(2))
//        expect(l[0]["phx_ref"] as? String).to(equal("2"))
//      })
//      
//      it("applies pending diff if state is not yet synced", closure: {
//        var onJoins: [(id: String, current: Presence.Map?, new: Presence.Map)] = []
//        var onLeaves: [(id: String, current: Presence.Map, left: Presence.Map)] = []
//        
//        presence.onJoin({ (key, current, new) in
//          onJoins.append((key, current, new))
//        })
//        
//        presence.onLeave({ (key, current, left) in
//          onLeaves.append((key, current, left))
//        })
//        
//        let user1 = ["metas": [["id": 1, "phx_ref": "1"]]]
//        let user2 = ["metas": [["id": 2, "phx_ref": "2"]]]
//        let user3 = ["metas": [["id": 3, "phx_ref": "3"]]]
//        
//        let newState = ["u1": user1, "u2": user2]
//        let leaves = ["u2": user2]
//        
//        let payload1 = ["joins": [:], "leaves": leaves]
//        channel.trigger(event: "presence_diff", payload: payload1, ref: "")
//        
//        // there is no state
//        expect(presence.list(by: listByFirst)).to(beEmpty())
//        
//        // pending diffs 1
//        expect(presence.pendingDiffs).to(haveCount(1))
//        expect(presence.pendingDiffs[0]["joins"]).to(beEmpty())
//        let t1 = transform(presence.pendingDiffs[0]["leaves"]!, and: leaves)
//        expect(t1.lhs).to(equal(t1.rhs))
//        
//        
//        channel.trigger(event: "presence_state", payload: newState, ref: "")
//        expect(onLeaves).to(haveCount(1))
//        expect(onLeaves[0].id).to(equal("u2"))
//        expect(onLeaves[0].current["metas"]).to(beEmpty())
//        expect(onLeaves[0].left["metas"]?[0]["id"] as? Int).to(equal(2))
//        
//        
//        let s = presence.list(by: listByFirst)
//        expect(s).to(haveCount(1))
//        expect(s[0]["id"] as? Int).to(equal(1))
//        expect(s[0]["phx_ref"] as? String).to(equal("1"))
//        expect(presence.pendingDiffs).to(beEmpty())
//        
//        expect(onJoins).to(haveCount(2))
//        // can't check values because maps are lazy
//        //                expect(onJoins[0].id).to(equal("u1"))
//        //                expect(onJoins[0].current).to(beNil())
//        //                expect(onJoins[0].new["metas"]?[0]["id"] as? Int).to(equal(1))
//        //
//        //                expect(onJoins[1].id).to(equal("u2"))
//        //                expect(onJoins[1].current).to(beNil())
//        //                expect(onJoins[1].new["metas"]?[0]["id"] as? Int).to(equal(2))
//        
//        
//        // disconnect then reconnect
//        expect(presence.isPendingSyncState).to(beFalse())
//        channel.joinPush.ref = "2"
//        expect(presence.isPendingSyncState).to(beTrue())
//        
//        
//        channel.trigger(event: "presence_diff",
//                        payload: ["joins": [:], "leaves": ["u1": user1]],
//                        ref: "")
//        let d = presence.list(by: listByFirst)
//        expect(d).to(haveCount(1))
//        expect(d[0]["id"] as? Int).to(equal(1))
//        expect(d[0]["phx_ref"] as? String).to(equal("1"))
//        
//        channel.trigger(event: "presence_state",
//                        payload: ["u1": user1, "u3": user3],
//                        ref: "")
//        let s2 = presence.list(by: listByFirst)
//        expect(s2).to(haveCount(1))
//        expect(s2[0]["id"] as? Int).to(equal(3))
//        expect(s2[0]["phx_ref"] as? String).to(equal("3"))
//        
//      })
//      
//      
//      it("allows custom states", closure: {
//        let channel = Channel(topic: "topic", socket: mockSocket)
//        channel.joinPush.ref = "1"
//        let customOptions
//          = Presence.Options(events: [.state: "the_state",
//                                      .diff: "the_diff"])
//        let presence = Presence(channel: channel, opts: customOptions)
//        
//        
//        let user1: Presence.Map = ["metas": [["id": 1, "phx_ref": "1"]]]
//        channel.trigger(event: "the_state", payload: ["user1": user1], ref: "")
//        
//        let s = presence.list(by: listByFirst)
//        expect(s).to(haveCount(1))
//        expect(s[0]["id"] as? Int).to(equal(1))
//        expect(s[0]["phx_ref"] as? String).to(equal("1"))
//        
//        channel.trigger(event: "the_diff",
//                        payload: ["joins": [:], "leaves": ["user1": user1]],
//                        ref: "2")
//        
//        expect(presence.list(by: listByFirst)).to(beEmpty())
//      })
//    }
//  }
//}
