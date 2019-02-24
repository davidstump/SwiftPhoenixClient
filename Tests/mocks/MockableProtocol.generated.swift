// Generated using Sourcery 0.15.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable line_length
// swiftlint:disable variable_name

import Starscream
@testable import SwiftPhoenixClient













class TimeoutTimeableMock: TimeoutTimeable {
    var callback: Delegated<(), Void> {
        get { return underlyingCallback }
        set(value) { underlyingCallback = value }
    }
    var underlyingCallback: Delegated<(), Void>!
    var timerCalculation: Delegated<Int, TimeInterval> {
        get { return underlyingTimerCalculation }
        set(value) { underlyingTimerCalculation = value }
    }
    var underlyingTimerCalculation: Delegated<Int, TimeInterval>!

    //MARK: - reset

    var resetCallsCount = 0
    var resetCalled: Bool {
        return resetCallsCount > 0
    }
    var resetClosure: (() -> Void)?

    func reset() {
        resetCallsCount += 1
        resetClosure?()
    }

    //MARK: - scheduleTimeout

    var scheduleTimeoutCallsCount = 0
    var scheduleTimeoutCalled: Bool {
        return scheduleTimeoutCallsCount > 0
    }
    var scheduleTimeoutClosure: (() -> Void)?

    func scheduleTimeout() {
        scheduleTimeoutCallsCount += 1
        scheduleTimeoutClosure?()
    }

}
