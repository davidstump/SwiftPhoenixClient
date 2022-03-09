// Generated using Sourcery 1.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable line_length
// swiftlint:disable variable_name

@testable import SwiftPhoenixClient


























class ChannelMock: Channel {
    var socketSetCount: Int = 0
    var socketDidGetSet: Bool { return socketSetCount > 0 }
    override var socket: Socket? {
        didSet { socketSetCount += 1 }
    }
    override var state: ChannelState {
        get { return underlyingState }
        set(value) { underlyingState = value }
    }
    var underlyingState: (ChannelState)!
    override var bindingRef: Int {
        get { return underlyingBindingRef }
        set(value) { underlyingBindingRef = value }
    }
    var underlyingBindingRef: (Int)!
    override var timeout: TimeInterval {
        get { return underlyingTimeout }
        set(value) { underlyingTimeout = value }
    }
    var underlyingTimeout: (TimeInterval)!
    override var joinedOnce: Bool {
        get { return underlyingJoinedOnce }
        set(value) { underlyingJoinedOnce = value }
    }
    var underlyingJoinedOnce: (Bool)!
    var joinPushSetCount: Int = 0
    var joinPushDidGetSet: Bool { return joinPushSetCount > 0 }
    override var joinPush: Push! {
        didSet { joinPushSetCount += 1 }
    }
    override var rejoinTimer: TimeoutTimer {
        get { return underlyingRejoinTimer }
        set(value) { underlyingRejoinTimer = value }
    }
    var underlyingRejoinTimer: (TimeoutTimer)!
    override var onMessage: (_ message: Message) -> Message {
        get { return underlyingOnMessage }
        set(value) { underlyingOnMessage = value }
    }
    var underlyingOnMessage: ((_ message: Message) -> Message)!


    //MARK: - init

    var initTopicParamsSocketReceivedArguments: (topic: String, params: [String: Any], socket: Socket)?
    var initTopicParamsSocketClosure: ((String, [String: Any], Socket) -> Void)?


    //MARK: - deinit

    var deinitCallsCount = 0
    var deinitCalled: Bool {
        return deinitCallsCount > 0
    }
    var deinitClosure: (() -> Void)?


    //MARK: - join

    var joinTimeoutCallsCount = 0
    var joinTimeoutCalled: Bool {
        return joinTimeoutCallsCount > 0
    }
    var joinTimeoutReceivedTimeout: TimeInterval?
    var joinTimeoutReturnValue: Push!
    var joinTimeoutClosure: ((TimeInterval?) -> Push)?

    override func join(timeout: TimeInterval? = nil) -> Push {
        joinTimeoutCallsCount += 1
        joinTimeoutReceivedTimeout = timeout
        return joinTimeoutClosure.map({ $0(timeout) }) ?? joinTimeoutReturnValue
    }


    //MARK: - onClose

    var onCloseCallsCount = 0
    var onCloseCalled: Bool {
        return onCloseCallsCount > 0
    }
    var onCloseReceivedCallback: ((Message) -> Void)?
    var onCloseReturnValue: Int!
    var onCloseClosure: ((@escaping ((Message) -> Void)) -> Int)?

    override func onClose(_ callback: @escaping ((Message) -> Void)) -> Int {
        onCloseCallsCount += 1
        onCloseReceivedCallback = callback
        return onCloseClosure.map({ $0(callback) }) ?? onCloseReturnValue
    }


    //MARK: - delegateOnClose<Target: AnyObject>

    var delegateOnCloseToCallbackCallsCount = 0
    var delegateOnCloseToCallbackCalled: Bool {
        return delegateOnCloseToCallbackCallsCount > 0
    }
    var delegateOnCloseToCallbackReturnValue: Int!

    override func delegateOnClose<Target: AnyObject>(to owner: Target,
                                                 callback: @escaping ((Target, Message) -> Void)) -> Int {
        delegateOnCloseToCallbackCallsCount += 1
        return delegateOnCloseToCallbackReturnValue
    }


    //MARK: - onError

    var onErrorCallsCount = 0
    var onErrorCalled: Bool {
        return onErrorCallsCount > 0
    }
    var onErrorReceivedCallback: ((_ message: Message) -> Void)?
    var onErrorReturnValue: Int!
    var onErrorClosure: ((@escaping ((_ message: Message) -> Void)) -> Int)?

