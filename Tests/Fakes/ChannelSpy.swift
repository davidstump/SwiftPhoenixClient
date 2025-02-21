//
//  ChannelSpy.swift
//  SwiftPhoenixClientTests
//
//  Created by Daniel Rees on 2/21/25.
//  Copyright © 2025 SwiftPhoenixClient. All rights reserved.
//

import Foundation
@testable import SwiftPhoenixClient

class ChannelSpy: Channel {
    
    init() {}
    
    override func trigger(event: String, payload: Payload = [:], status: String? = nil) {
     
    }
    
}
