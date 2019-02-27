// Generated using Sourcery 0.15.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable line_length
// swiftlint:disable variable_name

import Starscream
@testable import SwiftPhoenixClient


























class SocketMock: Socket {
    override var encode: ([String: Any]) -> Data {
        get { return underlyingEncode }
        set(value) { underlyingEncode = value }
    }
    var underlyingEncode: (([String: Any]) -> Data)!
    var decodeSetCount: Int = 0
    var decodeDidGetSet: Bool { return decodeSetCount > 0 }
    override var decode: (Data) -> [String: Any]? {
        didSet { decodeSetCount += 1 }
    }
    override var timeout: TimeInterval {
        get { return underlyingTimeout }
        set(value) { underlyingTimeout = value }
    }
    var underlyingTimeout: (TimeInterval)!
    override var heartbeatInterval: TimeInterval {
        get { return underlyingHeartbeatInterval }
        set(value) { underlyingHeartbeatInterval = value }
    }
    var underlyingHeartbeatInterval: (TimeInterval)!
    override var reconnectAfter: (Int) -> TimeInterval {
        get { return underlyingReconnectAfter }
        set(value) { underlyingReconnectAfter = value }
    }
    var underlyingReconnectAfter: ((Int) -> TimeInterval)!
    var loggerSetCount: Int = 0
    var loggerDidGetSet: Bool { return loggerSetCount > 0 }
    override var logger: ((String) -> Void)? {
        didSet { loggerSetCount += 1 }
    }
    override var skipHeartbeat: Bool {
        get { return underlyingSkipHeartbeat }
        set(value) { underlyingSkipHeartbeat = value }
    }
    var underlyingSkipHeartbeat: (Bool)!
    override var disableSSLCertValidation: Bool {
        get { return underlyingDisableSSLCertValidation }
        set(value) { underlyingDisableSSLCertValidation = value }
    }
    var underlyingDisableSSLCertValidation: (Bool)!
    var securitySetCount: Int = 0
    var securityDidGetSet: Bool { return securitySetCount > 0 }
    override var security: SSLTrustValidator? {
        didSet { securitySetCount += 1 }
    }
    var enabledSSLCipherSuitesSetCount: Int = 0
    var enabledSSLCipherSuitesDidGetSet: Bool { return enabledSSLCipherSuitesSetCount > 0 }
    override var enabledSSLCipherSuites: [SSLCipherSuite]? {
        didSet { enabledSSLCipherSuitesSetCount += 1 }
    }
    override var stateChangeCallbacks: StateChangeCallbacks {
        get { return underlyingStateChangeCallbacks }
        set(value) { underlyingStateChangeCallbacks = value }
    }
    var underlyingStateChangeCallbacks: (StateChangeCallbacks)!
    override var ref: UInt64 {
        get { return underlyingRef }
        set(value) { underlyingRef = value }
    }
    var underlyingRef: (UInt64)!
    var heartbeatTimerSetCount: Int = 0
    var heartbeatTimerDidGetSet: Bool { return heartbeatTimerSetCount > 0 }
    override var heartbeatTimer: Timer? {
        didSet { heartbeatTimerSetCount += 1 }
    }
    var pendingHeartbeatRefSetCount: Int = 0
    var pendingHeartbeatRefDidGetSet: Bool { return pendingHeartbeatRefSetCount > 0 }
    override var pendingHeartbeatRef: String? {
        didSet { pendingHeartbeatRefSetCount += 1 }
    }
    override var reconnectTimer: TimeoutTimer {
        get { return underlyingReconnectTimer }
        set(value) { underlyingReconnectTimer = value }
    }
    var underlyingReconnectTimer: (TimeoutTimer)!
    var connectionSetCount: Int = 0
    var connectionDidGetSet: Bool { return connectionSetCount > 0 }
    override var connection: WebSocketClient? {
        didSet { connectionSetCount += 1 }
    }


    //MARK: - init

    var initParamsReceivedArguments: (endPoint: String, params: [String: Any]?)?
    var initParamsClosure: ((String, [String: Any]?) -> Void)?


    //MARK: - init

    var initEndPointTransportParamsReceivedArguments: (endPoint: String, transport: (URL) -> WebSocketClient, params: [String: Any]?)?
    var initEndPointTransportParamsClosure: ((String, @escaping ((URL) -> WebSocketClient), [String: Any]?) -> Void)?