    override func onError(_ callback: @escaping ((_ message: Message) -> Void)) -> Int {
        onErrorCallsCount += 1
        onErrorReceivedCallback = callback
        return onErrorClosure.map({ $0(callback) }) ?? onErrorReturnValue
    }


    //MARK: - delegateOnError<Target: AnyObject>

    var delegateOnErrorToCallbackCallsCount = 0
    var delegateOnErrorToCallbackCalled: Bool {
        return delegateOnErrorToCallbackCallsCount > 0
    }
    var delegateOnErrorToCallbackReturnValue: Int!

    override func delegateOnError<Target: AnyObject>(to owner: Target,
                                                 callback: @escaping ((Target, Message) -> Void)) -> Int {
        delegateOnErrorToCallbackCallsCount += 1
        return delegateOnErrorToCallbackReturnValue
    }


    //MARK: - on

    var onCallbackCallsCount = 0
    var onCallbackCalled: Bool {
        return onCallbackCallsCount > 0
    }
    var onCallbackReceivedArguments: (event: String, callback: (Message) -> Void)?
    var onCallbackReturnValue: Int!
    var onCallbackClosure: ((String, @escaping ((Message) -> Void)) -> Int)?

    override func on(_ event: String, callback: @escaping ((Message) -> Void)) -> Int {
        onCallbackCallsCount += 1
    onCallbackReceivedArguments = (event: event, callback: callback)
        return onCallbackClosure.map({ $0(event, callback) }) ?? onCallbackReturnValue
    }


    //MARK: - delegateOn<Target: AnyObject>

    var delegateOnToCallbackCallsCount = 0
    var delegateOnToCallbackCalled: Bool {
        return delegateOnToCallbackCallsCount > 0
    }
    var delegateOnToCallbackReturnValue: Int!

    override func delegateOn<Target: AnyObject>(_ event: String,
                                            to owner: Target,
                                            callback: @escaping ((Target, Message) -> Void)) -> Int {
        delegateOnToCallbackCallsCount += 1
        return delegateOnToCallbackReturnValue
    }


    //MARK: - off

    var offRefCallsCount = 0
    var offRefCalled: Bool {
        return offRefCallsCount > 0
    }
    var offRefReceivedArguments: (event: String, ref: Int?)?
    var offRefClosure: ((String, Int?) -> Void)?

    override func off(_ event: String, ref: Int? = nil) {
        offRefCallsCount += 1
    offRefReceivedArguments = (event: event, ref: ref)
        offRefClosure?(event, ref)
    }


    //MARK: - push

    var pushPayloadTimeoutCallsCount = 0
    var pushPayloadTimeoutCalled: Bool {
        return pushPayloadTimeoutCallsCount > 0
    }
    var pushPayloadTimeoutReceivedArguments: (event: String, payload: Payload, timeout: TimeInterval)?
    var pushPayloadTimeoutReturnValue: Push!
    var pushPayloadTimeoutClosure: ((String, Payload, TimeInterval) -> Push)?

    override func push(_ event: String,
                   payload: Payload,
                   timeout: TimeInterval = Defaults.timeoutInterval) -> Push {
        pushPayloadTimeoutCallsCount += 1
    pushPayloadTimeoutReceivedArguments = (event: event, payload: payload, timeout: timeout)
        return pushPayloadTimeoutClosure.map({ $0(event, payload, timeout) }) ?? pushPayloadTimeoutReturnValue
    }


    //MARK: - leave

    var leaveTimeoutCallsCount = 0
    var leaveTimeoutCalled: Bool {
        return leaveTimeoutCallsCount > 0
    }
    var leaveTimeoutReceivedTimeout: TimeInterval?
    var leaveTimeoutReturnValue: Push!
    var leaveTimeoutClosure: ((TimeInterval) -> Push)?

    override func leave(timeout: TimeInterval = Defaults.timeoutInterval) -> Push {
        leaveTimeoutCallsCount += 1
        leaveTimeoutReceivedTimeout = timeout
        return leaveTimeoutClosure.map({ $0(timeout) }) ?? leaveTimeoutReturnValue
    }


    //MARK: - onMessage

    var onMessageCallbackCallsCount = 0
    var onMessageCallbackCalled: Bool {
        return onMessageCallbackCallsCount > 0
    }
    var onMessageCallbackReceivedCallback: ((Message) -> Message)?
    var onMessageCallbackClosure: ((@escaping (Message) -> Message) -> Void)?

