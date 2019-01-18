//
//  Presence.swift
//  SwiftPhoenixClient
//
//  All the credit in the world to the Birdsong repo for a good swift
//  implementation of Presence. Please check out that repo/library for
//  a good Swift Channels alternative
//
//  Created by Simon Manning on 6/07/2016.
//
//

import Foundation

public final class Presence {
  static let phx_ref = "phx_ref"
  static let diff_joins = "joins"
  static let diff_leaves = "leaves"
  
  static public let defaultOptions = PresenceOptions(events: [PresenceEventType.state: "presence_state", PresenceEventType.diff: "presence_diff"])

  // MARK: - Enum declarations and classes
  public enum PresenceEventType: String {
    case state = "state", diff = "diff"
  }
  
  public struct PresenceOptions {
    let events: [PresenceEventType: String]
  }
  
  // MARK: - Convenience typealiases
  public typealias PresenceMap = [String: Array<Meta>]
  public typealias PresenceState = [String: PresenceMap]
  // Diff has keys "joins" and "leaves", pointing to a PresenceState each
  // containing the users that joined and left, respectively...
  public typealias Diff = [String: PresenceState]
  public typealias Meta = [String: Any]
  public typealias OnJoinCallback = ((_ key: String, _ currentPresence: PresenceMap?, _ newPresence: PresenceMap) -> Void)?
  public typealias OnLeaveCallback = ((_ key: String, _ currentPresence: PresenceMap, _ leftPresence: PresenceMap) -> Void)?
  public typealias OnSync = (() -> ())?

  public typealias ListBy = (_ key: String, _ presence: PresenceMap) -> Any

  // MARK: - Properties
  public let channel: Channel
  
  private(set) public var joinRef: String? = nil
  private(set) public var pendingDiffs: Array<Diff> = []
  private(set) public var state: PresenceState
  private(set) public var options: PresenceOptions
  
  public var isPendingSyncState: Bool { return joinRef == nil || joinRef != self.channel.joinRef }
  
  // MARK: - Callbacks
  public var onJoin: OnJoinCallback
  public var onLeave: OnLeaveCallback
  public var onSync: OnSync
  
  // MARK: - Initialisation
  public convenience init(channel: Channel) {
    self.init(channel: channel, options: Presence.defaultOptions)
  }
  
  public init(channel: Channel, options: PresenceOptions) {
    self.channel = channel
    self.state = [:]
    self.options = options
    if let state = self.options.events[PresenceEventType.state] {
      channel.on(state) { (message: Message) in
        if let newState = message.payload as? PresenceState {
          self.joinRef = channel.joinRef
          self.state = Presence.syncState(self.state, newState: newState, onJoin: self.onJoin, onLeave: self.onLeave)

          for diff in self.pendingDiffs {
            self.state = Presence.syncDiff(self.state, diff: diff, onJoin: self.onJoin, onLeave: self.onLeave)
          }
          self.pendingDiffs = []
          if let onSync = self.onSync {
            onSync()
          }
        }
      }
    }
    if let diff = self.options.events[PresenceEventType.diff] {
      channel.on(diff) { (message: Message) in
        if let diff = message.payload as? Diff {
          if self.isPendingSyncState {
            self.pendingDiffs.append(diff)
          } else {
            self.state = Presence.syncDiff(self.state, diff: diff, onJoin: self.onJoin, onLeave: self.onLeave)
            if let onSync = self.onSync {
              onSync()
            }
          }
        }
      }
    }
  }
  
