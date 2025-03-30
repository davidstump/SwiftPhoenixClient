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
    
    static let fixState: Presence.State = [
        "u1": ["metas": [["id":1, "phx_ref": "1"]]],
        "u2": ["metas": [["id":2, "phx_ref": "2"]]],
        "u3": ["metas": [["id":3, "phx_ref": "3"]]]
    ]
    
    @Suite("syncState")
    struct SyncStateSuite {
        
        /// Fixtures
        let fixJoins: Presence.State = ["u1": ["metas": [["id":1, "phx_ref": "1.2"]]]]
        let fixLeaves: Presence.State = ["u2": ["metas": [["id":2, "phx_ref": "2"]]]]
        
        
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
    
    @Suite("list")
    struct ListSuite {
        
        @Test("lists full presence by default")
        func byDefault() async throws {
            let list = Presence.list(fixState).sorted { first, second in
                let firstId = (first["metas"]!.first!["id"] as! Int)
                let secondId = (second["metas"]!.first!["id"] as! Int)
                return firstId < secondId
            }
            
            #expect((list[0]["metas"]![0]["id"] as! Int) == 1)
            #expect((list[0]["metas"]![0]["phx_ref"] as! String) == "1")
            
            #expect((list[1]["metas"]![0]["id"] as! Int) == 2)
            #expect((list[1]["metas"]![0]["phx_ref"] as! String) == "2")
            
            #expect((list[2]["metas"]![0]["id"] as! Int) == 3)
            #expect((list[2]["metas"]![0]["phx_ref"] as! String) == "3")
        }
        
        @Test("lists with custom function")
        func withCustomFucntion() async throws {
            let state = [
                "u1": [
                    "metas": [
                        [
                            "id": 1,
                            "phx_ref": "1.first"
                        ],
                        [
                            "id": 1,
                            "phx_ref": "1.second"
                        ]
                    ]
                ]
            ]
            let list = Presence.listBy(state) { key, map in
                return map.first?.value.first
            }
            
            #expect(list.first!!["id"] as! Int == 1)
            #expect(list.first!!["phx_ref"] as! String == "1.first")
        }
    }
    
    @Suite("instance")
    struct InstanceSuite {
        let listByFirst: (_ key: String, _ presence: Presence.Map) -> Presence.Meta
        = { key, pres in
            return pres["metas"]!.first!
        }
        
        let channel: Channel
        
        init() {
            let socket = SocketSpy("/socket") { _ in TransportMock() }
            channel = socket.channel("topic")
            channel.joinPush.ref = "1"
        }
        
        @Test("syncs state and diffs")
        func syncsStateAndDiffs() async throws {
            let presence = Presence(channel: channel)
            let user1: Presence.Map = ["metas": [["id": 1, "phx_ref": "1"]]]
            let user2: Presence.Map = ["metas": [["id": 2, "phx_ref": "2"]]]
            let newState: Presence.State = ["u1": user1, "u2": user2]
            
            let incomingPresenceState = buildIncomingJsonMessage(ref: "1",
                                                                 event: "presence_state",
                                                                 jsonPayload: newState)
            channel.trigger(incomingPresenceState)
            var s = presence.list(by: listByFirst)
            #expect(s.count == 2)
            s.sort { first, second in
                return (first["id"] as! Int) < (second["id"] as! Int)
            }
            
            #expect((s[0]["id"] as! Int) == 1)
            #expect((s[0]["phx_ref"] as! String) == "1")
            #expect((s[1]["id"] as! Int) == 2)
            #expect((s[1]["phx_ref"] as! String) == "2")
            
            
            
            let diffJson = ["joins": [:], "leaves": ["u1": user1]]
            let incomingPresenceDiff = buildIncomingJsonMessage(ref: "2",
                                                                event: "presence_diff",
                                                                jsonPayload: diffJson)
            
            channel.trigger(incomingPresenceDiff)
            let l = presence.list(by: listByFirst)
            #expect(l.count == 1)
            #expect((l[0]["id"] as! Int) == 2)
            #expect((l[0]["phx_ref"] as! String) == "2")
        }
        
        @Test("applies pending diff if state is not yet synced")
        func appliesPendingDiffIfNotSynced() async throws {
            var onJoins: [(id: String, current: Presence.Map?, new: Presence.Map)] = []
            var onLeaves: [(id: String, current: Presence.Map, left: Presence.Map)] = []
            
            let presence = Presence(channel: channel)
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
            channel.trigger(buildIncomingJsonMessage(event: "presence_diff",
                                                     jsonPayload: payload1))
            
            // there is no state
            #expect(presence.list(by: listByFirst).isEmpty)
            
            // pending diffs 1
            #expect(presence.pendingDiffs.count == 1)
            #expect(presence.pendingDiffs[0]["joins"]?.isEmpty == true)
            let t1 = transform(presence.pendingDiffs[0]["leaves"]!, and: leaves)
            #expect(t1.lhs == t1.rhs)
            
            channel.trigger(buildIncomingJsonMessage(event: "presence_state",
                                                     jsonPayload: newState))
            #expect(onLeaves.count == 1)
            #expect(onLeaves[0].id == "u2")
            #expect(onLeaves[0].current["metas"]?.isEmpty == true)
            #expect(onLeaves[0].left["metas"]?[0]["id"] as? Int == 2)
            
            let s = presence.list(by: listByFirst)
            #expect(s.count == 1)
            #expect(s[0]["id"] as? Int == 1)
            #expect(s[0]["phx_ref"] as? String == "1")
            #expect(presence.pendingDiffs.isEmpty)
            
            #expect(onJoins.count == 2)
            onJoins.sort { first, second in
                return first.id < second.id
            }
            // can't check values because maps are lazy
            #expect(onJoins[0].id == "u1")
            #expect(onJoins[0].current == nil)
            #expect(onJoins[0].new["metas"]?[0]["id"] as? Int == 1)
            
            #expect(onJoins[1].id == "u2")
            #expect(onJoins[1].current == nil)
            #expect(onJoins[1].new["metas"]?[0]["id"] as? Int == 2)
            
            
            // disconnect then reconnect
            #expect(presence.isPendingSyncState == false)
            channel.joinPush.ref = "2"
            #expect(presence.isPendingSyncState == true)
            
            
            channel.trigger(buildIncomingJsonMessage(
                event: "presence_diff",
                jsonPayload: ["joins": [:], "leaves": ["u1": user1]]))
            
            let d = presence.list(by: listByFirst)
            #expect(d.count == 1)
            #expect(d[0]["id"] as? Int == 1)
            #expect(d[0]["phx_ref"] as? String == "1")
            
            channel.trigger(buildIncomingJsonMessage(event: "presence_state",
                                                     jsonPayload: ["u1": user1, "u3": user3]))
            
            let s2 = presence.list(by: listByFirst)
            #expect(s2.count == 1)
            #expect(s2[0]["id"] as? Int == 3)
            #expect(s2[0]["phx_ref"] as? String == "3")
        }
        
        @Test("allows custom channel events")
        func allowsCustomEvents() async throws {
            let customOptions = Presence.Options(
                events: [.state: "the_state", .diff: "the_diff"])
            let p = Presence(channel: channel, opts: customOptions)
            
            #expect(p.channel?.getChannelSubscription("presence_state").isEmpty == true)
            #expect(p.channel?.getChannelSubscription("presence_diff").isEmpty == true)
            
            #expect(p.channel?.getChannelSubscription("the_state").count == 1)
            #expect(p.channel?.getChannelSubscription("the_diff").count == 1)
            
            
            let user1: Presence.Map = ["metas": [["id": 1, "phx_ref": "1"]]]
            let theState = buildIncomingJsonMessage(event: "the_state",
                                                    jsonPayload: ["user1": user1])
            channel.trigger(theState)
            
            
            let s = p.list(by: listByFirst)
            #expect(s.count == 1)
            #expect(s[0]["id"] as? Int == 1)
            #expect(s[0]["phx_ref"] as? String == "1")
            
            let theDiff = buildIncomingJsonMessage(event: "the_diff",
                                                   jsonPayload: ["joins": [:], "leaves": ["user1": user1]])
            channel.trigger(theDiff)
            #expect(p.list(by: listByFirst).isEmpty)
        }
        
        @Test("updates existing meta for a presence update (leave + join)")
        func updatesExistingMeta() async throws {
            
        }
    }
    
}
