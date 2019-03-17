//
//  TestHelpers.swift
//  SwiftPhoenixClientTests
//
//  Created by Daniel Rees on 2/24/19.
//

@testable import SwiftPhoenixClient

class Helpers {
//    static func wrapSyncStateWithNilCallbacks(_ state: Presence.PresenceState, newState: Presence.PresenceState) -> Presence.PresenceState {
//        return Presence.syncState(state, newState: newState, onJoin: nil, onLeave: nil)
//    }
//
//    static func wrapSyncDiffWithNilCallbacks(_ state: Presence.PresenceState, diff: Presence.Diff) -> Presence.PresenceState {
//        return Presence.syncDiff(state, diff: diff, onJoin: nil, onLeave: nil)
//    }
}

enum TestError: Error {
    case stub
}

func toWebSocketText(data: [String: Any]) -> String {
    let encoded = Defaults.encode(data)
    return String(decoding: encoded, as: UTF8.self)
}
