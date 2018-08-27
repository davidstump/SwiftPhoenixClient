//
//  SocketSpec.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 2/10/18.
//

import Quick
import Nimble
import Starscream
@testable import SwiftPhoenixClient

class SocketSpec: QuickSpec {
    
    class FakeWebSocket: WebSocket {
        
        var disconnectCallsCount = 0
        var disconnectCalled: Bool { return disconnectCallsCount > 0 }
        func disconnect() {
            disconnectCallsCount += 1
        }
        
        var connectCallsCount = 0
        var connectCalled: Bool { return connectCallsCount > 0 }
        override func connect() {
            connectCallsCount += 1
        }

    }

    override func spec() {
        
        var fakeConnection: FakeWebSocket!
       
        var socket: Socket!
        var newMsgChannel: Channel!
        var oldMsgChannel: Channel!
        
        beforeEach {
            fakeConnection = FakeWebSocket(url: URL(string: "http://localhost:4000/socket/websocket")!)
            socket = Socket(connection: fakeConnection)
            
            newMsgChannel = socket.channel("new_msg", params: ["token": "abc123"])
            oldMsgChannel = socket.channel("old_msg")
            
        }
        
        describe(".init(url:, params:)") {
            it("should construct a valid URL", closure: {
                
                // Test different schemes
                expect(Socket(url: "http://localhost:4000/socket/websocket")
                    .endpointUrl.absoluteString)
                    .to(equal("http://localhost:4000/socket/websocket"))
                
                expect(Socket(url: "https://localhost:4000/socket/websocket")
                    .endpointUrl.absoluteString)
                    .to(equal("https://localhost:4000/socket/websocket"))
                
                expect(Socket(url: "ws://localhost:4000/socket/websocket")
                    .endpointUrl.absoluteString)
                    .to(equal("ws://localhost:4000/socket/websocket"))
                
                expect(Socket(url: "wss://localhost:4000/socket/websocket")
                    .endpointUrl.absoluteString)
                    .to(equal("wss://localhost:4000/socket/websocket"))
                
                
                // test params
                expect(Socket(url: "ws://localhost:4000/socket/websocket",
                              params: ["token": "abc123"])
                    .endpointUrl.absoluteString)
                    .to(equal("ws://localhost:4000/socket/websocket?token=abc123"))
                
                expect(Socket(url: "ws://localhost:4000/socket/websocket",
                              params: ["token": "abc123", "user_id": 1])
                    .endpointUrl.absoluteString)
                    .to(equal("ws://localhost:4000/socket/websocket?token=abc123&user_id=1"))
                
                
                // test params with spaces
                expect(Socket(url: "ws://localhost:4000/socket/websocket",
                              params: ["token": "abc 123", "user_id": 1])
                    .endpointUrl.absoluteString)
                    .to(equal("ws://localhost:4000/socket/websocket?token=abc%20123&user_id=1"))
            })

            it("should not introduce any retain cycles", closure: {
                weak var socket = Socket(url: "http://localhost:4000/socket/websocket")
                expect(socket).to(beNil())
            })
        }
        
        
        describe(".disconnect(callback:)") {
            
            it("should disconnect from the websocket", closure: {
                var callbackCallsCount = 0
                var callbackCalled: Bool { return callbackCallsCount > 0 }
                
                socket.disconnect({
                    callbackCallsCount += 1
                })
                expect(fakeConnection.delegate).to(beNil())
                expect(callbackCalled).to(beTrue())
            })
        }
        
        describe(".connect()") {
            it("should connect to the websocket", closure: {
                socket.connect()
                expect(fakeConnection.connectCalled).to(beTrue())
                expect(fakeConnection.delegate).toNot(beNil())
            })
        }
        
        
//        describe(".remove(channel:)") {
//            it("should send a leave message and remove the channel", closure: {
//                expect(socket.channels).to(haveCount(2))
//
//                let ref = String(socket.messageReference)
//                let okLeave = "{\"event\":\"phx_leave\",\"topic\":\"old_msg\",\"ref\":\"\(ref)\",\"payload\":{\"status\":\"ok\"}}"
//
//                // Make request
//                socket.remove(oldMsgChannel)
//                // Send response
//                socket.websocketDidReceiveMessage(socket: fakeConnection, text: okLeave)
//
//
//                expect(socket.channels).to(haveCount(1))
//
//
//            })
//        }
        
//
//        describe(".join(topic: payload:, closure:)") {
//
//            var webSocketClient: WebSocketClient!
//
//            var join: String!
//            var phxReply: String!
//            var joinReply: String!
//            var userEnteredReply: String!
//            var messageReply: String!
//            var pingReply: String!
//
//
//            beforeEach {
//                webSocketClient = WebSocket(url: socket.endpointUrl)
//                join = "{\"event\":\"phx_join\",\"topic\":\"rooms:lobby\",\"ref\":\"1\",\"payload\":{\"body\":\"joining\",\"subject\":\"status\"}}"
//                phxReply = "{\"topic\":\"rooms:socket\",\"ref\":\"1\",\"payload\":{\"status\":\"ok\",\"response\":{}},\"event\":\"phx_reply\"}"
//                joinReply = "{\"topic\":\"rooms:lobby\",\"ref\":null,\"payload\":{\"status\":\"connected\"},\"event\":\"join\"}"
//                userEnteredReply = "{\"topic\":\"rooms:lobby\",\"ref\":null,\"payload\":{\"user\":null},\"event\":\"user:entered\"}"
//                messageReply = "{\"topic\":\"rooms:lobby\",\"ref\":null,\"payload\":{\"user\":\"Test User\",\"body\":\"holla\"},\"event\":\"new:msg\"}"
//                pingReply = "{\"topic\":\"rooms:lobby\",\"ref\":null,\"payload\":{\"user\":\"SYSTEM\",\"body\":\"ping\"},\"event\":\"new:msg\"}"
//            }
//
//            it("should join a channel and begin receiving events", closure: {
//                var joinEventCallsCount = 0
//                var joinEventCalled: Bool { return joinEventCallsCount > 0 }
//                var joinEventPayloads: [Payload] = []
//
//                var newMsgEventCallsCount = 0
//                var newMsgEventCalled: Bool { return newMsgEventCallsCount > 0 }
//                var newMsgEventPayloads: [Payload] = []
//
//                var usrEnteredEventCallsCount = 0
//                var usrEnteredEventCalled: Bool { return usrEnteredEventCallsCount > 0 }
//                var usrEnteredEventPayloads: [Payload] = []
//
//
//                socket.join(topic: "rooms:lobby", { (channel) in
//                    channel.on(event: "join", handler: { (payload) in
//                        joinEventCallsCount += 1
//                        joinEventPayloads.append(payload)
//                    })
//
//                    channel.on(event: "new:msg", handler: { (payload) in
//                        newMsgEventCallsCount += 1
//                        newMsgEventPayloads.append(payload)
//                    })
//
//                    channel.on(event: "user:entered", handler: { (payload) in
//                        usrEnteredEventCallsCount += 1
//                        usrEnteredEventPayloads.append(payload)
//                    })
//                })
//
//
//                var replyEventCallsCount = 0
//                var replyEventCalled: Bool { return joinEventCallsCount > 0 }
//                var replyEventPayloads: [Socket.Payload] = []
//                socket.join(topic: "rooms:socket", { (channel) in
//                    channel.on(event: "phx_reply", handler: { (payload) in
//                        replyEventCallsCount += 1
//                        replyEventPayloads.append(payload)
//                    })
//                })
//
//
//                socket.websocketDidReceiveMessage(socket: webSocketClient, text: phxReply)
//                socket.websocketDidReceiveMessage(socket: webSocketClient, text: userEnteredReply)
//                socket.websocketDidReceiveMessage(socket: webSocketClient, text: joinReply)
//                socket.websocketDidReceiveMessage(socket: webSocketClient, text: pingReply)
//                socket.websocketDidReceiveMessage(socket: webSocketClient, text: messageReply)
//                socket.leave(topic: "rooms:lobby")
//                socket.websocketDidReceiveMessage(socket: webSocketClient, text: pingReply)
//                socket.websocketDidReceiveMessage(socket: webSocketClient, text: phxReply)
//
//
//                expect(joinEventCallsCount).to(equal(1))
//                expect(usrEnteredEventCallsCount).to(equal(1))
//                expect(newMsgEventCallsCount).to(equal(2))
//                expect(replyEventCallsCount).to(equal(2))
//
//                socket.close()
//                expect(socket.channels).toNot(beEmpty())
//
//                socket.close(reset: true)
//                expect(socket.channels).to(beEmpty())
//            })
//        }
//
//        describe(".send()") {
//            it("should inform the outbound of success", closure: {
//                var receivedCallsCount = 0
//                var receivedCalled: Bool { return receivedCallsCount > 0 }
//
//                var alwaysCallsCount = 0
//                var alwaysCalled: Bool { return alwaysCallsCount > 0 }
//
//
//                let outbound = Push(topic: "topic", event: "event", payload: [:], ref: "1")
//                socket
//                    .send(outbound: outbound)
//                    .receive("ok", handler: { (payload) in
//                        receivedCallsCount += 1
//                    }).always({
//                        alwaysCallsCount += 1
//                    })
//                let phxReply = "{\"topic\":\"rooms:socket\",\"ref\":\"1\",\"payload\":{\"status\":\"ok\",\"response\":{}},\"event\":\"phx_reply\"}"
//                let client = WebSocket(url: socket.endpoint)
//                socket.websocketDidReceiveMessage(socket: client, text: phxReply)
//                expect(receivedCalled).to(beTrue())
//                expect(alwaysCalled ).to(beTrue())
//            })
//        }
    }
}

