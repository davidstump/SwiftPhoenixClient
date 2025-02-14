//
//  SocketTest.swift
//  SwiftPhoenixClientTests
//
//  Created by Daniel Rees on 10/28/24.
//  Copyright © 2024 SwiftPhoenixClient. All rights reserved.
//

import Foundation
import Testing
@testable import SwiftPhoenixClient

struct SocketTest {
    
    private func setupSocket(readyState: TransportReadyState = .closed,
                             endpoint: String = "/socket") -> (Socket, TransportMock) {
        let mockTransport = TransportMock()
        mockTransport.readyState = readyState
        
        let socket = Socket(endPoint: endpoint) { _ in return mockTransport }
        
        return (socket, mockTransport)
    }
    
    // MARK: -- constructor --
    @Test func constructor_sets_defaults() async throws {
        let socket = Socket("wss://localhost:4000/socket")
        
        #expect(socket.channels.count == 0)
        #expect(socket.sendBuffer.count == 0)
        #expect(socket.ref == 0)
        #expect(socket.endPoint == "wss://localhost:4000/socket")
        #expect(socket.stateChangeCallbacks.open.isEmpty)
        #expect(socket.stateChangeCallbacks.close.isEmpty)
        #expect(socket.stateChangeCallbacks.error.isEmpty)
        #expect(socket.stateChangeCallbacks.message.isEmpty)
        #expect(socket.timeout == Defaults.timeoutInterval)
        #expect(socket.heartbeatInterval == Defaults.heartbeatInterval)
    }
    
    @Test func constructor_supports_closure_or_literal_params() async throws {
        let literalSocket = Socket("wss://localhost:4000/socket", params: ["one": "two"])
        #expect(literalSocket.params?["one"] as? String == "two")
        
        var authToken = "abc123"
        let closueSocket = Socket("wss://localhost:4000/socket", params: { ["token": authToken] } )
        #expect(closueSocket.params?["token"] as? String == "abc123")
        
        authToken = "xyz987"
        #expect(closueSocket.params?["token"] as? String == "xyz987")
    }
    
    // MARK: -- websocketProtocol --
    @Test func websocketProtocol_returns_wss_when_given_https() async throws {
        let socket = Socket("https://example.com/")
        #expect(socket.websocketProtocol == "wss")
    }
    
    @Test func websocketProtocol_returns_wss_when_given_wss() async throws {
        let socket = Socket("wss://example.com/")
        #expect(socket.websocketProtocol == "wss")
    }
    
    @Test func websocketProtocol_returns_ws_when_given_http() async throws {
        let socket = Socket("http://example.com/")
        #expect(socket.websocketProtocol == "ws")
    }
    
    @Test func websocketProtocol_returns_ws_when_given_ws() async throws {
        let socket = Socket("ws://example.com/")
        #expect(socket.websocketProtocol == "ws")
    }
    
    @Test func websocketProtocol_returns_nil_if_there_is_no_schema() async throws {
        let socket = Socket("example.com/")
        #expect(socket.websocketProtocol == "ws")
    }
    
    // MARK: -- endPointUrl --
    @Test func endPointUrl_constructs_valid_url() async throws {
        // Full URL
        #expect(Socket("wss://example.com/websocket")
            .endPointUrl.absoluteString == "wss://example.com/websocket?vsn=2.0.0")
        
