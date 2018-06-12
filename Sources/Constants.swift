//
//  Constants.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 4/27/18.
//


/// Default timeout when making a connection set to 10 seconds
public let PHOENIX_DEFAULT_TIMEOUT: Int = 10000

/// Default heartbeat interval set to 30 seconds
public let PHOENIX_DEFAULT_HEARTBEAT: Int = 30000



/// Represents the multiple states that a Channel can be in
/// throughout it's lifecycle.
public enum ChannelState: String {
    case closed = "closed"
    case errored = "errored"
    case joined = "joined"
    case joining = "joining"
    case leaving = "leaving"
}

public enum SocketState: String {
    case connecting = "connecting"
    case open = "open"
    case closing = "closing"
    case closed = "closed"
}

/// Represents the different events that can be sent through
/// a channel regarding a Channel's lifecycle.
public struct ChannelEvent {
    public static let heartbeat = "heartbeat"
    public static let join      = "phx_join"
    public static let leave     = "phx_leave"
    public static let reply     = "phx_reply"
    public static let error     = "phx_error"
    public static let close     = "phx_close"
    
    static func isLifecyleEvent(_ event: String) -> Bool {
        switch event {
        case join, leave, reply, error, close: return true
        default: return false
        }
    }
}



