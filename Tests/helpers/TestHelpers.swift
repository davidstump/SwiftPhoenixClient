//
//  TestHelpers.swift
//  SwiftPhoenixClientTests
//
//  Created by Daniel Rees on 2/24/19.
//

import Foundation
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


/// Transforms two Dictionaries into NSDictionaries so they can be conpared
func transform(_ lhs: [AnyHashable: Any],
               and rhs: [AnyHashable: Any]) -> (lhs: NSDictionary, rhs: NSDictionary) {
  return (NSDictionary(dictionary: lhs), NSDictionary(dictionary: rhs))
}


extension Channel {
  /// Utility method to easily filter the bindings for a channel by their event
  func getBindings(_ event: String) -> [Binding]? {
    return self.bindingsDel.filter({ $0.event == event })
  }
}
