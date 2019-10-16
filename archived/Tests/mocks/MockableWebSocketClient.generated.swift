// Generated using Sourcery 0.15.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable line_length
// swiftlint:disable variable_name

import Starscream
@testable import SwiftPhoenixClient













class WebSocketClientMock: WebSocketClient {
    var delegate: WebSocketDelegate?
    var pongDelegate: WebSocketPongDelegate?
    var disableSSLCertValidation: Bool {
        get { return underlyingDisableSSLCertValidation }
        set(value) { underlyingDisableSSLCertValidation = value }
    }
    var underlyingDisableSSLCertValidation: Bool!
    var overrideTrustHostname: Bool {
        get { return underlyingOverrideTrustHostname }
        set(value) { underlyingOverrideTrustHostname = value }
    }
    var underlyingOverrideTrustHostname: Bool!
    var desiredTrustHostname: String?
    var sslClientCertificate: SSLClientCertificate?
    var security: SSLTrustValidator?
    var enabledSSLCipherSuites: [SSLCipherSuite]?
    var isConnected: Bool {
        get { return underlyingIsConnected }
        set(value) { underlyingIsConnected = value }
    }
    var underlyingIsConnected: Bool!

    //MARK: - connect

    var connectCallsCount = 0
    var connectCalled: Bool {
        return connectCallsCount > 0
    }
    var connectClosure: (() -> Void)?

    func connect() {
        connectCallsCount += 1
        connectClosure?()
    }

    //MARK: - disconnect

    var disconnectForceTimeoutCloseCodeCallsCount = 0
    var disconnectForceTimeoutCloseCodeCalled: Bool {
        return disconnectForceTimeoutCloseCodeCallsCount > 0
    }
    var disconnectForceTimeoutCloseCodeReceivedArguments: (forceTimeout: TimeInterval?, closeCode: UInt16)?
    var disconnectForceTimeoutCloseCodeClosure: ((TimeInterval?, UInt16) -> Void)?

    func disconnect(forceTimeout: TimeInterval?, closeCode: UInt16) {
        disconnectForceTimeoutCloseCodeCallsCount += 1
        disconnectForceTimeoutCloseCodeReceivedArguments = (forceTimeout: forceTimeout, closeCode: closeCode)
        disconnectForceTimeoutCloseCodeClosure?(forceTimeout, closeCode)
    }

    //MARK: - write

    var writeStringCompletionCallsCount = 0
    var writeStringCompletionCalled: Bool {
        return writeStringCompletionCallsCount > 0
    }
    var writeStringCompletionReceivedArguments: (string: String, completion: (() -> ())?)?
    var writeStringCompletionClosure: ((String, (() -> ())?) -> Void)?

    func write(string: String, completion: (() -> ())?) {
        writeStringCompletionCallsCount += 1
        writeStringCompletionReceivedArguments = (string: string, completion: completion)
        writeStringCompletionClosure?(string, completion)
    }

    //MARK: - write

    var writeDataCompletionCallsCount = 0
    var writeDataCompletionCalled: Bool {
        return writeDataCompletionCallsCount > 0
    }
    var writeDataCompletionReceivedArguments: (data: Data, completion: (() -> ())?)?
    var writeDataCompletionClosure: ((Data, (() -> ())?) -> Void)?

    func write(data: Data, completion: (() -> ())?) {
        writeDataCompletionCallsCount += 1
        writeDataCompletionReceivedArguments = (data: data, completion: completion)
        writeDataCompletionClosure?(data, completion)
    }

    //MARK: - write

    var writePingCompletionCallsCount = 0
    var writePingCompletionCalled: Bool {
        return writePingCompletionCallsCount > 0
    }
    var writePingCompletionReceivedArguments: (ping: Data, completion: (() -> ())?)?
    var writePingCompletionClosure: ((Data, (() -> ())?) -> Void)?

    func write(ping: Data, completion: (() -> ())?) {
        writePingCompletionCallsCount += 1
        writePingCompletionReceivedArguments = (ping: ping, completion: completion)
        writePingCompletionClosure?(ping, completion)
    }

    //MARK: - write

    var writePongCompletionCallsCount = 0
    var writePongCompletionCalled: Bool {
        return writePongCompletionCallsCount > 0
    }
    var writePongCompletionReceivedArguments: (pong: Data, completion: (() -> ())?)?
    var writePongCompletionClosure: ((Data, (() -> ())?) -> Void)?

    func write(pong: Data, completion: (() -> ())?) {
        writePongCompletionCallsCount += 1
        writePongCompletionReceivedArguments = (pong: pong, completion: completion)
        writePongCompletionClosure?(pong, completion)
    }

}