    override func onMessage(callback: @escaping (Message) -> Message) {
        onMessageCallbackCallsCount += 1
        onMessageCallbackReceivedCallback = callback
        onMessageCallbackClosure?(callback)
    }


    //MARK: - isMember

    var isMemberCallsCount = 0
    var isMemberCalled: Bool {
        return isMemberCallsCount > 0
    }
    var isMemberReceivedMessage: Message?
    var isMemberReturnValue: Bool!
    var isMemberClosure: ((Message) -> Bool)?

    override func isMember(_ message: Message) -> Bool {
        isMemberCallsCount += 1
        isMemberReceivedMessage = message
        return isMemberClosure.map({ $0(message) }) ?? isMemberReturnValue
    }


    //MARK: - sendJoin

    var sendJoinCallsCount = 0
    var sendJoinCalled: Bool {
        return sendJoinCallsCount > 0
    }
    var sendJoinReceivedTimeout: TimeInterval?
    var sendJoinClosure: ((TimeInterval) -> Void)?

    override func sendJoin(_ timeout: TimeInterval) {
        sendJoinCallsCount += 1
        sendJoinReceivedTimeout = timeout
        sendJoinClosure?(timeout)
    }


    //MARK: - rejoin

    var rejoinCallsCount = 0
    var rejoinCalled: Bool {
        return rejoinCallsCount > 0
    }
    var rejoinReceivedTimeout: TimeInterval?
    var rejoinClosure: ((TimeInterval?) -> Void)?

    override func rejoin(_ timeout: TimeInterval? = nil) {
        rejoinCallsCount += 1
        rejoinReceivedTimeout = timeout
        rejoinClosure?(timeout)
    }


    //MARK: - trigger

    var triggerCallsCount = 0
    var triggerCalled: Bool {
        return triggerCallsCount > 0
    }
    var triggerReceivedMessage: Message?
    var triggerClosure: ((Message) -> Void)?

    override func trigger(_ message: Message) {
        triggerCallsCount += 1
        triggerReceivedMessage = message
        triggerClosure?(message)
    }


    //MARK: - trigger

    var triggerEventPayloadRefJoinRefCallsCount = 0
    var triggerEventPayloadRefJoinRefCalled: Bool {
        return triggerEventPayloadRefJoinRefCallsCount > 0
    }
    var triggerEventPayloadRefJoinRefReceivedArguments: (event: String, payload: Payload, ref: String, joinRef: String?)?
    var triggerEventPayloadRefJoinRefClosure: ((String, Payload, String, String?) -> Void)?

    override func trigger(event: String,
               payload: Payload = [:],
               ref: String = "",
               joinRef: String? = nil) {
        triggerEventPayloadRefJoinRefCallsCount += 1
    triggerEventPayloadRefJoinRefReceivedArguments = (event: event, payload: payload, ref: ref, joinRef: joinRef)
        triggerEventPayloadRefJoinRefClosure?(event, payload, ref, joinRef)
    }


    //MARK: - replyEventName

    var replyEventNameCallsCount = 0
    var replyEventNameCalled: Bool {
        return replyEventNameCallsCount > 0
    }
    var replyEventNameReceivedRef: String?
    var replyEventNameReturnValue: String!
    var replyEventNameClosure: ((String) -> String)?

    override func replyEventName(_ ref: String) -> String {
        replyEventNameCallsCount += 1
        replyEventNameReceivedRef = ref
        return replyEventNameClosure.map({ $0(ref) }) ?? replyEventNameReturnValue
    }


}
class PushMock: Push {
    var channelSetCount: Int = 0
    var channelDidGetSet: Bool { return channelSetCount > 0 }
    override var channel: Channel? {
        didSet { channelSetCount += 1 }
    }
    override var timeout: TimeInterval {
        get { return underlyingTimeout }
        set(value) { underlyingTimeout = value }
    }
    var underlyingTimeout: (TimeInterval)!
    var receivedMessageSetCount: Int = 0
    var receivedMessageDidGetSet: Bool { return receivedMessageSetCount > 0 }
    override var receivedMessage: Message? {
        didSet { receivedMessageSetCount += 1 }
    }
    override var timeoutTimer: TimerQueue {
        get { return underlyingTimeoutTimer }
        set(value) { underlyingTimeoutTimer = value }
    }
    var underlyingTimeoutTimer: (TimerQueue)!
    var timeoutWorkItemSetCount: Int = 0
    var timeoutWorkItemDidGetSet: Bool { return timeoutWorkItemSetCount > 0 }
    override var timeoutWorkItem: DispatchWorkItem? {
        didSet { timeoutWorkItemSetCount += 1 }
    }
    override var sent: Bool {
        get { return underlyingSent }
        set(value) { underlyingSent = value }
    }
    var underlyingSent: (Bool)!
    var refSetCount: Int = 0
    var refDidGetSet: Bool { return refSetCount > 0 }
    override var ref: String? {
        didSet { refSetCount += 1 }
    }
    var refEventSetCount: Int = 0
    var refEventDidGetSet: Bool { return refEventSetCount > 0 }
    override var refEvent: String? {
        didSet { refEventSetCount += 1 }
    }


