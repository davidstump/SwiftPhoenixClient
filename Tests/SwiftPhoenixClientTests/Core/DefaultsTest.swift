//
//  DefaultsTest.swift
//  SwiftPhoenixClientTests
//
//  Created by Daniel Rees on 10/28/24.
//  Copyright © 2024 SwiftPhoenixClient. All rights reserved.
//

import Testing
@testable import SwiftPhoenixClient

struct DefaultsTest {

    @Test("timeoutInterval defaults to 10 seconds")
    func timeoutInterval_is10seconds() async throws {
        #expect(Defaults.timeoutInterval == 10.0)
    }
    
    @Test("heartbeatInterval defaults to 30 seconds")
    func heartbeatInterval_is30seconds() async throws {
        #expect(Defaults.heartbeatInterval == 30.0)
    }

    @Test("reconnectSteppedBackOff tries before maxing out")
    func reconnectSteppedBackoff_triesBeforeMaxingOut() async throws {
        let backoff = Defaults.reconnectSteppedBackOff
        #expect(backoff(0) == 0.010) // 10ms
        #expect(backoff(1) == 0.010) // 10ms
        #expect(backoff(2) == 0.050) // 50ms
        #expect(backoff(3) == 0.100) // 100ms
        #expect(backoff(4) == 0.150) // 150ms
        #expect(backoff(5) == 0.200) // 200ms
        #expect(backoff(6) == 0.250) // 250ms
        #expect(backoff(7) == 0.500) // 500ms
        #expect(backoff(8) == 1.000) // 1_000ms (1s)
        #expect(backoff(9) == 2.000) // 2_000ms (2s)
        #expect(backoff(10) == 5.00) // 5_000ms (5s)
        #expect(backoff(11) == 5.00) // 5_000ms (5s)
    }
    
    @Test("rejoinSteppedbackOff tries before maxing out")
    func rejoinSteppedBackOff_triesBeforeMaxingOut() async throws {
        let backoff = Defaults.rejoinSteppedBackOff
        #expect(backoff(0) == 1)
        #expect(backoff(1) == 1)
        #expect(backoff(2) == 2)
        #expect(backoff(3) == 5)
        #expect(backoff(4) == 10)
        #expect(backoff(5) == 10)
    }
}
