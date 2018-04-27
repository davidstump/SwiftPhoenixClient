//
//  Constants.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 4/27/18.
//


/// Default timeout when making a connection set to 10 seconds
public let PHOENIX_DEFAULT_TIMEOUT: Int = 10000

/// Represents the multiple states that a Channel can be in
/// throughout it's lifecycle.
public enum ChannelState: String {
    case closed = "closed"
    case errored = "errored"
    case joined = "joined"
    case joining = "joining"
    case leaving = "leaving"
}

/// Represents the different events that can be sent through
/// a channel regarding a Channel's lifecycle.
public struct ChannelEvent {
    static let heartbeat = "heartbeat"
    static let join      = "phx_join"
    static let leave     = "phx_leave"
    static let reply     = "phx_reply"
    static let error     = "phx_error"
    static let close     = "phx_close"
}



