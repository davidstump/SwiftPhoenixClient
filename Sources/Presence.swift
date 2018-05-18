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
  // MARK: - Convenience typealiases
  
  public typealias PresenceState = [String: [Meta]]
  public typealias Diff = [String: [String: [Meta]]]
  public typealias Meta = [String: AnyObject]
  
  // MARK: - Properties
  
  private(set) public var state: PresenceState
  
  // MARK: - Callbacks
  
  public var onJoin: ((_ id: String, _ meta: Meta) -> ())?
  public var onLeave: ((_ id: String, _ meta: Meta) -> ())?
  public var onStateChange: ((_ state: PresenceState) -> ())?
  
  // MARK: - Initialisation
  
  init(state: PresenceState) {
    self.state = state
  }
  
  // MARK: - Syncing
  
  func sync(diff: Message) {
    // Initial state event
    if diff.event == "presence_state" {
      diff.payload.forEach{ id, entry in
        if let entry = entry as? [String: [Meta]] {
          state[id] = entry["metas"]
        }
      }
    }
    else if diff.event == "presence_diff" {
      if let leaves = diff.payload["leaves"] as? Diff {
        syncLeaves(diff: leaves)
      }
      if let joins = diff.payload["joins"] as? Diff {
        syncJoins(diff: joins)
      }
    }
    
    onStateChange?(state)
  }
  
  func syncLeaves(diff: Diff) {
    defer {
      diff.forEach { id, entry in
        if let metas = entry["metas"] {
          metas.forEach { onLeave?(id, $0) }
        }
      }
    }
    
    for (id, entry) in diff where state[id] != nil {
      guard var existing = state[id] else {
        continue
      }
      
      // If there's only one entry for the id, just remove it.
      if existing.count == 1 {
        state.removeValue(forKey: id)
        continue
      }
      
      // Otherwise, we need to find the phx_ref keys to delete.
      let refsToDelete = entry["metas"]?.map { $0["phx_ref"] as! String }
      existing = existing.filter { !refsToDelete!.contains($0["phx_ref"]! as! String) }
      state[id] = existing
    }
  }
  
  func syncJoins(diff: Diff) {
    diff.forEach { id, entry in
      let metas = entry["metas"]
      
      if var existing = state[id] {
        existing += metas!
      }
      else {
        state[id] = metas
      }
      
      metas?.forEach { onJoin?(id, $0) }
    }
  }
  
  // MARK: - Presence access convenience
  
  public func metas(id: String) -> [Meta]? {
    return state[id]
  }
  
  public func firstMeta(id: String) -> Meta? {
    return state[id]?.first
  }
  
  public func firstMetas() -> [String: Meta] {
    var result = [String: Meta]()
    state.forEach { id, metas in
      result[id] = metas.first
    }
    
    return result
  }
  
  public func firstMetaValue<T>(id: String, key: String) -> T? {
    guard let meta = state[id]?.first, let value = meta[key] as? T else {
      return nil
    }
    
    return value
  }
  
  public func firstMetaValues<T>(key: String) -> [T] {
    var result = [T]()
    state.forEach { id, metas in
      if let meta = metas.first, let value = meta[key] as? T {
        result.append(value)
      }
    }
    
    return result
  }
}
