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
    private var messageTask: Task<Void, Never>? = nil
    
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
        Task {
            for await _ in socket.onOpenEvents() {
                self.isConnected = true
                self.append("✅ Socket Opened")
            }
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
        self.listenForChannelMessages()

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
                
                if reply.status == "timeout" {
                    self.append("⏳ Timed out while joining")
                }
                
            } catch {
                self.append("⛔️ Could not join lobby")
                print("CHANNEL: rooms:lobby failed to join. payload <\(error)>")
            }
        }
    }
    
    private func listenForChannelMessages() {
        guard let lobby else { return }
        self.messageTask = Task {
            for await message in lobby.awaitOnDecodable("shout", of: Shout.self) {
                let shout = message.payload
                self.append("\(shout.name): \(shout.message)")
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
        guard let lobby else { return }
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Create and send the payload        
        let shout = Shout(name: "mobile-codable", message: trimmed)
        do {
            try lobby.push("shout", payload: shout)
    
        } catch {
            print("Error pushing shout: \(error)")
        }
        
        // Clear the text intput
        self.draft = ""
    }
    
    private func append(_ text: String, isMe: Bool = false) {
        self.messages.append(EchoMessage(text: text, isMe: isMe))
    }
}