    //MARK: - init

    var initChannelEventPayloadTimeoutReceivedArguments: (channel: Channel, event: String, payload: Payload, timeout: TimeInterval)?
    var initChannelEventPayloadTimeoutClosure: ((Channel, String, Payload, TimeInterval) -> Void)?


    //MARK: - resend

    var resendCallsCount = 0
    var resendCalled: Bool {
        return resendCallsCount > 0
    }
    var resendReceivedTimeout: TimeInterval?
    var resendClosure: ((TimeInterval) -> Void)?

    override func resend(_ timeout: TimeInterval = Defaults.timeoutInterval) {
        resendCallsCount += 1
        resendReceivedTimeout = timeout
        resendClosure?(timeout)
    }


    //MARK: - send

    var sendCallsCount = 0
    var sendCalled: Bool {
        return sendCallsCount > 0
    }
    var sendClosure: (() -> Void)?

    override func send() {
        sendCallsCount += 1
        sendClosure?()
    }


    //MARK: - receive

    var receiveCallbackCallsCount = 0
    var receiveCallbackCalled: Bool {
        return receiveCallbackCallsCount > 0
    }
    var receiveCallbackReceivedArguments: (status: String, callback: (Message) -> ())?
    var receiveCallbackReturnValue: Push!
    var receiveCallbackClosure: ((String, @escaping ((Message) -> ())) -> Push)?

    override func receive(_ status: String,
                      callback: @escaping ((Message) -> ())) -> Push {
        receiveCallbackCallsCount += 1
    receiveCallbackReceivedArguments = (status: status, callback: callback)
        return receiveCallbackClosure.map({ $0(status, callback) }) ?? receiveCallbackReturnValue
    }


    //MARK: - delegateReceive<Target: AnyObject>

    var delegateReceiveToCallbackCallsCount = 0
    var delegateReceiveToCallbackCalled: Bool {
        return delegateReceiveToCallbackCallsCount > 0
    }
    var delegateReceiveToCallbackReturnValue: Push!

    override func delegateReceive<Target: AnyObject>(_ status: String,
                                                 to owner: Target,
                                                 callback: @escaping ((Target, Message) -> ())) -> Push {
        delegateReceiveToCallbackCallsCount += 1
        return delegateReceiveToCallbackReturnValue
    }


    //MARK: - receive

    var receiveDelegatedCallsCount = 0
    var receiveDelegatedCalled: Bool {
        return receiveDelegatedCallsCount > 0
    }
    var receiveDelegatedReceivedArguments: (status: String, delegated: Delegated<Message, Void>)?
    var receiveDelegatedReturnValue: Push!
    var receiveDelegatedClosure: ((String, Delegated<Message, Void>) -> Push)?

    override func receive(_ status: String, delegated: Delegated<Message, Void>) -> Push {
        receiveDelegatedCallsCount += 1
    receiveDelegatedReceivedArguments = (status: status, delegated: delegated)
        return receiveDelegatedClosure.map({ $0(status, delegated) }) ?? receiveDelegatedReturnValue
    }


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


    //MARK: - cancelTimeout

    var cancelTimeoutCallsCount = 0
    var cancelTimeoutCalled: Bool {
        return cancelTimeoutCallsCount > 0
    }
    var cancelTimeoutClosure: (() -> Void)?

    override func cancelTimeout() {
        cancelTimeoutCallsCount += 1
        cancelTimeoutClosure?()
    }


    //MARK: - startTimeout

    var startTimeoutCallsCount = 0
    var startTimeoutCalled: Bool {
        return startTimeoutCallsCount > 0
    }
    var startTimeoutClosure: (() -> Void)?

