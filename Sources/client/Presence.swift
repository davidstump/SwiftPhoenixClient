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
  
  
  //----------------------------------------------------------------------
  // MARK: - Enums, Structs, and typealiases
  //----------------------------------------------------------------------
  /// Presense Events
  public enum Events: String {
    case state = "state"
    case diff = "diff"
  }
  
  /// Meta details of a Presence. Just a dictionary of properties
  public typealias Meta = [String: Any]
  
  /// A mapping of a String to an array of Metas. e.g. {"metas": [{id: 1}]}
  public typealias Map = [String: [Meta]]
  
  /// A mapping of a Presence state to a mapping of Metas
  public typealias State = [String: Map]
  
  // Diff has keys "joins" and "leaves", pointing to a Presence.State each
  // containing the users that joined and left.
  public typealias Diff = [String: State]
  
  /// Custom options that can be provided when creating Presence
  public struct Options {
    let events: [Events: String]
    
    /// Default set of Options used when creating Presence
    static public let defaults
      = Options(events: [.state: "presence_state",
                         .diff: "presence_diff"])
  }
  
  /// Closure signature of OnJoin callbacks
  public typealias OnJoin = (_ key: String, _ current: Map?, _ new: Map) -> Void
  
  /// Closure signature for OnLeave callbacks
  public typealias OnLeave = (_ key: String, _ current: Map, _ left: Map) -> Void
  
  //// Closure signature for OnSync callbacks
  public typealias OnSync = () -> Void
  
  /// Collection of callbacks with default values
  struct Caller {
    var onJoin: OnJoin = {_,_,_ in }
    var onLeave: OnLeave = {_,_,_ in }
    var onSync: OnSync = {}
  }
  
  
  //----------------------------------------------------------------------
  // MARK: - Properties
  //----------------------------------------------------------------------
  /// The channel the Presence belongs to
  weak var channel: Channel?
  
  /// Caller to callback hooks
  var caller: Caller
  
  /// The state of the Presence
  private(set) public var state: State
  
  /// Pending `join` and `leave` diffs that need to be synced
  private(set) public var pendingDiffs: [Diff]
  
  /// The channel's joinRef, set when state events occur
  private(set) public var joinRef: String?
  
  
  
//  static let phx_ref = "phx_ref"
//  static let diff_joins = "joins"
//  static let diff_leaves = "leaves"
//
//  static public let defaultOptions = PresenceOptions(events: [PresenceEventType.state: "presence_state", PresenceEventType.diff: "presence_diff"])
//
//  // MARK: - Enum declarations and classes
//  public enum PresenceEventType: String {
//    case state = "state", diff = "diff"
//  }
//
//  public struct PresenceOptions {
//    let events: [PresenceEventType: String]
//  }
  
  // MARK: - Convenience typealiases
//  public typealias PresenceMap = [String: Array<Meta>]
//  public typealias PresenceState = [String: PresenceMap]
  // Diff has keys "joins" and "leaves", pointing to a PresenceState each
  // containing the users that joined and left, respectively...
  
//  public typealias Meta = [String: Any]
//  public typealias OnJoinCallback = ((_ key: String, _ currentPresence: PresenceMap?, _ newPresence: PresenceMap) -> Void)?
//  public typealias OnLeaveCallback = ((_ key: String, _ currentPresence: PresenceMap, _ leftPresence: PresenceMap) -> Void)?
//  public typealias OnSync = (() -> ())?

//  public typealias ListBy = (_ key: String, _ presence: PresenceMap) -> Any

  public var isPendingSyncState: Bool {
    guard let safeJoinRef = self.joinRef else { return true }
    return safeJoinRef != self.channel?.joinRef
  }
  
  /// Callback to be informed of joins
  public var onJoin: OnJoin {
    get { return caller.onJoin }
    set { caller.onJoin = newValue }
  }
  
  /// Callback to be informed of leaves
  public var onLeave: OnLeave {
    get { return caller.onLeave }
    set { caller.onLeave = newValue }
  }
  
  /// Callback to be informed of synces
  public var onSync: OnSync {
    get { return caller.onSync }
    set { caller.onSync = newValue }
  }
  
  
  public init(channel: Channel, opts: Options = Options.defaults) {
    self.state = [:]
    self.pendingDiffs = []
    self.channel = channel
    self.joinRef = nil
    self.caller = Caller()
    
    guard // Do not subscribe to events if they were not provided
      let stateEvent = opts.events[.state],
      let diffEvent = opts.events[.diff] else { return }
    
    
    self.channel?.delegateOn(stateEvent, to: self) { (self, message) in
      guard let newState = message.payload as? State else { return }
      
      self.joinRef = self.channel?.joinRef
      self.state = Presence.syncState(self.state,
                                      newState: newState,
                                      onJoin: self.caller.onJoin,
                                      onLeave: self.caller.onLeave)
      
      self.pendingDiffs.forEach({ (diff) in
        self.state = Presence.syncDiff(self.state,
                                       diff: diff,
                                       onJoin: self.caller.onJoin,
                                       onLeave: self.caller.onLeave)
      })
      
      self.pendingDiffs = []
      self.caller.onSync()
    }

    self.channel?.delegateOn(diffEvent, to: self) { (self, message) in
      guard let diff = message.payload as? Diff else { return }
      if self.isPendingSyncState {
        self.pendingDiffs.append(diff)
      } else {
        self.state = Presence.syncDiff(self.state,
                                       diff: diff,
                                       onJoin: self.caller.onJoin,
                                       onLeave: self.caller.onLeave)
        self.caller.onSync()
      }
    }
  }
  
