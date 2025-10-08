//
//  EchoViewModel.swift
//  Examples
//
//  Created by Daniel Rees on 8/25/25.
//  Copyright © 2025 SwiftPhoenixClient. All rights reserved.
//

import Foundation
import SwiftPhoenixClient

@MainActor
final class EchoViewModel: ObservableObject {
    @Published var isConnected = false
    @Published var draft = ""
    @Published var messages: [EchoMessage] = [
        EchoMessage(text: "Welcome! Tap Connect to start.", isMe: false)
    ]
    
    private let url = URL(string: "https://echo.websocket.org/")!
    private var websocket: WebSocket? = nil
    
    func toggleConnection() async {
        if websocket == nil || websocket?.isClosed == true {
            await connect()
        } else {
            disconnect()
        }
    }
    
    func connect() async {
        do {
            self.append("Connecting...")
            let websocket = try await URLSessionWebSocket.connect(to: url)
            self.websocket = websocket
            
            for await event in websocket.events {
                switch event {
                case .open(_):
                    self.append("Connected ✅")
                    self.isConnected = true
                case .close(let code, let reason):
                    self.append("Code: \(code) Reason: \(reason ?? "None")")
                    self.append("Disconnected ⛔️")
                    self.isConnected = false
                case .text(let text):
                    self.append("Text Received: \(text)")
                case .binary(let binary):
                    let string = String(data: binary, encoding: .utf8)!
                    self.append("Binary Received: \(string)")
                }
            }
        } catch {
            print("error \(error)")
            self.append("\(error.localizedDescription) ⛔️")
        }
    }
    
    func disconnect() {
        self.append("disconnecting...")
        websocket?.disconnect(code: .normalClosure, reason: nil)
    }
    
    func send() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        self.append(trimmed, isMe: true)
        self.websocket?.send(string: trimmed)
        self.draft = ""
    }
    
    private func append(_ text: String, isMe: Bool = false) {
        self.messages.append(EchoMessage(text: text, isMe: isMe))
    }
}