    override func startTimeout() {
        startTimeoutCallsCount += 1
        startTimeoutClosure?()
    }


    //MARK: - hasReceived

    var hasReceivedStatusCallsCount = 0
    var hasReceivedStatusCalled: Bool {
        return hasReceivedStatusCallsCount > 0
    }
    var hasReceivedStatusReceivedStatus: String?
    var hasReceivedStatusReturnValue: Bool!
    var hasReceivedStatusClosure: ((String) -> Bool)?

    override func hasReceived(status: String) -> Bool {
        hasReceivedStatusCallsCount += 1
        hasReceivedStatusReceivedStatus = status
        return hasReceivedStatusClosure.map({ $0(status) }) ?? hasReceivedStatusReturnValue
    }


    //MARK: - trigger

    var triggerPayloadCallsCount = 0
    var triggerPayloadCalled: Bool {
        return triggerPayloadCallsCount > 0
    }
    var triggerPayloadReceivedArguments: (status: String, payload: Payload)?
    var triggerPayloadClosure: ((String, Payload) -> Void)?

    override func trigger(_ status: String, payload: Payload) {
        triggerPayloadCallsCount += 1
    triggerPayloadReceivedArguments = (status: status, payload: payload)
        triggerPayloadClosure?(status, payload)
    }


}
class SocketMock: Socket {
    override var endPointUrl: URL {
        get { return underlyingEndPointUrl }
        set(value) { underlyingEndPointUrl = value }
    }
    var underlyingEndPointUrl: (URL)!
    override var encode: (Any) -> Data {
        get { return underlyingEncode }
        set(value) { underlyingEncode = value }
    }
    var underlyingEncode: ((Any) -> Data)!
    override var decode: (Data) -> Any? {
        get { return underlyingDecode }
        set(value) { underlyingDecode = value }
    }
    var underlyingDecode: ((Data) -> Any?)!
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
    override var rejoinAfter: (Int) -> TimeInterval {
        get { return underlyingRejoinAfter }
        set(value) { underlyingRejoinAfter = value }
    }
    var underlyingRejoinAfter: ((Int) -> TimeInterval)!
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
    override var heartbeatTimer: HeartbeatTimer? {
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
    override var closeStatus: CloseStatus {
      get { return underlyingCloseStatus }
      set(value) { underlyingCloseStatus = value }
    }
    var underlyingCloseStatus: (CloseStatus)!
    var connectionSetCount: Int = 0
    var connectionDidGetSet: Bool { return connectionSetCount > 0 }
    override var connection: PhoenixTransport? {
        didSet { connectionSetCount += 1 }
    }


    //MARK: - init

    var initParamsReceivedArguments: (endPoint: String, params: Payload?)?
    var initParamsClosure: ((String, Payload?) -> Void)?


    //MARK: - init

    var initParamsClosureReceivedArguments: (endPoint: String, paramsClosure: PayloadClosure?)?
    var initParamsClosureClosure: ((String, PayloadClosure?) -> Void)?


    //MARK: - init

    var initEndPointTransportParamsClosureReceivedArguments: (endPoint: String, transport: (URL) -> PhoenixTransport, paramsClosure: PayloadClosure?)?
    var initEndPointTransportParamsClosureClosure: ((String, @escaping ((URL) -> PhoenixTransport), PayloadClosure?) -> Void)?


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
        connectClosure?()
    }


    //MARK: - disconnect

    var disconnectCodeCallbackCallsCount = 0
    var disconnectCodeCallbackCalled: Bool {
        return disconnectCodeCallbackCallsCount > 0
    }
    var disconnectCodeCallbackReceivedArguments: (code: CloseCode, callback: (() -> Void)?)?
    var disconnectCodeCallbackClosure: ((CloseCode, (() -> Void)?) -> Void)?

    override func disconnect(code: CloseCode = CloseCode.normal,
                         callback: (() -> Void)? = nil) {
        disconnectCodeCallbackCallsCount += 1
    disconnectCodeCallbackReceivedArguments = (code: code, callback: callback)
        disconnectCodeCallbackClosure?(code, callback)
    }


    //MARK: - teardown

    var teardownCodeCallbackCallsCount = 0
    var teardownCodeCallbackCalled: Bool {
        return teardownCodeCallbackCallsCount > 0
    }
    var teardownCodeCallbackReceivedArguments: (code: CloseCode, callback: (() -> Void)?)?
    var teardownCodeCallbackClosure: ((CloseCode, (() -> Void)?) -> Void)?

