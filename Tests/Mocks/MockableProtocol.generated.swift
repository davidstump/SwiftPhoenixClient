// Generated using Sourcery 2.2.5 — https://github.com/krzysztofzablocki/Sourcery
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














class PhoenixTransportMock: PhoenixTransport {
    var readyState: PhoenixTransportReadyState {
        get { return underlyingReadyState }
        set(value) { underlyingReadyState = value }
    }
    var underlyingReadyState: PhoenixTransportReadyState!
    var delegate: PhoenixTransportDelegate?

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
    var disconnectCodeReasonReceivedArguments: (code: Int, reason: String?)?
    var disconnectCodeReasonReceivedInvocations: [(code: Int, reason: String?)] = []
    var disconnectCodeReasonClosure: ((Int, String?) -> Void)?

    func disconnect(code: Int, reason: String?) {
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

}
