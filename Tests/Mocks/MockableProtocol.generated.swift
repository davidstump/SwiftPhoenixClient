// Generated using Sourcery 2.2.6 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

@testable import SwiftPhoenixClient














class ScheduleTimerMock: ScheduleTimer {
    var callback: (() -> Void)?
    var timerCalculation: ((Int) -> TimeInterval)?

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

}
class TransportMock: Transport {
    var readyState: TransportReadyState {
        get { return underlyingReadyState }
        set(value) { underlyingReadyState = value }
    }
    var underlyingReadyState: TransportReadyState!
    var delegate: TransportDelegate?

    //MARK: - connect

    var connectWithCallsCount = 0
    var connectWithCalled: Bool {
        return connectWithCallsCount > 0
    }
    var connectWithReceivedHeaders: [String: Any]?
    var connectWithReceivedInvocations: [[String: Any]] = []
    var connectWithClosure: (([String: Any]) -> Void)?

    func connect(with headers: [String: Any]) {
        connectWithCallsCount += 1
        connectWithReceivedHeaders = headers
        connectWithReceivedInvocations.append(headers)
        connectWithClosure?(headers)
    }

    //MARK: - disconnect

    var disconnectCodeReasonCallsCount = 0
    var disconnectCodeReasonCalled: Bool {
        return disconnectCodeReasonCallsCount > 0
    }
    var disconnectCodeReasonReceivedArguments: (code: URLSessionWebSocketTask.CloseCode, reason: String?)?
    var disconnectCodeReasonReceivedInvocations: [(code: URLSessionWebSocketTask.CloseCode, reason: String?)] = []
    var disconnectCodeReasonClosure: ((URLSessionWebSocketTask.CloseCode, String?) -> Void)?

    func disconnect(code: URLSessionWebSocketTask.CloseCode, reason: String?) {
        disconnectCodeReasonCallsCount += 1
        disconnectCodeReasonReceivedArguments = (code: code, reason: reason)
        disconnectCodeReasonReceivedInvocations.append((code: code, reason: reason))
        disconnectCodeReasonClosure?(code, reason)
    }

    //MARK: - send

    var sendDataCallsCount = 0
    var sendDataCalled: Bool {
        return sendDataCallsCount > 0
    }
    var sendDataReceivedData: Data?
    var sendDataReceivedInvocations: [Data] = []
    var sendDataClosure: ((Data) -> Void)?

    func send(data: Data) {
        sendDataCallsCount += 1
        sendDataReceivedData = data
        sendDataReceivedInvocations.append(data)
        sendDataClosure?(data)
    }

    //MARK: - send

    var sendStringCallsCount = 0
    var sendStringCalled: Bool {
        return sendStringCallsCount > 0
    }
    var sendStringReceivedString: String?
    var sendStringReceivedInvocations: [String] = []
    var sendStringClosure: ((String) -> Void)?

    func send(string: String) {
        sendStringCallsCount += 1
        sendStringReceivedString = string
        sendStringReceivedInvocations.append(string)
        sendStringClosure?(string)
    }

}