    override func teardown(code: CloseCode = CloseCode.normal, callback: (() -> Void)? = nil) {
        teardownCodeCallbackCallsCount += 1
    teardownCodeCallbackReceivedArguments = (code: code, callback: callback)
        teardownCodeCallbackClosure?(code, callback)
    }


    //MARK: - onOpen

    var onOpenCallbackCallsCount = 0
    var onOpenCallbackCalled: Bool {
        return onOpenCallbackCallsCount > 0
    }
    var onOpenCallbackReceivedCallback: (() -> Void)?
    var onOpenCallbackReturnValue: String!
    var onOpenCallbackClosure: ((@escaping () -> Void) -> String)?

    override func onOpen(callback: @escaping () -> Void) -> String {
        onOpenCallbackCallsCount += 1
        onOpenCallbackReceivedCallback = callback
        return onOpenCallbackClosure.map({ $0(callback) }) ?? makeRefReturnValue
    }


    //MARK: - delegateOnOpen<T: AnyObject>

    var delegateOnOpenToCallbackCallsCount = 0
    var delegateOnOpenToCallbackCalled: Bool {
        return delegateOnOpenToCallbackCallsCount > 0
    }
    var delegateOnOpenToCallbackReturnValue: String!

    override func delegateOnOpen<T: AnyObject>(to owner: T,
                                           callback: @escaping ((T) -> Void)) -> String {
        delegateOnOpenToCallbackCallsCount += 1
        return makeRefReturnValue
    }


    //MARK: - onClose

    var onCloseCallbackCallsCount = 0
    var onCloseCallbackCalled: Bool {
        return onCloseCallbackCallsCount > 0
    }
    var onCloseCallbackReceivedCallback: (() -> Void)?
    var onCloseCallbackReturnValue: String!
    var onCloseCallbackClosure: ((@escaping () -> Void) -> String)?

    override func onClose(callback: @escaping () -> Void) -> String {
        onCloseCallbackCallsCount += 1
        onCloseCallbackReceivedCallback = callback
        return onCloseCallbackClosure.map({ $0(callback) }) ?? makeRefReturnValue
    }


    //MARK: - delegateOnClose<T: AnyObject>

    var delegateOnCloseToCallbackCallsCount = 0
    var delegateOnCloseToCallbackCalled: Bool {
        return delegateOnCloseToCallbackCallsCount > 0
    }
    var delegateOnCloseToCallbackReturnValue: String!

    override func delegateOnClose<T: AnyObject>(to owner: T,
                                            callback: @escaping ((T) -> Void)) -> String {
        delegateOnCloseToCallbackCallsCount += 1
        return makeRefReturnValue
    }


    //MARK: - onError

    var onErrorCallbackCallsCount = 0
    var onErrorCallbackCalled: Bool {
        return onErrorCallbackCallsCount > 0
    }
    var onErrorCallbackReceivedCallback: ((Error) -> Void)?
    var onErrorCallbackReturnValue: String!
    var onErrorCallbackClosure: ((@escaping (Error) -> Void) -> String)?

    override func onError(callback: @escaping (Error) -> Void) -> String {
        onErrorCallbackCallsCount += 1
        onErrorCallbackReceivedCallback = callback
        return onErrorCallbackClosure.map({ $0(callback) }) ?? makeRefReturnValue
    }


    //MARK: - delegateOnError<T: AnyObject>

    var delegateOnErrorToCallbackCallsCount = 0
    var delegateOnErrorToCallbackCalled: Bool {
        return delegateOnErrorToCallbackCallsCount > 0
    }
    var delegateOnErrorToCallbackReturnValue: String!

    override func delegateOnError<T: AnyObject>(to owner: T,
                                            callback: @escaping ((T, Error) -> Void)) -> String {
        delegateOnErrorToCallbackCallsCount += 1
        return makeRefReturnValue
    }


    //MARK: - onMessage

    var onMessageCallbackCallsCount = 0
    var onMessageCallbackCalled: Bool {
        return onMessageCallbackCallsCount > 0
    }
    var onMessageCallbackReceivedCallback: ((Message) -> Void)?
    var onMessageCallbackReturnValue: String!
    var onMessageCallbackClosure: ((@escaping (Message) -> Void) -> String)?