    //MARK: - deinit

    var deinitCallsCount = 0
    var deinitCalled: Bool {
        return deinitCallsCount > 0
    }
    var deinitClosure: (() -> Void)?


    //MARK: - connect

    var connectCallsCount = 0
    var connectCalled: Bool {
        return connectCallsCount > 0
    }
    var connectClosure: (() -> Void)?

    override func connect() {
        connectCallsCount += 1
    }


    //MARK: - disconnect

    var disconnectCodeCallbackCallsCount = 0
    var disconnectCodeCallbackCalled: Bool {
        return disconnectCodeCallbackCallsCount > 0
    }
    var disconnectCodeCallbackReceivedArguments: (code: CloseCode?, callback: (() -> Void)?)?
    var disconnectCodeCallbackClosure: ((CloseCode?, (() -> Void)?) -> Void)?

    override func disconnect(code: CloseCode? = nil,                           callback: (() -> Void)? = nil) {
        disconnectCodeCallbackCallsCount += 1
    disconnectCodeCallbackReceivedArguments = (code: code, callback: callback)
    }


    //MARK: - teardown

    var teardownCodeCallbackCallsCount = 0
    var teardownCodeCallbackCalled: Bool {
        return teardownCodeCallbackCallsCount > 0
    }
    var teardownCodeCallbackReceivedArguments: (code: CloseCode?, callback: (() -> Void)?)?
    var teardownCodeCallbackClosure: ((CloseCode?, (() -> Void)?) -> Void)?

    override func teardown(code: CloseCode? = nil, callback: (() -> Void)? = nil) {
        teardownCodeCallbackCallsCount += 1
    teardownCodeCallbackReceivedArguments = (code: code, callback: callback)
    }


    //MARK: - onOpen

    var onOpenCallbackCallsCount = 0
    var onOpenCallbackCalled: Bool {
        return onOpenCallbackCallsCount > 0
    }
    var onOpenCallbackReceivedCallback: (() -> Void)?
    var onOpenCallbackClosure: ((@escaping () -> Void) -> Void)?

    override func onOpen(callback: @escaping () -> Void) {
        onOpenCallbackCallsCount += 1
        onOpenCallbackReceivedCallback = callback
    }


    //MARK: - delegateOnOpen<T: AnyObject>

    var delegateOnOpenToCallbackCallsCount = 0
    var delegateOnOpenToCallbackCalled: Bool {
        return delegateOnOpenToCallbackCallsCount > 0
    }

    override func delegateOnOpen<T: AnyObject>(to owner: T,                                             callback: @escaping ((T) -> Void)) {
        delegateOnOpenToCallbackCallsCount += 1
    }


    //MARK: - onClose

    var onCloseCallbackCallsCount = 0
    var onCloseCallbackCalled: Bool {
        return onCloseCallbackCallsCount > 0
    }
    var onCloseCallbackReceivedCallback: (() -> Void)?
    var onCloseCallbackClosure: ((@escaping () -> Void) -> Void)?

    override func onClose(callback: @escaping () -> Void) {
        onCloseCallbackCallsCount += 1
        onCloseCallbackReceivedCallback = callback
    }


    //MARK: - delegateOnClose<T: AnyObject>

    var delegateOnCloseToCallbackCallsCount = 0
    var delegateOnCloseToCallbackCalled: Bool {
        return delegateOnCloseToCallbackCallsCount > 0
    }

    override func delegateOnClose<T: AnyObject>(to owner: T,                                              callback: @escaping ((T) -> Void)) {
        delegateOnCloseToCallbackCallsCount += 1
    }


    //MARK: - onError

    var onErrorCallbackCallsCount = 0
    var onErrorCallbackCalled: Bool {
        return onErrorCallbackCallsCount > 0
    }
    var onErrorCallbackReceivedCallback: ((Error) -> Void)?
    var onErrorCallbackClosure: ((@escaping (Error) -> Void) -> Void)?

    override func onError(callback: @escaping (Error) -> Void) {
        onErrorCallbackCallsCount += 1
        onErrorCallbackReceivedCallback = callback
    }


    //MARK: - delegateOnError<T: AnyObject>

    var delegateOnErrorToCallbackCallsCount = 0
    var delegateOnErrorToCallbackCalled: Bool {
        return delegateOnErrorToCallbackCallsCount > 0
    }