//  // MARK: - Initialisation
//  public convenience init(channel: Channel) {
//    self.init(channel: channel, options: Presence.defaultOptions)
//  }
//
//  public init(channel: Channel, options: PresenceOptions) {
//    self.channel = channel
//    self.state = [:]
//    self.options = options
//    if let state = self.options.events[PresenceEventType.state] {
//      channel.delegateOn(state, to: self) { (self, message) in
//        if let newState = message.payload as? PresenceState {
//          self.joinRef = channel.joinRef
//          self.state = Presence.syncState(self.state, newState: newState, onJoin: self.onJoin, onLeave: self.onLeave)
//
//          for diff in self.pendingDiffs {
//            self.state = Presence.syncDiff(self.state, diff: diff, onJoin: self.onJoin, onLeave: self.onLeave)
//          }
//          self.pendingDiffs = []
//          if let onSync = self.onSync {
//            onSync()
//          }
//        }
//      }
//    }
//    if let diff = self.options.events[PresenceEventType.diff] {
//      channel.delegateOn(diff, to: self) { (self, message) in
//        if let diff = message.payload as? Diff {
//          if self.isPendingSyncState {
//            self.pendingDiffs.append(diff)
//          } else {
//            self.state = Presence.syncDiff(self.state, diff: diff, onJoin: self.onJoin, onLeave: self.onLeave)
//            if let onSync = self.onSync {
//              onSync()
//            }
//          }
//        }
//      }
//    }
//  }
  
  
  //----------------------------------------------------------------------
  // MARK: - Static
  //----------------------------------------------------------------------
  
  // Used to sync the list of presences on the server
  // with the client's state. An optional `onJoin` and `onLeave` callback can
  // be provided to react to changes in the client's local presences across
  // disconnects and reconnects with the server.
  //
  // - returns: Presence.State
  @discardableResult
  public static func syncState(_ currentState: State,
                               newState: State,
                               onJoin: OnJoin = {_,_,_ in },
                               onLeave: OnLeave = {_,_,_ in }) -> State {
    let state = currentState
    var leaves = state.filter { (key, _) -> Bool in
      !newState.contains(where: { $0.key == key })
    }
    
    var joins = newState.filter { (key, _) -> Bool in
      !state.contains(where: { $0.key == key })
    }
    
    newState.forEach { (key, newPresence) in
      guard let currentPresence = state[key] else { return }
      
      let newRefs = newPresence["meta"]!.map({ $0["phx_ref"] as! String })
      let curRefs = currentPresence["meta"]!.map({ $0["phx_ref"] as! String })
      
      let joinedMetas = newPresence["meta"]!.filter({ (meta: Meta) -> Bool in
        curRefs.contains { $0 == meta["phx_ref"] as! String }
      })
      let leftMetas = currentPresence["metas"]!.filter({ (meta: Meta) -> Bool in
        newRefs.contains { $0 == meta["phx_ref"] as! String }
      })
  
      if joinedMetas.count > 0 {
        joins[key] = ["metas": joinedMetas]
      }
      
      if leftMetas.count > 0 {
        leaves[key] = ["metas": leftMetas]
      }
    }

    return Presence.syncDiff(state,
                             diff: ["joins": joins, "leaves": leaves],
                             onJoin: onJoin,
                             onLeave: onLeave)
  }
  
  
  // Used to sync a diff of presence join and leave
  // events from the server, as they happen. Like `syncState`, `syncDiff`
  // accepts optional `onJoin` and `onLeave` callbacks to react to a user
  // joining or leaving from a device.
  //
  // - returns: Presence.State
  public static func syncDiff(_ currentState: State,
                              diff: Diff,
                              onJoin: OnJoin = {_,_,_ in },
                              onLeave: OnLeave = {_,_,_ in }) -> State {
    var state = currentState
    diff["joins"]?.forEach { (key, newPresence) in
      let currentPresence = state[key]
      state[key] = newPresence
      
      if let curPresence = currentPresence {
        let joinedRefs = state[key]!["metas"]!.map({ $0["phx_ref"] as! String })
        let curMetas = curPresence["metas"]!.filter { (meta: Meta) -> Bool in
          joinedRefs.contains { $0 == meta["phx_ref"] as! String }
        }
        state[key]!["metas"]!.append(contentsOf: curMetas)
      }
      
      onJoin(key, currentPresence, newPresence)
    }
    
    diff["leaves"]?.forEach({ (key, leftPresence) in
      guard let curPresence = state[key] else { return }
      let refsToRemove = leftPresence["metas"]!.map { $0["phx_ref"] as! String }
      let keepMetas = curPresence["metas"]!.filter { (meta: Meta) -> Bool in
        !refsToRemove.contains { $0 == meta["phx_ref"] as! String }
      }

      onLeave(key, curPresence, leftPresence)

      if keepMetas.count > 0 {
        state[key]!["metas"] = keepMetas
      } else {
        state.removeValue(forKey: key)
      }
    })
    
    return state
  }
  
  
