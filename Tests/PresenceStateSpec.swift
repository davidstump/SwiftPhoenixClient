//
//  PresenceSpec.swift
//  SwiftPhoenixClient
//
//  Created by Simon Bergström on 2018-10-03.
//

import Quick
import Nimble
@testable import SwiftPhoenixClient

class PresenceStateSpec: QuickSpec {
  static let firstId = "first"
  static let secondId = "second"
  
  override func spec() {
    
//    /// Constants
//    let emptyState: Presence.PresenceState = [:]
//    
//    let firstOnlineMap: Presence.PresenceMap = [
//      "metas": [
//        ["phx_ref": "ref one", "status": "online"]
//      ]
//    ]
//    let firstPresMap: Presence.PresenceMap = [
//      "metas": [
//        ["phx_ref": "ref two", "status": "online"],
//        ["phx_ref": "ref three", "available": true]
//      ]
//    ]
//    
//    let secondPresMap: Presence.PresenceMap = [
//      "metas": [
//        ["phx_ref": "ref four", "status": "offline"],
//        ["phx_ref": "ref five", "available": true]
//      ]
//    ]
//    
//    var stateWithOne: Presence.PresenceState!
//    var stateWithTwo: Presence.PresenceState!
//    
//    beforeEach {
//      stateWithOne = [PresenceStateSpec.firstId: firstPresMap]
//      stateWithTwo = [
//        PresenceStateSpec.firstId: firstPresMap,
//        PresenceStateSpec.secondId: secondPresMap
//      ]
//    }
//    
//    // Tests
//    describe("syncState without callbacks") {
//      it("empty state no change") {
//        let syncedState = Presence.syncState(emptyState, newState: [:], onJoin: nil, onLeave: nil)
//        expect(syncedState).to(beEmpty())
//      }
//      
//      it("empty state with one new") {
//        let newState = [PresenceStateSpec.firstId: firstOnlineMap]
//        let syncedState = Helpers.wrapSyncStateWithNilCallbacks(emptyState, newState: newState)
//        expect(syncedState).to(haveCount(1))
//      }
//      
//      it("state with one and it leaves") {
//        let syncedState = Helpers.wrapSyncStateWithNilCallbacks(stateWithOne, newState: [:])
//        expect(syncedState).to(haveCount(0))
//      }
//    }
//    
//    describe("syncState with callbacks") {
//      it("onJoin - empty state with one new") {
//        var calledCallback = false
//        let onJoinCallback: Presence.OnJoinCallback = { (key: String, currentPresence: Presence.PresenceMap?, newPresence: Presence.PresenceMap) in
//          calledCallback = true
//          expect(key).to(equal(PresenceStateSpec.firstId))
//          expect(currentPresence).to(beNil())
//          expect(newPresence["metas"]).to(haveCount(1))
//        }
//        
//        let syncedState = Presence.syncState(emptyState, newState: [PresenceStateSpec.firstId: firstOnlineMap], onJoin: onJoinCallback, onLeave: nil)
//        expect(syncedState).to(haveCount(1))
//        expect(calledCallback).to(beTrue())
//      }
//      
//      it("onJoin - two users and one changes status") {
//        var calledOnJoinCallback = false
//        var calledOnLeaveCallback = false
//        let onJoinCallback: Presence.OnJoinCallback = { (key: String, currentPresence: Presence.PresenceMap?, newPresence: Presence.PresenceMap) in
//          calledOnJoinCallback = true
//        }
//        
//        let onLeaveCallback: Presence.OnLeaveCallback = { (key: String, currentPresence: Presence.PresenceMap, leftPresence: Presence.PresenceMap) in
//          calledOnLeaveCallback = true
//          expect(currentPresence["metas"]!).to(haveCount(2))
//          expect(currentPresence["metas"]!.first!["phx_ref"] as? String).to(equal("ref four"))
//          expect(leftPresence["metas"]!).to(haveCount(1))
//          expect(leftPresence["metas"]!.first!["phx_ref"] as? String).to(equal("ref five"))
//        }
//        
//        let syncedState = Presence.syncDiff(stateWithTwo,
//                                            diff: ["joins": [:], "leaves": [PresenceStateSpec.secondId: [ "metas": [[ "phx_ref": "ref five", "available": true ]]]]],
//                                            onJoin: onJoinCallback, onLeave: onLeaveCallback)
//        expect(syncedState).to(haveCount(2))
//        expect(calledOnJoinCallback).to(beFalse())
//        expect(calledOnLeaveCallback).to(beTrue())
//      }
//      
//      it("onJoin - two users and one disappears") {
//        var calledOnJoinCallback = false
//        var calledOnLeaveCallback = false
//        let onJoinCallback: Presence.OnJoinCallback = { (key: String, currentPresence: Presence.PresenceMap?, newPresence: Presence.PresenceMap) in
//          calledOnJoinCallback = true
//        }
//        
//        let onLeaveCallback: Presence.OnLeaveCallback = { (key: String, currentPresence: Presence.PresenceMap, leftPresence: Presence.PresenceMap) in
//          calledOnLeaveCallback = true
//          expect(currentPresence["metas"]!).to(haveCount(2))
//          expect(leftPresence["metas"]!).to(haveCount(2))
//        }
//        
//        let syncedState = Presence.syncDiff(stateWithTwo,
//                                            diff: ["joins": [:], "leaves": [PresenceStateSpec.secondId: secondPresMap]],
//                                            onJoin: onJoinCallback, onLeave: onLeaveCallback)
//        expect(syncedState).to(haveCount(1))
//        expect(calledOnJoinCallback).to(beFalse())
//        expect(calledOnLeaveCallback).to(beTrue())
//      }
//    }
  }
}