    override func onMessage(callback: @escaping (Message) -> Void) -> String {
        onMessageCallbackCallsCount += 1
        onMessageCallbackReceivedCallback = callback
        return onMessageCallbackClosure.map({ $0(callback) }) ?? makeRefReturnValue
    }


    //MARK: - delegateOnMessage<T: AnyObject>

    var delegateOnMessageToCallbackCallsCount = 0
    var delegateOnMessageToCallbackCalled: Bool {
        return delegateOnMessageToCallbackCallsCount > 0
    }
    var delegateOnMessageToCallbackReturnValue: String!

    override func delegateOnMessage<T: AnyObject>(to owner: T,
                                              callback: @escaping ((T, Message) -> Void)) -> String {
        delegateOnMessageToCallbackCallsCount += 1
        return makeRefReturnValue
    }


    //MARK: - releaseCallbacks

    var releaseCallbacksCallsCount = 0
    var releaseCallbacksCalled: Bool {
        return releaseCallbacksCallsCount > 0
    }
    var releaseCallbacksClosure: (() -> Void)?

    override func releaseCallbacks() {
        releaseCallbacksCallsCount += 1
        releaseCallbacksClosure?()
    }


    //MARK: - channel

    var channelParamsCallsCount = 0
    var channelParamsCalled: Bool {
        return channelParamsCallsCount > 0
    }
    var channelParamsReceivedArguments: (topic: String, params: [String: Any])?
    var channelParamsReturnValue: Channel!
    var channelParamsClosure: ((String, [String: Any]) -> Channel)?

    override func channel(_ topic: String,
                      params: [String: Any] = [:]) -> Channel {
        channelParamsCallsCount += 1
    channelParamsReceivedArguments = (topic: topic, params: params)
        return channelParamsClosure.map({ $0(topic, params) }) ?? channelParamsReturnValue
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
        removeClosure?(channel)
    }


    //MARK: - off

    var offCallsCount = 0
    var offCalled: Bool {
        return offCallsCount > 0
    }
    var offReceivedRefs: [String]?
    var offClosure: (([String]) -> Void)?

    override func off(_ refs: [String]) {
        offCallsCount += 1
        offReceivedRefs = refs
        offClosure?(refs)
    }


    //MARK: - push

    var pushTopicEventPayloadRefJoinRefCallsCount = 0
    var pushTopicEventPayloadRefJoinRefCalled: Bool {
        return pushTopicEventPayloadRefJoinRefCallsCount > 0
    }
    var pushTopicEventPayloadRefJoinRefReceivedArguments: (topic: String, event: String, payload: Payload, ref: String?, joinRef: String?)?
    var pushTopicEventPayloadRefJoinRefClosure: ((String, String, Payload, String?, String?) -> Void)?

    override func push(topic: String,
                     event: String,
                     payload: Payload,
                     ref: String? = nil,
                     joinRef: String? = nil) {
        pushTopicEventPayloadRefJoinRefCallsCount += 1
    pushTopicEventPayloadRefJoinRefReceivedArguments = (topic: topic, event: event, payload: payload, ref: ref, joinRef: joinRef)
        pushTopicEventPayloadRefJoinRefClosure?(topic, event, payload, ref, joinRef)
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
        return makeRefClosure.map({ $0() }) ?? makeRefReturnValue
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
        logItemsClosure?(items)
    }


    //MARK: - onConnectionOpen

    var onConnectionOpenCallsCount = 0
    var onConnectionOpenCalled: Bool {
        return onConnectionOpenCallsCount > 0
    }
    var onConnectionOpenClosure: (() -> Void)?

    override func onConnectionOpen() {
        onConnectionOpenCallsCount += 1
        onConnectionOpenClosure?()
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
        onConnectionClosedCodeClosure?(code)
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
        onConnectionErrorClosure?(error)
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
        onConnectionMessageClosure?(rawMessage)
    }


    //MARK: - triggerChannelError

    var triggerChannelErrorCallsCount = 0
    var triggerChannelErrorCalled: Bool {
        return triggerChannelErrorCallsCount > 0
    }
    var triggerChannelErrorClosure: (() -> Void)?

    override func triggerChannelError() {
        triggerChannelErrorCallsCount += 1
        triggerChannelErrorClosure?()
    }


    //MARK: - flushSendBuffer

    var flushSendBufferCallsCount = 0
    var flushSendBufferCalled: Bool {
        return flushSendBufferCallsCount > 0
    }
    var flushSendBufferClosure: (() -> Void)?