//  public static func list(_ state: State, chooser: ()
  
  
  
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
//  static public func syncState(_ pState: PresenceState, newState pNewState: PresenceState,
//                   onJoin pOnJoin: OnJoinCallback, onLeave pOnLeave: OnLeaveCallback) -> PresenceState {
//    var state = pState
//    var leaves = pState.filter { (key, value) -> Bool in
//      !pNewState.contains(where: { $0.key == key })
//    }
//    var joins = pNewState.filter { (key, value) -> Bool in
//      !pState.contains(where: { $0.key == key })
//    }
//
//    pNewState.forEach { (key: String, newPresence: PresenceMap) in
//      // Looking for differences in metadata of already present users.
//      if let currentPresence = state[key] {
//        let curRefs = currentPresence["metas"]!.map { $0[phx_ref] as! String }
//        let newMetas = newPresence["metas"]!.filter({ (meta: Meta) -> Bool in
//          curRefs.contains { $0 == meta[phx_ref] as! String }
//        })
//        if newMetas.count > 0 {
//          joins[key] = ["metas": newMetas]
//        }
//
//        let newRefs = newPresence["metas"]!.map { $0[phx_ref] as! String }
//        let leftMetas = currentPresence["metas"]!.filter({ (meta: Meta) -> Bool in
//          newRefs.contains { $0 == meta[phx_ref] as! String }
//        })
//        if leftMetas.count > 0 {
//          leaves[key] = ["metas": leftMetas]
//        }
//      }
//    }
//
//    return Presence.syncDiff(state, diff: [diff_joins: joins, diff_leaves: leaves], onJoin: pOnJoin, onLeave: pOnLeave)
//  }
  
//  static public func syncDiff(_ pState: PresenceState, diff: Diff,
//                       onJoin pOnJoin: OnJoinCallback, onLeave pOnLeave: OnLeaveCallback) -> PresenceState {
//    var state = pState
//    guard let joins = diff[diff_joins],
//      let leaves = diff[diff_leaves]
//      else {
//        // TODO: Do something about this or just force cast instead of guard?
//        return [:]
//    }
//
//    for (key, newPresence) in joins {
//      let currentPresence: PresenceMap? = state[key]
//      state[key] = newPresence
//      if currentPresence != nil {
//        let joinedRefs = state[key]!["metas"]!.map { $0[phx_ref] as! String }
//        let curMetas = currentPresence!["metas"]!.filter { (meta: Meta) -> Bool in
//          joinedRefs.contains { $0 == meta[phx_ref] as! String }
//        }
//        state[key]!["metas"]!.append(contentsOf: curMetas)
//      }
//      if let onJoin = pOnJoin {
//        onJoin(key, currentPresence, newPresence)
//      }
//    }
//
//    for (key, leftPresence) in leaves {
//      if let currentPresence = state[key] {
//        let refsToRemove = leftPresence["metas"]!.map { $0[phx_ref] as! String }
//        let keepMetas = currentPresence["metas"]!.filter { (meta: Meta) -> Bool in
//          !refsToRemove.contains { $0 == meta[phx_ref] as! String }
//        }
//
//        if let onLeave = pOnLeave {
//          onLeave(key, currentPresence, leftPresence)
//        }
//        if keepMetas.count > 0 {
//          state[key]!["metas"] = keepMetas
//        } else {
//          state.removeValue(forKey: key)
//        }
//      }
//    }
//
//    return state
//  }
  
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
