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
    
    let listByFirst: (_ key: String, _ presence: Presence.Map) -> Presence.Meta
      = { key, pres in
        return pres["metas"]!.first!
    }
    
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
      channel.joinPush.ref = "1"
      
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
      
      it("syncs state and diffs", closure: {
        let user1: Presence.Map = ["metas": [["id": 1, "phx_ref": "1"]]]
        let user2: Presence.Map = ["metas": [["id": 2, "phx_ref": "2"]]]
        let newState: Presence.State = ["u1": user1, "u2": user2]
        
        
        channel.trigger(event: "presence_state",
                        payload: newState,
                        ref: "1")
        let s = presence.list(by: listByFirst)
        expect(s).to(haveCount(2))
        // can't check values because maps are lazy
        //                expect(s[0]["id"] as? Int).to(equal(1))
        //                expect(s[0]["phx_ref"] as? String).to(equal("1"))
        //
        //                expect(s[1]["id"] as? Int).to(equal(2))
        //                expect(s[1]["phx_ref"] as? String).to(equal("2"))
        
        channel.trigger(event: "presence_diff",
                        payload: ["joins": [:], "leaves": ["u1": user1]],
                        ref: "2")
        
        let l = presence.list(by: listByFirst)
        expect(l).to(haveCount(1))
        expect(l[0]["id"] as? Int).to(equal(2))
        expect(l[0]["phx_ref"] as? String).to(equal("2"))
      })
      
      it("applies pending diff if state is not yet synced", closure: {
        var onJoins: [(id: String, current: Presence.Map?, new: Presence.Map)] = []
        var onLeaves: [(id: String, current: Presence.Map, left: Presence.Map)] = []
        
        presence.onJoin({ (key, current, new) in
          onJoins.append((key, current, new))
        })
        
        presence.onLeave({ (key, current, left) in
          onLeaves.append((key, current, left))
        })
        
        let user1 = ["metas": [["id": 1, "phx_ref": "1"]]]
        let user2 = ["metas": [["id": 2, "phx_ref": "2"]]]
        let user3 = ["metas": [["id": 3, "phx_ref": "3"]]]
        
        let newState = ["u1": user1, "u2": user2]
        let leaves = ["u2": user2]
        
        let payload1 = ["joins": [:], "leaves": leaves]
        channel.trigger(event: "presence_diff", payload: payload1, ref: "")
        
        // there is no state
        expect(presence.list(by: listByFirst)).to(beEmpty())
        
        // pending diffs 1
        expect(presence.pendingDiffs).to(haveCount(1))
        expect(presence.pendingDiffs[0]["joins"]).to(beEmpty())
        let t1 = transform(presence.pendingDiffs[0]["leaves"]!, and: leaves)
        expect(t1.lhs).to(equal(t1.rhs))
        
        
        channel.trigger(event: "presence_state", payload: newState, ref: "")
        expect(onLeaves).to(haveCount(1))
        expect(onLeaves[0].id).to(equal("u2"))
        expect(onLeaves[0].current["metas"]).to(beEmpty())
        expect(onLeaves[0].left["metas"]?[0]["id"] as? Int).to(equal(2))
        
        
        let s = presence.list(by: listByFirst)
        expect(s).to(haveCount(1))
        expect(s[0]["id"] as? Int).to(equal(1))
        expect(s[0]["phx_ref"] as? String).to(equal("1"))
        expect(presence.pendingDiffs).to(beEmpty())
        
        expect(onJoins).to(haveCount(2))
        // can't check values because maps are lazy
        //                expect(onJoins[0].id).to(equal("u1"))
        //                expect(onJoins[0].current).to(beNil())
        //                expect(onJoins[0].new["metas"]?[0]["id"] as? Int).to(equal(1))
        //
        //                expect(onJoins[1].id).to(equal("u2"))
        //                expect(onJoins[1].current).to(beNil())
        //                expect(onJoins[1].new["metas"]?[0]["id"] as? Int).to(equal(2))
        
        
        // disconnect then reconnect
        expect(presence.isPendingSyncState).to(beFalse())
        channel.joinPush.ref = "2"
        expect(presence.isPendingSyncState).to(beTrue())
        
        
        channel.trigger(event: "presence_diff",
                        payload: ["joins": [:], "leaves": ["u1": user1]],
                        ref: "")
        let d = presence.list(by: listByFirst)
        expect(d).to(haveCount(1))
        expect(d[0]["id"] as? Int).to(equal(1))
        expect(d[0]["phx_ref"] as? String).to(equal("1"))
        
        channel.trigger(event: "presence_state",
                        payload: ["u1": user1, "u3": user3],
                        ref: "")
        let s2 = presence.list(by: listByFirst)
        expect(s2).to(haveCount(1))
        expect(s2[0]["id"] as? Int).to(equal(3))
        expect(s2[0]["phx_ref"] as? String).to(equal("3"))
        
      })
      
      
      it("allows custom states", closure: {
        let channel = Channel(topic: "topic", socket: mockSocket)
        channel.joinPush.ref = "1"
        let customOptions
          = Presence.Options(events: [.state: "the_state",
                                      .diff: "the_diff"])
        let presence = Presence(channel: channel, opts: customOptions)
        
        
        let user1: Presence.Map = ["metas": [["id": 1, "phx_ref": "1"]]]
        channel.trigger(event: "the_state", payload: ["user1": user1], ref: "")
        
        let s = presence.list(by: listByFirst)
        expect(s).to(haveCount(1))
        expect(s[0]["id"] as? Int).to(equal(1))
        expect(s[0]["phx_ref"] as? String).to(equal("1"))
        
        channel.trigger(event: "the_diff",
                        payload: ["joins": [:], "leaves": ["user1": user1]],
                        ref: "2")
        
        expect(presence.list(by: listByFirst)).to(beEmpty())
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
        var joined: Presence.Diff = [:]
        var left: Presence.Diff = [:]
        let onJoin: Presence.OnJoin = { key, current, newPres in
          var state: Presence.State = ["newPres": newPres]
          if let c = current {
            state["current"] = c
          }
          
          // Diff = [String: Presence.State]
          joined[key] = state
        }
        
        let onLeave: Presence.OnLeave = { key, current, leftPres in
          // Diff = [String: Presence.State]
          left[key] = ["current": current, "leftPres": leftPres]
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
        
        // assert equality in joined
        let joinedExpectation: Presence.Diff = [
          "u1": ["newPres": ["metas": [["id":1, "phx_ref": "1"]] ]],
          "u2": ["newPres": ["metas": [["id":2, "phx_ref": "2"]] ]],
          "u3": ["newPres": ["metas": [["id":3, "phx_ref": "3"]] ]]
        ]
        let tJoin = transform(joined, and: joinedExpectation)
        expect(tJoin.lhs).to(equal(tJoin.rhs))
        
        // assert equality in left
        let leftExpectation: Presence.Diff = ["u4": [
          "current": ["metas": [] ],
          "leftPres": ["metas": [["id":4, "phx_ref": "4"]] ]
          ] ]
        let tLeft = transform(left, and: leftExpectation)
        expect(tLeft.lhs).to(equal(tLeft.rhs))
      })
      
      
      it("onJoins only newly added metas", closure: {
        var state = ["u3": ["metas": [["id":3, "phx_ref": "3"]]]]
        let newState = ["u3": [
          "metas": [["id":3, "phx_ref": "3"], ["id":3, "phx_ref": "3.new"]]
          ]]
        
        var joined: Presence.Diff = [:]
        var left: Presence.Diff = [:]
        let onJoin: Presence.OnJoin = { key, current, newPres in
          var state: Presence.State = ["newPres": newPres]
          if let c = current {
            state["current"] = c
          }
          
          // Diff = [String: Presence.State]
          joined[key] = state
        }
        
        let onLeave: Presence.OnLeave = { key, current, leftPres in
          // Diff = [String: Presence.State]
          left[key] = ["current": current, "leftPres": leftPres]
        }
        
        state = Presence.syncState(state, newState: newState,
                                   onJoin: onJoin, onLeave: onLeave)
        let t2 = transform(state, and: newState)
        expect(t2.lhs).to(equal(t2.rhs))
        
        // assert equality in joined
        let joinedExpectation: Presence.Diff = [
          "u3": ["current": ["metas": [["id":3, "phx_ref": "3"]] ],
                 "newPres": ["metas": [["id":3, "phx_ref": "3.new"]] ]
          ]
        ]
        
        let tJoin = transform(joined, and: joinedExpectation)
        expect(tJoin.lhs).to(equal(tJoin.rhs))
        
        // assert equality in left
        expect(left).to(beEmpty())
      })
      
      it("onLeaves only newly removed metas", closure: {
        let newState = ["u3": ["metas": [["id":3, "phx_ref": "3"]]]]
        var state = ["u3": [
          "metas": [["id":3, "phx_ref": "3"], ["id":3, "phx_ref": "3.left"]]
          ]]
        
        var joined: Presence.Diff = [:]
        var left: Presence.Diff = [:]
        let onJoin: Presence.OnJoin = { key, current, newPres in
          var state: Presence.State = ["newPres": newPres]
          if let c = current {
            state["current"] = c
          }
          
          // Diff = [String: Presence.State]
          joined[key] = state
        }
        
        let onLeave: Presence.OnLeave = { key, current, leftPres in
          // Diff = [String: Presence.State]
          left[key] = ["current": current, "leftPres": leftPres]
        }
        
        state = Presence.syncState(state, newState: newState,
                                   onJoin: onJoin, onLeave: onLeave)
        let t2 = transform(state, and: newState)
        expect(t2.lhs).to(equal(t2.rhs))
        
        // assert equality in joined
        let leftExpectation: Presence.Diff = [
          "u3": ["current": ["metas": [["id":3, "phx_ref": "3"]] ],
                 "leftPres": ["metas": [["id":3, "phx_ref": "3.left"]] ]
          ]
        ]
        
        let tLeft = transform(left, and: leftExpectation)
        expect(tLeft.lhs).to(equal(tLeft.rhs))
        
        // assert equality in left
        expect(joined).to(beEmpty())
      })
      
      it("syncs both joined and left metas", closure: {
        let newState = ["u3": [
          "metas": [["id":3, "phx_ref": "3"], ["id":3, "phx_ref": "3.new"]]
          ]]
        var state = ["u3": [
          "metas": [["id":3, "phx_ref": "3"], ["id":3, "phx_ref": "3.left"]]
          ]]
        
        var joined: Presence.Diff = [:]
        var left: Presence.Diff = [:]
        let onJoin: Presence.OnJoin = { key, current, newPres in
          var state: Presence.State = ["newPres": newPres]
          if let c = current {
            state["current"] = c
          }
          
          // Diff = [String: Presence.State]
          joined[key] = state
        }
        
        let onLeave: Presence.OnLeave = { key, current, leftPres in
          // Diff = [String: Presence.State]
          left[key] = ["current": current, "leftPres": leftPres]
        }
        
        state = Presence.syncState(state, newState: newState,
                                   onJoin: onJoin, onLeave: onLeave)
        let t2 = transform(state, and: newState)
        expect(t2.lhs).to(equal(t2.rhs))
        
        // assert equality in joined
        let joinedExpectation: Presence.Diff = [
          "u3": ["current": ["metas": [["id":3, "phx_ref": "3"], ["id":3, "phx_ref": "3.left"]] ],
                 "newPres": ["metas": [["id":3, "phx_ref": "3.new"]] ]
          ]
        ]
        
        let tJoin = transform(joined, and: joinedExpectation)
        expect(tJoin.lhs).to(equal(tJoin.rhs))
        
        // assert equality in left
        let leftExpectation: Presence.Diff = [
          "u3": ["current": ["metas": [["id":3, "phx_ref": "3"], ["id":3, "phx_ref": "3.new"]] ],
                 "leftPres": ["metas": [["id":3, "phx_ref": "3.left"]] ]
          ]
        ]
        
        let tLeft = transform(left, and: leftExpectation)
        expect(tLeft.lhs).to(equal(tLeft.rhs))
      })
    }
    
    describe("syncDiff") {
      it("syncs empty state", closure: {
        let joins: Presence.State = ["u1": ["metas": [["id":1, "phx_ref": "1"]]]]
        var state: Presence.State = [:]
        
        Presence.syncDiff(state, diff: ["joins": joins, "leaves": [:]])
        expect(state).to(beEmpty())
        
        state = Presence.syncDiff(state, diff: ["joins": joins, "leaves": [:]])
        let t1 = transform(state, and: joins)
        expect(t1.lhs).to(equal(t1.rhs))
      })
      
      it("removes presence when meta is empty and adds additional meta", closure: {
        var state = fixState
        let diff: Presence.Diff = ["joins": fixJoins, "leaves": fixLeaves]
        state = Presence.syncDiff(state, diff: diff)
        
        let expectation: Presence.State = [
          "u1": ["metas": [
            ["id":1, "phx_ref": "1"],
            ["id":1, "phx_ref": "1.2"]]
          ],
          "u3": ["metas": [["id":3, "phx_ref": "3"]] ]
        ]
        
        let t1 = transform(state, and: expectation)
        expect(t1.lhs).to(equal(t1.rhs))
      })
      
      it("removes meta while leaving key if other metas exist", closure: {
        var state: Presence.State = [
          "u1": ["metas": [
            ["id":1, "phx_ref": "1"],
            ["id":1, "phx_ref": "1.2"]]
          ]]
        
        let leaves: Presence.State = ["u1": ["metas": [["id":1, "phx_ref": "1"]]]]
        let diff: Presence.Diff = ["joins": [:], "leaves": leaves]
        state = Presence.syncDiff(state, diff: diff)
      })
    }
  }
}