        // Appends `/websocket`
        #expect(Socket("https://example.com/chat")
            .endPointUrl.absoluteString == "wss://example.com/chat/websocket?vsn=2.0.0")
        
        // Appends `/websocket`, accounting for trailing `/`
        #expect(Socket("ws://example.com/chat/")
            .endPointUrl.absoluteString == "ws://example.com/chat/websocket?vsn=2.0.0")
        
        // Appends `params`
        #expect(Socket("http://example.com/chat", params: ["token": "abc123"])
            .endPointUrl.absoluteString == "ws://example.com/chat/websocket?vsn=2.0.0&token=abc123")
    }
    
    // MARK: -- connectWithWebsocket ---
    @Test func connectWithWebsocket_establishes_websocket_connection_with_endpoint() {
        let (socket, _) = setupSocket()
        
        socket.connect()
        #expect(socket.connection != nil)
    }
    
    @Test func connectWithWebsocket_sets_callbacks_for_connection() {
        let (socket, mockTransport) = setupSocket()
        
        var open = 0
        socket.onOpen { open += 1 }
        
        var close = 0
        socket.onClose { close += 1 }
        
        var lastError: Error?
        socket.onError { error, _ in
            lastError = error
        }
        
        var lastMessage: IncomingMessage?
        socket.onMessage(callback: { (message) in
            lastMessage = message
        }
        )
        
        mockTransport.readyState = .closed
        socket.connect()
        
        mockTransport.delegate?.onOpen(response: nil)
        mockTransport.delegate?.onClose(code: .normalClosure, reason: nil)
        mockTransport.delegate?.onError(error: TestError.stub, response: nil)
        
        let text = """
        [null,null,"topic","event","payload"]
        """
        mockTransport.delegate?.onMessage(string: text)
        
        // Delegate implementations all runs `.async` which cause there to be a
        // slight out-of-ordering. Sleep 1 second to let everything hit
        Thread.sleep(forTimeInterval: 0.2) // syncarray runs on .async
        #expect(open == 1)
        #expect(close == 1)
        #expect(lastError != nil)
        
        let parser = JsonPayloadParser()
        let parseResult = parser.parse(lastMessage!,
                                       payloadDecoder: socket.decoder,
                                       payloadEncoder: socket.encoder)
        let payload = try! parseResult.get() as! String
        #expect(payload == "payload")
    }
    
    @Test func connectWithWebsocket_does_not_connect_if_already_connected() {
        let (socket, mockTransport) = setupSocket()
        
        socket.connect()
        mockTransport.readyState = .open
        
        socket.connect()
        
        #expect(mockTransport.connectWithCallsCount == 1)
    }
    
    // TODO: Long Poll
    // MARK: -- connectWithLongPoll ---
    
    @Test func disconnect_removes_existing_connection() async throws {
        let (socket, mockTransport) = setupSocket()
        
        socket.connect()
        socket.disconnect()
        
        #expect(socket.connection == nil)
        #expect(mockTransport.disconnectCodeReasonReceivedArguments?.code
                == URLSessionWebSocketTask.CloseCode.normalClosure)
    }
    
    @Test func disconnect_calls_callback() async throws {
        let (socket, mockTransport) = setupSocket()
        socket.connect()
        
        var count = 0
        socket.disconnect(code: .goingAway) {
            count += 1
        }
        
        #expect(mockTransport.disconnectCodeReasonCalled)
        #expect(mockTransport.disconnectCodeReasonReceivedArguments?.code == .goingAway)
        #expect(mockTransport.disconnectCodeReasonReceivedArguments?.reason == nil)
        #expect(count == 1)
    }
    
    @Test func disconnect_calls_onClose_state_callbacks() async throws {
        let (socket, _) = setupSocket()
        
        var count =  0
        socket.onClose {
            count += 1
        }
        
        socket.disconnect()
        #expect(count == 1)
    }
    
    @Test func disconnect_invalidates_the_heartbeat_timer() async throws {
        let (socket, _) = setupSocket()
        
        var count = 0
        let queue = DispatchQueue(label: "test.heartbeat")
        let timer = HeartbeatTimer(timeInterval: 10, queue: queue)
        
        timer.start { count += 1 }
        
        socket.heartbeatTimer = timer
        
        socket.disconnect()
        #expect(socket.heartbeatTimer?.isValid == false)
        timer.fire()
        #expect(count == 0)
    }
    
    @Test func disconnect_does_nothing_if_not_connected() async throws {
        let (socket, mockTransport) = setupSocket()
        
        socket.disconnect()
        #expect(mockTransport.disconnectCodeReasonCalled == false)
    }
    
    // MARK: -- isConnected & connectionState --
    @Test func connectionState_defaults_to_closed() async throws {
        let (socket, _) = setupSocket()
        #expect(socket.isConnected == false)
        #expect(socket.connectionState == .closed)
    }
    
    @Test func connectionState_returns_connecting() async throws {
        let (socket, _) = setupSocket(readyState: .connecting)
        socket.connect()
        
        #expect(socket.isConnected == false)
        #expect(socket.connectionState == .connecting)
    }
    
    @Test func connectionState_returns_open() async throws {
        let (socket, _) = setupSocket(readyState: .open)
        socket.connect()
        
        #expect(socket.isConnected == true)
        #expect(socket.connectionState == .open)
    }
    @Test func connectionState_returns_closing() async throws {
        let (socket, _) = setupSocket(readyState: .closing)
        socket.connect()
        
        #expect(socket.isConnected == false)
        #expect(socket.connectionState == .closing)
    }
    @Test func connectionState_returns_closed() async throws {
        let (socket, _) = setupSocket(readyState: .closed)
        socket.connect()
        
        #expect(socket.isConnected == false)
        #expect(socket.connectionState == .closed)
    }
    
    // MARK: -- channel --
    @Test func channel_returns_channel_with_given_topic_and_params() async throws {
        let (socket, _) = setupSocket()
        
        let channel = socket.channel("topic", params: ["one": "two"])
        #expect(channel.socket === socket)
        #expect(channel.topic == "topic")
        #expect(channel.params["one"] as? String == "two")
    }
    
    @Test func channel_adds_channel_to_sockets_channel_list() async throws {
        let (socket, _) = setupSocket()
        
        #expect(socket.channels.isEmpty)
        
        let channel = socket.channel("topic", params: ["one": "two"])
        #expect(socket.channels.count == 1)
        #expect(socket.channels.first === channel)
    }
    
    // MARK: -- remove --
    @Test func remove_removes_given_channel_from_channels() throws {
        let (socket, _) = setupSocket()
        
        let channel1 = socket.channel("topic-1")
        let channel2 = socket.channel("topic-2")
        
        
        channel1.joinPush.ref = "1"
        channel2.joinPush.ref = "2"
        
        Thread.sleep(forTimeInterval: 0.2) // syncarray runs on .async
        #expect(socket.stateChangeCallbacks.open.count == 2)
        
        socket.remove(channel1)
        Thread.sleep(forTimeInterval: 0.2) // syncarray runs on .async
        #expect(socket.stateChangeCallbacks.open.count == 1)
        
        #expect(socket.channels.count == 1)
        #expect(socket.channels.first === channel2)
    }
    
    // MARK: -- push --
    @Test func push_sends_string_to_connection_when_conneted() throws {
        let (socket, mockTransport) = setupSocket()
        
        socket.connect()
        mockTransport.readyState = .open
        
        let outgoing = buildOutgoingMessage(ref: "ref",
                                            topic: "topic",
                                            event: "event",
                                            payload: .json("payload"))
        socket.push(outgoing: outgoing)
        #expect(mockTransport.sendStringCalled)
        let actual = mockTransport.sendStringReceivedString
        
        let expected = """
        [null,"ref","topic","event","payload"]
        """
        
        #expect(actual == expected)
    }
    
    @Test func push_sends_binary_when_connected() async throws {
        let (socket, mockTransport) = setupSocket()
        
        socket.connect()
        mockTransport.readyState = .open
        
        let outgoing = buildOutgoingMessage(joinRef: "0",
                                            ref: "1",
                                            topic: "t",
                                            event: "e",
                                            payload: .binary(Data([0x01])))
        socket.push(outgoing: outgoing)
        #expect(mockTransport.sendDataCalled)
        let data = mockTransport.sendDataReceivedData!
        let actual = [UInt8](data)
        let expected: [UInt8] = [0x00, 0x01, 0x01, 0x01, 0x01]
        + "01te".utf8.map { UInt8($0) }
        + [0x01]
        
        
        #expect(actual == expected)
    }
    
    @Test func push_buffers_messages_when_not_conneted() throws {
        let (socket, mockTransport) = setupSocket()
        socket.connect()
        #expect(socket.sendBuffer.isEmpty)
        
        let outgoing = buildOutgoingMessage(ref: "ref",
                                            topic: "topic",
                                            event: "event",
                                            payload: .json("payload"))
        socket.push(outgoing: outgoing)
        #expect(mockTransport.sendStringCalled == false)
        #expect(mockTransport.sendDataCalled == false)
        Thread.sleep(forTimeInterval: 0.2) // syncarray runs on .async
        #expect(socket.sendBuffer.count == 1)
        
        socket.sendBuffer.forEach( { try? $0.callback() } )
        #expect(mockTransport.sendStringCallsCount == 1)
        let actual = mockTransport.sendStringReceivedString
        
        let expected = """
        [null,"ref","topic","event","payload"]
        """
        
        #expect(actual == expected)
    }
    
    // MARK: -- makeRef --
    @Test func makeRef_returns_next_message_ref() throws {
        let (socket, _) = setupSocket()
        
        #expect(socket.ref == 0)
        #expect(socket.makeRef() == "1")
        #expect(socket.ref == 1)
        #expect(socket.makeRef() == "2")
        #expect(socket.ref == 2)
    }
    
    @Test func makeRef_resets_after_overflow() async throws {
        let (socket, _) = setupSocket()
        socket.ref = UInt64.max
        
        #expect(socket.makeRef() == "0")
        #expect(socket.ref == 0)
    }
    
    // MARK: -- sendHeartbeat --
    @Test func sendHeartbeat_closes_socket_if_heartbeat_not_ackd_within_window() throws {
        //        let (socket, mockTransport) = setupSocket()
        //
        //        var closed = false
        //        socket.connect()
        //        mockTransport.readyState = .open
        
        // TODO: Mock Heartbeat Timer
        // TODO: Can timers be converted to task sleep with fake clock?
    }
    
    @Test func sendHeartbeat_pushes_heartbeat_data_when_connected() async throws {
        let (socket, mockTransport) = setupSocket()
        socket.connect()
        mockTransport.readyState = .open
        
        socket.sendHeartbeat()
        
        #expect(mockTransport.sendStringCalled == true)
        let actual = mockTransport.sendStringReceivedString
        
        let expected = """
        [null,"\(socket.pendingHeartbeatRef!)","phoenix","heartbeat",{}]
        """
        
        #expect(actual == expected)
    }
    
    @Test func sendHeartbeat_does_nothing_when_not_connected() throws {
        let (socket, mockTransport) = setupSocket()
        socket.sendHeartbeat()
        
        #expect(mockTransport.disconnectCodeReasonCalled == false)
        #expect(mockTransport.sendDataCalled == false)
        #expect(mockTransport.sendStringCalled == false)
    }
    
    // MARK: -- flushSendBuffer --
    @Test func flushSendBuffer_calls_callbacks_in_buffer_when_connected() throws {
        let (socket, mockTransport) = setupSocket()
        socket.connect()
        mockTransport.readyState = .open
        
        var oneCalled = 0
        socket.sendBuffer.append(("0", { oneCalled += 1 }))
        var twoCalled = 0
        socket.sendBuffer.append(("1", { twoCalled += 1 }))
        let threeCalled = 0
        
        socket.flushSendBuffer()
        #expect(oneCalled == 1)
        #expect(twoCalled == 1)
        #expect(threeCalled == 0)
    }
    
    @Test func flushSendBuffer_empties_send_buffer() throws {
        let (socket, mockTransport) = setupSocket()
        socket.connect()
        mockTransport.readyState = .open
        
        socket.sendBuffer.append(("0", { }))
        
        Thread.sleep(forTimeInterval: 0.2) // syncarray runs on .async
        #expect(socket.sendBuffer.count == 1)
        
        socket.flushSendBuffer()
        Thread.sleep(forTimeInterval: 0.2) // syncarray runs on .async
        #expect(socket.sendBuffer.count == 0)
    }
    
    // MARK: -- removeFromSendBuffer --
    @Test func removeFromSendBuffer_removes_a_callback_with_a_matching_ref() async throws {
        let (socket, mockTransport) = setupSocket()
        socket.connect()
        mockTransport.readyState = .open
        
        var oneCalled = 0
        socket.sendBuffer.append(("0", { oneCalled += 1 }))
        var twoCalled = 0
        socket.sendBuffer.append(("1", { twoCalled += 1 }))
        let threeCalled = 0
        
        socket.connect()
        mockTransport.readyState = .open
        
        socket.removeFromSendBuffer(ref: "0")
        
        socket.flushSendBuffer()
        #expect(oneCalled == 0)
        #expect(twoCalled == 1)
        #expect(threeCalled == 0)
    }
    
    // MARK: -- onConnectionOpen --
    @Test func onConnectionOpen_flushes_the_send_buffer() throws {
        let (socket, mockTransport) = setupSocket()
        
        var oneCalled = 0
        socket.sendBuffer.append(("0", { oneCalled += 1 }))
        
        socket.connect()
        mockTransport.readyState = .open
        
        socket.onConnectionOpen(response: nil)
        Thread.sleep(forTimeInterval: 0.2) // syncarray runs on .async
        #expect(socket.sendBuffer.isEmpty)
    }
    
    @Test func onConnectionOpen_resets_reconnect_timer() throws {
        let (socket, mockTransport) = setupSocket()
        let mockTimer = ScheduleTimerMock()
        socket.reconnectTimer = mockTimer
        
        socket.connect()
        mockTransport.readyState = .open
        
        socket.onConnectionOpen(response: nil)
        #expect(mockTimer.resetCalled)
    }
    
    @Test func onConnectionOpen_resets_heartbeat() throws {
        let (socket, mockTransport) = setupSocket()
        socket.pendingHeartbeatRef = "1"
        
        socket.connect()
        mockTransport.readyState = .open
        
        socket.onConnectionOpen(response: nil)
        #expect(socket.pendingHeartbeatRef == nil)
    }
    
    @Test func onConnectionOpen_triggers_onOpen_callbacks() async throws {
        let (socket, mockTransport) = setupSocket()
        socket.connect()
        mockTransport.readyState = .open
        
        
        var oneCalled = 0
        socket.onOpen { oneCalled += 1 }
        var twoCalled = 0
        socket.onOpen { twoCalled += 1 }
        var threeCalled = 0
        socket.onClose { threeCalled += 1 }
        
        socket.onConnectionOpen(response: nil)
        #expect(oneCalled == 1)
        #expect(twoCalled == 1)
        #expect(threeCalled == 0)
    }
    
    // MARK: -- resetHeartbeat --
    @Test func resetHeartbeat_clears_any_pending_heartbeat() async throws {
        let (socket, _) = setupSocket()
        socket.pendingHeartbeatRef = "1"
        
        socket.onConnectionOpen(response: nil)
        #expect(socket.pendingHeartbeatRef == nil)
    }
    
    @Test func resetHeartbeat_does_not_schedule_if_skipHeartbeat_is_true() async throws {
        let (socket, _) = setupSocket()
        socket.skipHeartbeat = true
        socket.resetHeartbeat()
        
        #expect(socket.heartbeatTimer == nil)
    }
    
    @Test func resetHeartbeat_creates_a_timer_and_sends_a_heartbeat() async throws {
        let (socket, mockTransport) = setupSocket()
        socket.heartbeatInterval = 1
        
        socket.connect()
        mockTransport.readyState = .open
        
        #expect(socket.heartbeatTimer == nil)
        socket.resetHeartbeat()
        
        #expect(socket.heartbeatTimer != nil)
        #expect(socket.heartbeatTimer?.timeInterval == 1)
        
        // Fire the timer manually. HeartbeatTimer has its own tests
        socket.heartbeatTimer?.fire()
        #expect(mockTransport.sendStringCalled)
    }
    
    @Test func resetHeartbeat_invalidates_old_timer_and_creates_new_one() async throws {
        let (socket, _) = setupSocket()
        let queue = DispatchQueue(label: "test.heartbeat")
        let timer = HeartbeatTimer(timeInterval: 1000, queue: queue)
        
        var timerCalled = 0
        timer.start { timerCalled += 1 }
        socket.heartbeatTimer = timer
        
        #expect(timer.isValid)
        socket.resetHeartbeat()
        
        #expect(timer.isValid == false)
        #expect(socket.heartbeatTimer !== timer)
        #expect(timerCalled == 0)
    }
    
    // MARK: -- onConnectionClosed --
    @Test func onConnectionClosed_does_not_schedule_reconnectTimer_if_normal_close() async throws {
        let (socket, mockTransport) = setupSocket()
        let mockTimer = ScheduleTimerMock()
        socket.reconnectTimer = mockTimer
        
        socket.connect()
        mockTransport.readyState = .open
        
        socket.onConnectionClosed(code: .normalClosure, reason: nil)
        #expect(mockTimer.scheduleTimeoutCalled == false)
    }
    
    @Test func onConnectionClosed_schedules_reconnectTimer_timeout_if_abnormal_clos() async throws {
        let (socket, mockTransport) = setupSocket()
        let mockTimer = ScheduleTimerMock()
        socket.reconnectTimer = mockTimer
        
        socket.connect()
        mockTransport.readyState = .open
        
        socket.onConnectionClosed(code: .abnormalClosure, reason: nil)
        #expect(mockTimer.scheduleTimeoutCalled)
    }
    
    @Test("onConnectionClosed does not schedule reconnectTimer timeout if normal close after explicit disconnect")
    func onConnectionClosed_does_not_schedule_after_explicit_close() throws {
        
        let (socket, _) = setupSocket()
        let mockTimer = ScheduleTimerMock()
        socket.reconnectTimer = mockTimer
        
        socket.disconnect()
        socket.onConnectionClosed(code: .goingAway, reason: nil)
        #expect(mockTimer.scheduleTimeoutCalled == false)
    }
    
    @Test func onConnectionClosed_schedules_reconnectTimer_timeout_if_not_normal_close() throws {
        let (socket, _) = setupSocket()
        let mockTimer = ScheduleTimerMock()
        socket.reconnectTimer = mockTimer

        socket.onConnectionClosed(code: .goingAway, reason: nil)
        #expect(mockTimer.scheduleTimeoutCalled == true)
    }
    
    @Test("onConnectionClosed schedules reconnectTimer timeout if connection cannot be made after a previous clean disconnect")
    func onConnectionClosed_schedules_reconnectTimer_connect_after_disconnect() throws {
        let (socket, _) = setupSocket()
        let mockTimer = ScheduleTimerMock()
        socket.reconnectTimer = mockTimer
        
        socket.disconnect()
        socket.connect()
        
        socket.onConnectionClosed(code: .goingAway, reason: nil)
        #expect(mockTimer.scheduleTimeoutCalled == true)
    }
    
    @Test func onConnectionClosed_triggers_on_close_callbacks() async throws {
        let (socket, _) = setupSocket()
        var oneCalled = 0
        socket.onClose { oneCalled += 1 }
        var twoCalled = 0
        socket.onClose { twoCalled += 1 }
        var threeCalled = 0
        socket.onOpen { threeCalled += 1 }
        
        socket.onConnectionClosed(code: .normalClosure, reason: nil)
        #expect(oneCalled == 1)
        #expect(twoCalled == 1)
        #expect(threeCalled == 0)
    }
    
    @Test func onConnectionClosed_triggers_channel_error_if_joining() async throws {
        let (socket, _) = setupSocket()
        let channel = socket.channel("topic")
        var errorMessage: ChannelMessage<Any>? = nil
        channel.on(ChannelEvent.error) { errorMessage = $0 }
        
        channel.join()
        #expect(channel.state == .joining)
        
        socket.onConnectionClosed(code: .goingAway, reason: nil)
        #expect(errorMessage?.event == "phx_error")
    }
    
    @Test func onConnectionClosed_triggers_channel_error_if_joined() async throws {
        let (socket, _) = setupSocket()
        let channel = socket.channel("topic")
        var errorMessage: ChannelMessage<Any>? = nil
        channel.on(ChannelEvent.error) { errorMessage = $0 }
        
        channel.join().trigger("ok", payload: [:])
        #expect(channel.state == .joined)
        
        socket.onConnectionClosed(code: .goingAway, reason: nil)
        #expect(errorMessage?.event == "phx_error")
    }
    
    @Test func onConnectionClosed_does_not_triggers_channel_error_after_leave() throws {
        let (socket, _) = setupSocket()
        let channel = socket.channel("topic")
        
        var errorMessage: ChannelMessage<Any>? = nil
        channel.on(ChannelEvent.error) { errorMessage = $0 }
        
        channel.join().trigger("ok", payload: [:])
        channel.leave().trigger("ok", payload: [:])
        #expect(channel.state == .closed)
        
        socket.onConnectionClosed(code: .goingAway, reason: nil)
        #expect(errorMessage == nil)
    }
    
    @Test func onConnectionClosed_does_not_send_heartbeats_after_disconnect() async throws {
        // TODO: Mock Heartbeat Timer
    }
    
    @Test func onConnectionClosed_does_timeout_the_heartbeat_after_disconnect() async throws {
        // TODO: Mock Heartbeat Timer
    }
    
    // MARK: -- onConnectionError --
    @Test func onConnectionError_triggers_onClose_callback() async throws {
        let (socket, _) = setupSocket()
        
        var lastError: Error? = nil
        var lastResponse: URLResponse? = nil
        socket.onError { error, response in
            lastError = error
            lastResponse = response
        }

        socket.onConnectionError(TestError.stub, response: URLResponse())
        #expect(lastError != nil)
        #expect(lastResponse != nil)
    }
    
    @Test func onConnectionError_triggers_channel_error_if_joining_with_open_connection() async throws {
        let (socket, _) = setupSocket()
        let channel = socket.channel("topic")
        
        var errorMessage: ChannelMessage<Any>? = nil
        channel.on(ChannelEvent.error) { errorMessage = $0 }
        
        channel.join()
        socket.onConnectionOpen(response: nil)
        #expect(channel.state == .joining)
        
        socket.onConnectionError(TestError.stub, response: nil)
        #expect(errorMessage?.event == "phx_error")
    }
    
    @Test func onConnectionError_triggers_channel_error_if_joining_with_no_connection() async throws {
        let (socket, _) = setupSocket()
        let channel = socket.channel("topic")
        
        var errorMessage: ChannelMessage<Any>? = nil
        channel.on(ChannelEvent.error) { errorMessage = $0 }
        
        channel.join()
        #expect(channel.state == .joining)
        
        socket.onConnectionError(TestError.stub, response: nil)
        #expect(errorMessage?.event == "phx_error")
    }
    
    @Test func onConnectionError_triggers_channel_error_if_joined() async throws {
        let (socket, _) = setupSocket()
        let channel = socket.channel("topic")
        
        var errorMessage: ChannelMessage<Any>? = nil
        channel.on(ChannelEvent.error) { errorMessage = $0 }
        
        channel.join().trigger("ok", payload: [:])
        socket.onConnectionOpen(response: nil)
        #expect(channel.state == .joined)
        
        socket.onConnectionError(TestError.stub, response: nil)
        #expect(errorMessage?.event == "phx_error")
    }
    
    
    @Test func onConnectionError_does_not_trigger_channel_error_after_leave() async throws {
        let (socket, _) = setupSocket()
        let channel = socket.channel("topic")
        
        var errorMessage: ChannelMessage<Any>? = nil
        channel.on(ChannelEvent.error) { errorMessage = $0 }
        
        channel.join().trigger("ok", payload: [:])
        channel.leave()
        #expect(channel.state == .closed)
        
        socket.onConnectionError(TestError.stub, response: nil)
        #expect(errorMessage == nil)
    }
    
    // MARK: -- onConnectionMessage --
    @Test func onConnectionMessage_parses_raw_message_and_triggers_channel_event() throws {
        let (socket, _) = setupSocket()
        let targetChannel = socket.channel("topic")
        let otherChannel = socket.channel("off-topic")
        
        var targetMessage: ChannelMessage<Any>? = nil
        targetChannel.on("event") { msg in
            targetMessage = msg
        }
        
        var otherMessage: ChannelMessage<Any>? = nil
        otherChannel.on("event") { otherMessage = $0 }
        
        let message = """
        [null,"ref","topic","event","payload"]
        """
        // Calling onMessage here since it parses the text first before passing
        // the IncomingMessage through to onConnectionMessage
        socket.onMessage(string: message)
        Thread.sleep(forTimeInterval: 0.2) // syncarray runs on .async
        
        #expect(targetMessage?.ref == "ref")
        #expect(targetMessage?.topic == "topic")
        #expect(targetMessage?.event == "event")
        let payload = try! targetMessage?.payload.get() as! String
        #expect(payload == "payload")
        
        #expect(otherMessage == nil)
    }
    
    @Test func onConnectionMessage_parses_binary_message_and_triggers_channel_event() throws {
        let (socket, _) = setupSocket()
        let targetChannel = socket.channel("top")
        let otherChannel = socket.channel("off-top")
        
        var targetMessage: ChannelMessage<Data>? = nil
        targetChannel.onData("some-event") { msg in
            targetMessage = msg
        }
        
        var otherMessage: ChannelMessage<Data>? = nil
        otherChannel.onData("some-event") { otherMessage = $0 }
        
        let bin: [UInt8] = [0x00, 0x03, 0x03, 0x0A]
        + "123topsome-event".utf8.map { UInt8($0) }
        + [0x01, 0x01]
        
        // Calling onMessage here since it parses the text first before passing
        // the IncomingMessage through to onConnectionMessage
        socket.onMessage(data: Data(bin))
        Thread.sleep(forTimeInterval: 0.2) // syncarray runs on .async
        
        #expect(targetMessage?.joinRef == "123")
        #expect(targetMessage?.ref == nil)
        #expect(targetMessage?.topic == "top")
        #expect(targetMessage?.event == "some-event")
        #expect(targetMessage?.status == nil)
        
        if case .success(let data) = targetMessage?.payload {
            let binary = [UInt8](data)
            #expect(binary == [0x01, 0x01])
        } else {
            fatalError("expected decided payload type")
        }
        
        #expect(otherMessage == nil)
    }
    
    @Test func onConnectionMessage_triggers_onMessage_callbacks() throws {
        let (socket, _) = setupSocket()

        var incomingMessage: IncomingMessage? = nil
        socket.onMessage { incomingMessage = $0 }
        
        let message = """
        [null,"ref","topic","event","payload"]
        """
        
        socket.onMessage(string: message)
        Thread.sleep(forTimeInterval: 0.2) // syncarray runs on .async
        
        #expect(incomingMessage?.topic == "topic")
        #expect(incomingMessage?.event == "event")
        
        if case .deferred(let rawIncomingText) = incomingMessage?.payload {
            #expect(rawIncomingText == message.data(using: .utf8))
        } else {
            fatalError("expected deferred payload type")
        }
    }
    
    @Test func onConnectionMessage_clears_pending_heartbeat() throws {
        let (socket, _) = setupSocket()
        socket.pendingHeartbeatRef = "5"

        let message = """
        [null,"5","phoenix","phx_reply",{"status":"ok","response":{}}]
        """

        socket.onMessage(string: message)
        Thread.sleep(forTimeInterval: 0.5) // syncarray runs on .async
        #expect(socket.pendingHeartbeatRef == nil)
    }
}
