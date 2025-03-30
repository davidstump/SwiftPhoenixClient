//
//  PushSpy.swift
//  SwiftPhoenixClientTests
//
//  Created by Daniel Rees on 2/20/25.
//  Copyright © 2025 SwiftPhoenixClient. All rights reserved.
//

import Foundation
@testable import SwiftPhoenixClient

class PushSpy: Push {
    
    override init(
        channel: Channel,
        event: String,
        payload: OutgoingPayload = .json([:]),
        timeout: TimeInterval = Defaults.timeoutInterval
    ) {
        super.init(
            channel: channel,
            event: event,
            payload: payload,
            timeout: timeout
        )
    }
    
    // MARK: - send
    private(set) var sendCallCount: Int = 0
    var sendCalled: Bool { sendCallCount > 0 }
    
    override func send() {
        sendCallCount += 1
    }
    
    // MARK: - reset
    private(set) var resetCallCount: Int = 0
    var resetCalled: Bool { resetCallCount > 0 }
    
    override func reset() {
        resetCallCount += 1
    }
}
