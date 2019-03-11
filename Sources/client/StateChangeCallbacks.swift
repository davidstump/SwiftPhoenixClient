//
//  StateChangeCallbacks.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 2/20/19.
//

import Foundation

struct StateChangeCallbacks {
    var open: [Delegated<Void, Void>] = []
    var close: [Delegated<Void, Void>] = []
    var error: [Delegated<Error, Void>] = []
    var message: [Delegated<Message, Void>] = []
}