    override func delegateOnError<T: AnyObject>(to owner: T,                                              callback: @escaping ((T, Error) -> Void)) {
        delegateOnErrorToCallbackCallsCount += 1
    }


    //MARK: - onMessage

    var onMessageCallbackCallsCount = 0
    var onMessageCallbackCalled: Bool {
        return onMessageCallbackCallsCount > 0
    }
    var onMessageCallbackReceivedCallback: ((Message) -> Void)?
    var onMessageCallbackClosure: ((@escaping (Message) -> Void) -> Void)?

    override func onMessage(callback: @escaping (Message) -> Void) {
        onMessageCallbackCallsCount += 1
        onMessageCallbackReceivedCallback = callback
    }


    //MARK: - delegateOnMessage<T: AnyObject>

    var delegateOnMessageToCallbackCallsCount = 0
    var delegateOnMessageToCallbackCalled: Bool {
        return delegateOnMessageToCallbackCallsCount > 0
    }

    override func delegateOnMessage<T: AnyObject>(to owner: T,                                                callback: @escaping ((T, Message) -> Void)) {
        delegateOnMessageToCallbackCallsCount += 1
    }


    //MARK: - releaseCallbacks

    var releaseCallbacksCallsCount = 0
    var releaseCallbacksCalled: Bool {
        return releaseCallbacksCallsCount > 0
    }
    var releaseCallbacksClosure: (() -> Void)?

    override func releaseCallbacks() {
        releaseCallbacksCallsCount += 1
    }


    //MARK: - channel

    var channelParamsCallsCount = 0
    var channelParamsCalled: Bool {
        return channelParamsCallsCount > 0
    }
    var channelParamsReceivedArguments: (topic: String, params: [String: Any])?
    var channelParamsReturnValue: Channel!
    var channelParamsClosure: ((String, [String: Any]) -> Channel)?

    override func channel(_ topic: String,                        params: [String: Any] = [:]) -> Channel {
        channelParamsCallsCount += 1
    channelParamsReceivedArguments = (topic: topic, params: params)
        return channelParamsReturnValue
    }


    //MARK: - remove

    var removeCallsCount = 0
    var removeCalled: Bool {
        return removeCallsCount > 0
    }
    var removeReceivedChannel: Channel?
    var removeClosure: ((Channel) -> Void)?

    override func remove(_ channel: Channel) {
        removeCallsCount += 1
        removeReceivedChannel = channel
    }


    //MARK: - push

    var pushTopicEventPayloadRefJoinRefCallsCount = 0
    var pushTopicEventPayloadRefJoinRefCalled: Bool {
        return pushTopicEventPayloadRefJoinRefCallsCount > 0
    }
    var pushTopicEventPayloadRefJoinRefReceivedArguments: (topic: String, event: String, payload: Payload, ref: String?, joinRef: String?)?
    var pushTopicEventPayloadRefJoinRefClosure: ((String, String, Payload, String?, String?) -> Void)?

    override func push(topic: String,                       event: String,                       payload: Payload,                       ref: String? = nil,                       joinRef: String? = nil) {
        pushTopicEventPayloadRefJoinRefCallsCount += 1
    pushTopicEventPayloadRefJoinRefReceivedArguments = (topic: topic, event: event, payload: payload, ref: ref, joinRef: joinRef)
    }


    //MARK: - makeRef

    var makeRefCallsCount = 0
    var makeRefCalled: Bool {
        return makeRefCallsCount > 0
    }
    var makeRefReturnValue: String!
    var makeRefClosure: (() -> String)?

    override func makeRef() -> String {
        makeRefCallsCount += 1
        return makeRefReturnValue
    }


    //MARK: - logItems

    var logItemsCallsCount = 0
    var logItemsCalled: Bool {
        return logItemsCallsCount > 0
    }
    var logItemsReceivedItems: Any?
    var logItemsClosure: ((Any) -> Void)?

    override func logItems(_ items: Any...) {
        logItemsCallsCount += 1
        logItemsReceivedItems = items
    }


    //MARK: - onConnectionOpen

    var onConnectionOpenCallsCount = 0
    var onConnectionOpenCalled: Bool {
        return onConnectionOpenCallsCount > 0
    }
    var onConnectionOpenClosure: (() -> Void)?

