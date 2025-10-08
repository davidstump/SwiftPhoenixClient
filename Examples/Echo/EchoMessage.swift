//
//  EchoMessage.swift
//  Examples
//
//  Created by Daniel Rees on 8/25/25.
//  Copyright © 2025 SwiftPhoenixClient. All rights reserved.
//

import Foundation

struct EchoMessage: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let isMe: Bool
}
