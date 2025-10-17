//
//  Clock.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 10/15/25.
//  Copyright © 2025 SwiftPhoenixClient. All rights reserved.
//

import Foundation

internal protocol _Clock: Sendable {
    func sleep(for duration: TimeInterval) async throws
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, *)
extension ContinuousClock: _Clock {
    internal func sleep(for duration: TimeInterval) async throws {
        try await sleep(for: .seconds(duration))
    }
}

/// `_Clock` used on platforms where ``Clock`` protocol isn't available.
struct FallbackClock: _Clock {
    func sleep(for duration: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: NSEC_PER_SEC * UInt64(duration))
    }
}


// Resolves clock instance based on platform availability.
let _resolveClock: @Sendable () -> any _Clock = {
    if #available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *) {
        ContinuousClock()
    } else {
        FallbackClock()
    }
}

private let __clock = LockIsolated(_resolveClock())

#if DEBUG
internal var _clock: any _Clock {
    get {
        __clock.value
    }
    set {
        __clock.setValue(newValue)
    }
}
#else
internal var _clock: any _Clock {
    __clock.value
}
#endif
