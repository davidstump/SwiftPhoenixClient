//
//  Helpers.swift
//  SwiftPhoenixClientTests
//
//  Created by Simon Bergström on 2018-10-04.
//

@testable import SwiftPhoenixClient

class Helpers {
    static func wrapSyncStateWithNilCallbacks(_ state: Presence.PresenceState, newState: Presence.PresenceState) -> Presence.PresenceState {
        return Presence.syncState(state, newState: newState, onJoin: nil, onLeave: nil)
    }
    
    static func wrapSyncDiffWithNilCallbacks(_ state: Presence.PresenceState, diff: Presence.Diff) -> Presence.PresenceState {
        return Presence.syncDiff(state, diff: diff, onJoin: nil, onLeave: nil)
    }
}