    override func flushSendBuffer() {
        flushSendBufferCallsCount += 1
        flushSendBufferClosure?()
    }


    //MARK: - removeFromSendBuffer

    var removeFromSendBufferRefCallsCount = 0
    var removeFromSendBufferRefCalled: Bool {
        return removeFromSendBufferRefCallsCount > 0
    }
    var removeFromSendBufferRefReceivedRef: String?
    var removeFromSendBufferRefClosure: ((String) -> Void)?

    override func removeFromSendBuffer(ref: String) {
        removeFromSendBufferRefCallsCount += 1
        removeFromSendBufferRefReceivedRef = ref
        removeFromSendBufferRefClosure?(ref)
    }


    //MARK: - leaveOpenTopic

    var leaveOpenTopicTopicCallsCount = 0
    var leaveOpenTopicTopicCalled: Bool {
        return leaveOpenTopicTopicCallsCount > 0
    }
    var leaveOpenTopicTopicReceivedTopic: String?
    var leaveOpenTopicTopicClosure: ((String) -> Void)?

    override func leaveOpenTopic(topic: String) {
        leaveOpenTopicTopicCallsCount += 1
        leaveOpenTopicTopicReceivedTopic = topic
        leaveOpenTopicTopicClosure?(topic)
    }


    //MARK: - resetHeartbeat

    var resetHeartbeatCallsCount = 0
    var resetHeartbeatCalled: Bool {
        return resetHeartbeatCallsCount > 0
    }
    var resetHeartbeatClosure: (() -> Void)?

    override func resetHeartbeat() {
        resetHeartbeatCallsCount += 1
        resetHeartbeatClosure?()
    }


    //MARK: - sendHeartbeat

    var sendHeartbeatCallsCount = 0
    var sendHeartbeatCalled: Bool {
        return sendHeartbeatCallsCount > 0
    }
    var sendHeartbeatClosure: (() -> Void)?

    override func sendHeartbeat() {
        sendHeartbeatCallsCount += 1
        sendHeartbeatClosure?()
    }


    //MARK: - abnormalClose

    var abnormalCloseCallsCount = 0
    var abnormalCloseCalled: Bool {
        return abnormalCloseCallsCount > 0
    }
    var abnormalCloseReceivedReason: String?
    var abnormalCloseClosure: ((String) -> Void)?

    override func abnormalClose(_ reason: String) {
        abnormalCloseCallsCount += 1
        abnormalCloseReceivedReason = reason
        abnormalCloseClosure?(reason)
    }


    //MARK: - onOpen

    var onOpenCallsCount = 0
    var onOpenCalled: Bool {
        return onOpenCallsCount > 0
    }
    var onOpenClosure: (() -> Void)?

    override func onOpen() {
        onOpenCallsCount += 1
        onOpenClosure?()
    }


    //MARK: - onError

    var onErrorErrorCallsCount = 0
    var onErrorErrorCalled: Bool {
        return onErrorErrorCallsCount > 0
    }
    var onErrorErrorReceivedError: Error?
    var onErrorErrorClosure: ((Error) -> Void)?

    override func onError(error: Error) {
        onErrorErrorCallsCount += 1
        onErrorErrorReceivedError = error
        onErrorErrorClosure?(error)
    }


    //MARK: - onMessage

    var onMessageMessageCallsCount = 0
    var onMessageMessageCalled: Bool {
        return onMessageMessageCallsCount > 0
    }
    var onMessageMessageReceivedMessage: String?
    var onMessageMessageClosure: ((String) -> Void)?

    override func onMessage(message: String) {
        onMessageMessageCallsCount += 1
        onMessageMessageReceivedMessage = message
        onMessageMessageClosure?(message)
    }


    //MARK: - onClose

    var onCloseCodeCallsCount = 0
    var onCloseCodeCalled: Bool {
        return onCloseCodeCallsCount > 0
    }
    var onCloseCodeReceivedCode: Int?
    var onCloseCodeClosure: ((Int) -> Void)?

    override func onClose(code: Int) {
        onCloseCodeCallsCount += 1
        onCloseCodeReceivedCode = code
        onCloseCodeClosure?(code)
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
    override var queue: TimerQueue {
        get { return underlyingQueue }
        set(value) { underlyingQueue = value }
    }
    var underlyingQueue: (TimerQueue)!


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


}
