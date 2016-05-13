//
//  TestSocket.swift
//  SwiftPhoenixClient
//
//  Created by Nils Lattek on 13.05.16.
//  Copyright © 2016 Nils Lattek. All rights reserved.
//

import Foundation
import SwiftPhoenixClient

class TestSocket: Phoenix.Socket {
    init() {
        super.init(domainAndPort: "localhost:1234", path: "socket", transport: "websocket")
    }
}