// Generated using Sourcery 0.15.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable line_length
// swiftlint:disable variable_name

import Starscream
@testable import SwiftPhoenixClient
























class TimeoutTimerMock: TimeoutTimer {


    //MARK: - reset

    var resetCallsCount = 0
    var resetCalled: Bool {
        return resetCallsCount > 0
    }
    var resetClosure: (() -> Void)?

    override func reset() {
        resetCallsCount += 1
        resetClosure?()
    }


    //MARK: - scheduleTimeout

    var scheduleTimeoutCallsCount = 0
    var scheduleTimeoutCalled: Bool {
        return scheduleTimeoutCallsCount > 0
    }
    var scheduleTimeoutClosure: (() -> Void)?

    override func scheduleTimeout() {
        scheduleTimeoutCallsCount += 1
        scheduleTimeoutClosure?()
    }


    //MARK: - onTimerTriggered

    var onTimerTriggeredCallsCount = 0
    var onTimerTriggeredCalled: Bool {
        return onTimerTriggeredCallsCount > 0
    }
    var onTimerTriggeredClosure: (() -> Void)?

    override func onTimerTriggered() {
        onTimerTriggeredCallsCount += 1
        onTimerTriggeredClosure?()
    }


}