  // MARK: - Syncing
  /**
   Used to sync the list of presences on the server
   with the client's state. An optional `onJoin` and `onLeave` callback can
   be provided to react to changes in the client's local presences across
   disconnects and reconnects with the server.
   
   - Parameter pState: the current PresenceState
   
   - Parameter pNewState: the new PresenceState sent from the server
   
   - Parameter pOnJoin: an optional callback for the client to react to new users joining

   - Parameter pOnLeave: an optional callback for the client to react to users leaving

   - Returns: A new PresenceState
   */
  static public func syncState(_ pState: PresenceState, newState pNewState: PresenceState,
                   onJoin pOnJoin: OnJoinCallback, onLeave pOnLeave: OnLeaveCallback) -> PresenceState {
    var state = pState
    var leaves = pState.filter { (key, value) -> Bool in
      !pNewState.contains(where: { $0.key == key })
    }
    var joins = pNewState.filter { (key, value) -> Bool in
      !pState.contains(where: { $0.key == key })
    }
    
    pNewState.forEach { (key: String, newPresence: PresenceMap) in
      // Looking for differences in metadata of already present users.
      if let currentPresence = state[key] {
        let curRefs = currentPresence["metas"]!.map { $0[phx_ref] as! String }
        let newMetas = newPresence["metas"]!.filter({ (meta: Meta) -> Bool in
          curRefs.contains { $0 == meta[phx_ref] as! String }
        })
        if newMetas.count > 0 {
          joins[key] = ["metas": newMetas]
        }
        
        let newRefs = newPresence["metas"]!.map { $0[phx_ref] as! String }
        let leftMetas = currentPresence["metas"]!.filter({ (meta: Meta) -> Bool in
          newRefs.contains { $0 == meta[phx_ref] as! String }
        })
        if leftMetas.count > 0 {
          leaves[key] = ["metas": leftMetas]
        }
      }
    }
    
    return Presence.syncDiff(state, diff: [diff_joins: joins, diff_leaves: leaves], onJoin: pOnJoin, onLeave: pOnLeave)
  }
  
  static public func syncDiff(_ pState: PresenceState, diff: Diff,
                       onJoin pOnJoin: OnJoinCallback, onLeave pOnLeave: OnLeaveCallback) -> PresenceState {
    var state = pState
    guard let joins = diff[diff_joins],
      let leaves = diff[diff_leaves]
      else {
        // TODO: Do something about this or just force cast instead of guard?
        return [:]
    }

    for (key, newPresence) in joins {
      let currentPresence: PresenceMap? = state[key]
      state[key] = newPresence
      if currentPresence != nil {
        let joinedRefs = state[key]!["metas"]!.map { $0[phx_ref] as! String }
        let curMetas = currentPresence!["metas"]!.filter { (meta: Meta) -> Bool in
          joinedRefs.contains { $0 == meta[phx_ref] as! String }
        }
        state[key]!["metas"]!.append(contentsOf: curMetas)
      }
      if let onJoin = pOnJoin {
        onJoin(key, currentPresence, newPresence)
      }
    }
    
    for (key, leftPresence) in leaves {
      if let currentPresence = state[key] {
        let refsToRemove = leftPresence["metas"]!.map { $0[phx_ref] as! String }
        let keepMetas = currentPresence["metas"]!.filter { (meta: Meta) -> Bool in
          !refsToRemove.contains { $0 == meta[phx_ref] as! String }
        }
        
        if let onLeave = pOnLeave {
          onLeave(key, currentPresence, leftPresence)
        }
        if keepMetas.count > 0 {
          state[key]!["metas"] = keepMetas
        } else {
          state.removeValue(forKey: key)
        }
      }
    }

    return state
  }
  
  // MARK: - Presence access convenience
  
//  public func metas(id: String) -> PresenceMap? {
//    return state[id]
//  }
//
//  public func firstMeta(id: String) -> PresenceMap? {
//    return state[id]?.first
//  }
//
//  public func firstMetas() -> [String: Meta] {
//    var result = [String: Meta]()
//    state.forEach { id, metas in
//      result[id] = metas.first
//    }
//
//    return result
//  }
//
//  public func firstMetaValue<T>(id: String, key: String) -> T? {
//    guard let meta = state[id]?.first, let value = meta[key] as? T else {
//      return nil
//    }
//
//    return value
//  }
//
//  public func firstMetaValues<T>(key: String) -> [T] {
//    var result = [T]()
//    state.forEach { id, metas in
//      if let meta = metas.first, let value = meta[key] as? T {
//        result.append(value)
//      }
//    }
//
//    return result
//  }
}
