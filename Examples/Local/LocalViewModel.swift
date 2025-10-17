//
//  LocalViewModel.swift
//  Examples
//
//  Created by Daniel Rees on 10/9/25.
//  Copyright © 2025 SwiftPhoenixClient. All rights reserved.
//

import Foundation
import SwiftPhoenixClient

struct Shout: Codable {
    let name: String
    let message: String
}

@MainActor
final class LocalViewModel: ObservableObject {
    
    @Published var isConnected = false
    @Published var draft = ""
    @Published var messages: [EchoMessage] = [
        EchoMessage(text: "Welcome! Tap Connect to start.", isMe: false)
    ]
    
    private let url = URL(string: "ws://localhost:4000/socket")!
    private let socket: Socket
    private var lobby: Channel? = nil
    
    init() {
        self.socket = Socket("http://localhost:4000/socket", options: .init(
            transport: WebSocketTransport(
                onOpen: { response in
                    if let response = response as? HTTPURLResponse {
                        print("Transport Connected: \(response.statusCode)")
                    }
                },
                onError: {  error, response in
                    if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode > 400 {
                        print("Transport Errored: \(statusCode)")
                        
                    } else {
                        print("Transport Errored: \(error.localizedDescription)")
                    }
                }
            )
        ))
    }
    
    func toggleConnection() async {
        if !socket.isConnected {
            await connect()
        } else {
            disconnect()
        }
    }
    
    func connect() async {
        self.socket.onOpen {
            self.append("✅ Socket Opened")
        }
        
        self.socket.onClose {
            self.append("⛔️ Socket Closed")
        }
        
        self.socket.logger = { msg in print("LOG:", msg) }
        
        let channel = socket.channel("room:lobby", params: ["status": "joining"])
//        channel.onDecodable("shout", of: Shout.self) { message, error in
//            guard let message else {
//                if let error {
//                    self.append("⛔️ Error receiving shout. See logs")
//                    print("Error receiving message", error)
//                }
//                return
//            }
//            
//            let shout = message.payload
//            self.append("\(shout.name): \(shout.message)")
//            
//        }
        
        self.lobby = channel
        self.joinLobby()
//        try! self.lobby?
//            .join()
//            .awa
//            .receive("ok") { message in
//                self.append("✅ Joined lobby")
//                print("CHANNEL: rooms:lobby joined. status <\(message.status ?? "null")>")
//            }
//            .receive("error") { message in
//                self.append("⛔️ Could not join lobby")
//                print("CHANNEL: rooms:lobby failed to join. payload <\(message.payload)>  status <\(message.status ?? "null")> ")
//            }
            
        await self.socket.connect()
    }
    
    private func joinLobby() {
        guard let lobby else { return }
        
        Task {
            do {
                let reply = try await lobby
                    .join()
                    .awaitReply()
                
                if reply.status == "ok" {
                    self.append("✅ Joined lobby")
                    print("CHANNEL: rooms:lobby joined. status <\(reply.status ?? "null")>")
                }
                
                if reply.status == "error" {
                    self.append("⛔️ Could not join lobby")
                    print("CHANNEL: rooms:lobby failed to join. payload <\(reply.payload)>  status <\(reply.status ?? "null")> ")
                }
                
            } catch {
                self.append("⛔️ Could not join lobby")
                print("CHANNEL: rooms:lobby failed to join. payload <\(error)>")
            }
            
        }
    }
    
    func disconnect() {
        if let channel = self.lobby {
            channel.leave()
            socket.remove(channel)
        }
        
        self.socket.disconnect()
    }
    
    func send() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Create and send the payload
        let payload = ["name": "mobile", "message": trimmed]
        try! self.lobby?.push("shout", payload: payload)

        Task {
            do {
                let message = try await self.lobby?
                    .push("shout", payload: payload)
                    .awaitReply()
                
                
            } catch {
                // TODO: Local Timeout
            }
        }
        
        
        // Clear the text intput
        self.draft = ""
    }
    
    private func append(_ text: String, isMe: Bool = false) {
        self.messages.append(EchoMessage(text: text, isMe: isMe))
    }
}
