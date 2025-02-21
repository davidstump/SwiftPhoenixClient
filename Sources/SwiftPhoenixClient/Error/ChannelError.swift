//
//  ChannelError.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 2/21/25.
//  Copyright © 2025 SwiftPhoenixClient. All rights reserved.
//

import Foundation

public enum ChannelError: LocalizedError {
    case alreadyJoined
    case pushTriedBeforeJoin(topic: String, event: String)
    
    public var errorDescription: String? {
        switch self {
        case .alreadyJoined:
            NSLocalizedString(
                "tried to join multiple times. 'join' can only be called a single time per channel instance",
                comment: "Already Joined")
        case .pushTriedBeforeJoin(let topic, let event):
            NSLocalizedString(
                "tried to push \(event) to \(topic) before joining. Use channel.join() before pushing events",
                comment: "Cannot push before join")
            
        }
    }
}
