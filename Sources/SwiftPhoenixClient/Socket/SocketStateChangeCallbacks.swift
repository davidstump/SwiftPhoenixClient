//
//  SocketStateChangeCallbacks.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 10/9/25.
//  Copyright © 2025 SwiftPhoenixClient. All rights reserved.
//

import Foundation
 
internal struct SocketOpened {
    let ref: String
    let callback: (URLResponse?) -> Void
}

internal struct SocketClosed {
    let ref: String
    let callback: (URLSessionWebSocketTask.CloseCode, String?) -> Void
}

internal struct SocketErrored {
    let ref: String
    let callback: (Error, URLResponse?) -> Void
}

internal struct SocketMessaged {
    let ref: String
    let callback: (IncomingMessage) -> Void
}

/// Struct that gathers callbacks assigned to the Socket
internal struct SocketStateChangeCallbacks {
    var open: [SocketOpened] = []
    var close: [SocketClosed] = []
    var error: [SocketErrored] = []
    var message: [SocketMessaged] = []
}
