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

//

  public var isPendingSyncState: Bool {
    guard let safeJoinRef = self.joinRef else { return true }
    return safeJoinRef != self.channel?.joinRef
  }
  
  /// Callback to be informed of joins
  public var onJoin: OnJoin {
    get { return caller.onJoin }
    set { caller.onJoin = newValue }
  }
  
  /// Set the OnJoin callback
  public func onJoin(_ callback: @escaping OnJoin) {
    self.onJoin = callback
  }
  
  /// Callback to be informed of leaves
  public var onLeave: OnLeave {
    get { return caller.onLeave }
    set { caller.onLeave = newValue }
  }
  
  /// Set the OnLeave callback
  public func onLeave(_ callback: @escaping OnLeave) {
    self.onLeave = callback
  }
  
  /// Callback to be informed of synces
  public var onSync: OnSync {
    get { return caller.onSync }
    set { caller.onSync = newValue }
  }
  
  /// Set the OnSync callback
  public func onSync(_ callback: @escaping OnSync) {
    self.onSync = callback
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
  
  /// Returns the array of presences, with deault selected metadata.
  public func list() -> [Map] {
    return self.list(by: { _, pres in pres })
  }
  
  /// Returns the array of presences, with selected metadata
  public func list<T>(by transformer: (String, Map) -> T) -> [T] {
    return Presence.listBy(self.state, transformer: transformer)
  }
  
  /// Filter the Presence state with a given function
  public func filter(by filter: ((String, Map) -> Bool)?) -> State {
    return Presence.filter(self.state, by: filter)
  }

  
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
    var leaves: Presence.State = [:]
    var joins: Presence.State = [:]

    state.forEach { (key, presence) in
      if newState[key] == nil {
        leaves[key] = presence
      }
    }

    newState.forEach { (key, newPresence) in
      if let currentPresence = state[key] {
        let newRefs = newPresence["metas"]!.map({ $0["phx_ref"] as! String })
        let curRefs = currentPresence["metas"]!.map({ $0["phx_ref"] as! String })
        
        let joinedMetas = newPresence["metas"]!.filter({ (meta: Meta) -> Bool in
          !curRefs.contains { $0 == meta["phx_ref"] as! String }
        })
        let leftMetas = currentPresence["metas"]!.filter({ (meta: Meta) -> Bool in
          !newRefs.contains { $0 == meta["phx_ref"] as! String }
        })
    
        
        if joinedMetas.count > 0 {
          joins[key] = newPresence
          joins[key]!["metas"] = joinedMetas
        }
        
        if leftMetas.count > 0 {
          leaves[key] = currentPresence
          leaves[key]!["metas"] = leftMetas
        }
      } else {
        joins[key] = newPresence
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
  @discardableResult
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
          !joinedRefs.contains { $0 == meta["phx_ref"] as! String }
        }
        state[key]!["metas"]!.insert(contentsOf: curMetas, at: 0)
      }
      
      onJoin(key, currentPresence, newPresence)
    }
    
    diff["leaves"]?.forEach({ (key, leftPresence) in
      guard var curPresence = state[key] else { return }
      let refsToRemove = leftPresence["metas"]!.map { $0["phx_ref"] as! String }
      let keepMetas = curPresence["metas"]!.filter { (meta: Meta) -> Bool in
        !refsToRemove.contains { $0 == meta["phx_ref"] as! String }
      }
      
      curPresence["metas"] = keepMetas
      onLeave(key, curPresence, leftPresence)

      if keepMetas.count > 0 {
        state[key]!["metas"] = keepMetas
      } else {
        state.removeValue(forKey: key)
      }
    })
    
    return state
  }
  
  public static func filter(_ presences: State,
                            by filter: ((String, Map) -> Bool)?) -> State {
    let safeFilter = filter ?? { key, pres in true }
    return presences.filter(safeFilter)
  }
  
  public static func listBy<T>(_ presences: State,
                               transformer: (String, Map) -> T) -> [T] {
    return presences.map(transformer)
  }
}
