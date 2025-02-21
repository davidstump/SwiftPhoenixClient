//
//  PresenceTest.swift
//  SwiftPhoenixClientTests
//
//  Created by Daniel Rees on 2/21/25.
//  Copyright © 2025 SwiftPhoenixClient. All rights reserved.
//

import Testing
@testable import SwiftPhoenixClient

@Suite("Presence")
struct PresenceTest {
    
    @Suite("syncState")
    struct SyncStateSuite {
        
        /// Fixtures
        let fixJoins: Presence.State = ["u1": ["metas": [["id":1, "phx_ref": "1.2"]]]]
        let fixLeaves: Presence.State = ["u2": ["metas": [["id":2, "phx_ref": "2"]]]]
        let fixState: Presence.State = [
            "u1": ["metas": [["id":1, "phx_ref": "1"]]],
            "u2": ["metas": [["id":2, "phx_ref": "2"]]],
            "u3": ["metas": [["id":3, "phx_ref": "3"]]]
        ]
        
        @Test("syncs empty state")
        func syncsEmptyState() async throws {
            let newState: Presence.State = ["u1": ["metas": [["id":1, "phx_ref": "1"]]]]
            var state: Presence.State = [:]
            let stateBefore = state
            
            Presence.syncState(state, newState: newState)
            
            let t1 = transform(state, and: stateBefore)
            #expect(t1.lhs == t1.rhs)
            
            state = Presence.syncState(state, newState: newState)
            let t2 = transform(state, and: newState)
            #expect(t2.lhs == t2.rhs)
        }
        
        
        @Test("onJoins new presences and onLeave's left presences")
        func onJoinsNewPresncesAndOnLeavesLeftPrecenses() async throws {
            
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
            #expect(t1.lhs == t1.rhs)
            
            state = Presence.syncState(state, newState: newState,
                                       onJoin: onJoin, onLeave: onLeave)
            let t2 = transform(state, and: newState)
            #expect(t2.lhs == t2.rhs)
            
            // assert equality in joined
            let joinedExpectation: Presence.Diff = [
                "u1": ["newPres": ["metas": [["id":1, "phx_ref": "1"]] ]],
                "u2": ["newPres": ["metas": [["id":2, "phx_ref": "2"]] ]],
                "u3": ["newPres": ["metas": [["id":3, "phx_ref": "3"]] ]]
            ]
            let tJoin = transform(joined, and: joinedExpectation)
            #expect(tJoin.lhs == tJoin.rhs)
            
            // assert equality in left
            let leftExpectation: Presence.Diff = ["u4": [
                "current": ["metas": [] ],
                "leftPres": ["metas": [["id":4, "phx_ref": "4"]] ]
            ] ]
            let tLeft = transform(left, and: leftExpectation)
            #expect(tLeft.lhs == tLeft.rhs)
        }
        
        @Test("onJoins only newly added metas")
        func onlyNewlyAddedMetas() async throws {
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
            #expect(t2.lhs == t2.rhs)
            
            // assert equality in joined
            let joinedExpectation: Presence.Diff = [
                "u3": ["current": ["metas": [["id":3, "phx_ref": "3"]] ],
                       "newPres": ["metas": [["id":3, "phx_ref": "3.new"]] ]
                      ]
            ]
            
            let tJoin = transform(joined, and: joinedExpectation)
            #expect(tJoin.lhs == tJoin.rhs)
            
            // assert equality in left
            #expect(left.isEmpty)
        }
        
        @Test("syncs both joined and left metas")
        func syncsBothJoinedAndLeftMetas() async throws {
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
            #expect(t2.lhs == t2.rhs)
            
            // assert equality in joined
            let joinedExpectation: Presence.Diff = [
                "u3": ["current": ["metas": [["id":3, "phx_ref": "3"], ["id":3, "phx_ref": "3.left"]] ],
                       "newPres": ["metas": [["id":3, "phx_ref": "3.new"]] ]
                      ]
            ]
            
            let tJoin = transform(joined, and: joinedExpectation)
            #expect(tJoin.lhs == tJoin.rhs)
            
            // assert equality in left
            let leftExpectation: Presence.Diff = [
                "u3": ["current": ["metas": [["id":3, "phx_ref": "3"], ["id":3, "phx_ref": "3.new"]] ],
                       "leftPres": ["metas": [["id":3, "phx_ref": "3.left"]] ]
                      ]
            ]
            
            let tLeft = transform(left, and: leftExpectation)
            #expect(tLeft.lhs == tLeft.rhs)
        }
    }
    
    @Suite("syncDiff")
    struct SyncDiffSuite {
        
        /// Fixtures
        let fixJoins: Presence.State = ["u1": ["metas": [["id":1, "phx_ref": "1.2"]]]]
        let fixLeaves: Presence.State = ["u2": ["metas": [["id":2, "phx_ref": "2"]]]]
        let fixState: Presence.State = [
            "u1": ["metas": [["id":1, "phx_ref": "1"]]],
            "u2": ["metas": [["id":2, "phx_ref": "2"]]],
            "u3": ["metas": [["id":3, "phx_ref": "3"]]]
        ]
        
        @Test("syncs empty state")
        func syncsEmptyState() async throws {
            let joins: Presence.State = ["u1": ["metas": [["id":1, "phx_ref": "1"]]]]
            var state: Presence.State = [:]
            
            Presence.syncDiff(state, diff: ["joins": joins, "leaves": [:]])
            #expect(state.isEmpty)
            
            state = Presence.syncDiff(state, diff: ["joins": joins, "leaves": [:]])
            let t1 = transform(state, and: joins)
            #expect(t1.lhs == t1.rhs)
        }
        
        @Test("removes presence when meta is empty and adds additional meta")
        func removesPresenceWhenMetaIsEmptyAndAddsAdditionalMeta() async throws {
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
            #expect(t1.lhs == t1.rhs)
        }
        
        @Test("removes meta while leaving key if other metas exist")
        func removesMetaWhileLeavingKeyIfOtherMetasExist() async throws {
            var state: Presence.State = [
                "u1": ["metas": [
                    ["id":1, "phx_ref": "1"],
                    ["id":1, "phx_ref": "1.2"]]
                      ]]
            
            let leaves: Presence.State = ["u1": ["metas": [["id":1, "phx_ref": "1"]]]]
            let diff: Presence.Diff = ["joins": [:], "leaves": leaves]
            state = Presence.syncDiff(state, diff: diff)
        }
    }
    
    @Suite("instance")
    struct InstanceSuite {
        let listByFirst: (_ key: String, _ presence: Presence.Map) -> Presence.Meta
        = { key, pres in
            return pres["metas"]!.first!
        }
        
        @Test("syncs state and diffs")
        func syncsStateAndDiffs() async throws {
            let channel = ChannelSpy()
            let presence = Presence(channel: channel)
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
        }
    }
    
}