    override func onConnectionOpen() {
        onConnectionOpenCallsCount += 1
    }


    //MARK: - onConnectionClosed

    var onConnectionClosedCodeCallsCount = 0
    var onConnectionClosedCodeCalled: Bool {
        return onConnectionClosedCodeCallsCount > 0
    }
    var onConnectionClosedCodeReceivedCode: Int?
    var onConnectionClosedCodeClosure: ((Int?) -> Void)?

    override func onConnectionClosed(code: Int?) {
        onConnectionClosedCodeCallsCount += 1
        onConnectionClosedCodeReceivedCode = code
    }


    //MARK: - onConnectionError

    var onConnectionErrorCallsCount = 0
    var onConnectionErrorCalled: Bool {
        return onConnectionErrorCallsCount > 0
    }
    var onConnectionErrorReceivedError: Error?
    var onConnectionErrorClosure: ((Error) -> Void)?

    override func onConnectionError(_ error: Error) {
        onConnectionErrorCallsCount += 1
        onConnectionErrorReceivedError = error
    }


    //MARK: - onConnectionMessage

    var onConnectionMessageCallsCount = 0
    var onConnectionMessageCalled: Bool {
        return onConnectionMessageCallsCount > 0
    }
    var onConnectionMessageReceivedRawMessage: String?
    var onConnectionMessageClosure: ((String) -> Void)?

    override func onConnectionMessage(_ rawMessage: String) {
        onConnectionMessageCallsCount += 1
        onConnectionMessageReceivedRawMessage = rawMessage
    }


    //MARK: - triggerChannelError

    var triggerChannelErrorCallsCount = 0
    var triggerChannelErrorCalled: Bool {
        return triggerChannelErrorCallsCount > 0
    }
    var triggerChannelErrorClosure: (() -> Void)?

    override func triggerChannelError() {
        triggerChannelErrorCallsCount += 1
    }


    //MARK: - flushSendBuffer

    var flushSendBufferCallsCount = 0
    var flushSendBufferCalled: Bool {
        return flushSendBufferCallsCount > 0
    }
    var flushSendBufferClosure: (() -> Void)?

    override func flushSendBuffer() {
        flushSendBufferCallsCount += 1
    }


    //MARK: - resetHeartbeat

    var resetHeartbeatCallsCount = 0
    var resetHeartbeatCalled: Bool {
        return resetHeartbeatCallsCount > 0
    }
    var resetHeartbeatClosure: (() -> Void)?

    override func resetHeartbeat() {
        resetHeartbeatCallsCount += 1
    }


    //MARK: - sendHeartbeat

    var sendHeartbeatCallsCount = 0
    var sendHeartbeatCalled: Bool {
        return sendHeartbeatCallsCount > 0
    }
    var sendHeartbeatClosure: (() -> Void)?

    override func sendHeartbeat() {
        sendHeartbeatCallsCount += 1
    }


}
class TimeoutTimerMock: TimeoutTimer {
    override var callback: Delegated<(), Void> {
        get { return underlyingCallback }
        set(value) { underlyingCallback = value }
    }
    var underlyingCallback: (Delegated<(), Void>)!
    override var timerCalculation: Delegated<Int, TimeInterval> {
        get { return underlyingTimerCalculation }
        set(value) { underlyingTimerCalculation = value }
    }
    var underlyingTimerCalculation: (Delegated<Int, TimeInterval>)!
    var workItemSetCount: Int = 0
    var workItemDidGetSet: Bool { return workItemSetCount > 0 }
    override var workItem: DispatchWorkItem? {
        didSet { workItemSetCount += 1 }
    }
    override var tries: Int {
        get { return underlyingTries }
        set(value) { underlyingTries = value }
    }
    var underlyingTries: (Int)!


    //MARK: - reset

    var resetCallsCount = 0
    var resetCalled: Bool {
        return resetCallsCount > 0
    }
    var resetClosure: (() -> Void)?

    override func reset() {
        resetCallsCount += 1
    }


    //MARK: - scheduleTimeout

    var scheduleTimeoutCallsCount = 0
    var scheduleTimeoutCalled: Bool {
        return scheduleTimeoutCallsCount > 0
    }
    var scheduleTimeoutClosure: (() -> Void)?

    override func scheduleTimeout() {
        scheduleTimeoutCallsCount += 1
    }


}
