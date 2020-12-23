//
//  BasicChatViewController.swift
//  Basic
//
//  Created by Daniel Rees on 10/23/20.
//  Copyright © 2020 SwiftPhoenixClient. All rights reserved.
//

import UIKit
import SwiftPhoenixClient

class BasicChatViewController: UIViewController {
    
    // MARK: - Child Views
    
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var messageField: UITextField!
    @IBOutlet weak var chatWindow: UITextView!
    
    
    // MARK: - Variables
    let username: String =  "Basic"
    let socket = Socket("ws://localhost:4000/socket/websocket")
    var topic: String = "rooms:lobby"
    var lobbyChannel: Channel!
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.chatWindow.text = ""
        
        // To automatically manage retain cycles, use `delegate*(to:)` methods.
        // If you would prefer to handle them yourself, youcan use the same
        // methods without the `delegate` functions, just be sure you avoid
        // memory leakse with `[weak self]`
        socket.delegateOnOpen(to: self) { (self) in
            self.addText("Socket Opened")
            DispatchQueue.main.async {
                self.connectButton.setTitle("Disconnect", for: .normal)
            }
        }
        
        socket.delegateOnClose(to: self) { (self) in
            self.addText("Socket Closed")
            DispatchQueue.main.async {
                self.connectButton.setTitle("Connect", for: .normal)
            }
        }
        
        socket.delegateOnError(to: self) { (self, error) in
            self.addText("Socket Errored: " + error.localizedDescription)
        }
        
        socket.logger = { msg in print("LOG:", msg) }
    }
    
    
    // MARK: - IBActions
    @IBAction func onConnectButtonPressed(_ sender: Any) {
        if socket.isConnected {
            disconnectAndLeave()
        } else {
            connectAndJoin()
        }
    }
    
    @IBAction func sendMessage(_ sender: UIButton) {
        let payload = ["user": username, "body": messageField.text!]
        
        self.lobbyChannel
            .push("new:msg", payload: payload)
            .receive("ok") { (message) in
                print("success", message)
            }
            .receive("error") { (errorMessage) in
                print("error: ", errorMessage)
            }
        
        messageField.text = ""
    }
    
    
    
    // MARK: - Private
    private func disconnectAndLeave() {
        //     Be sure the leave the channel or call socket.remove(lobbyChannel)
        lobbyChannel.leave()
        socket.disconnect {
            self.addText("Socket Disconnected")
        }
    }
    
    private func connectAndJoin() {
        let channel = socket.channel(topic, params: ["status":"joining"])
        channel.delegateOn("join", to: self) { (self, _) in
            self.addText("You joined the room.")
        }
        
        channel.delegateOn("new:msg", to: self) { (self, message) in
            let payload = message.payload
            guard
                let username = payload["user"],
                let body = payload["body"] else { return }
            let newMessage = "[\(username)] \(body)"
            self.addText(newMessage)
        }
        
        channel.delegateOn("user:entered", to: self) { (self, message) in
            self.addText("[anonymous entered]")
        }
        
        self.lobbyChannel = channel
        self.lobbyChannel
            .join()
            .delegateReceive("ok", to: self) { (self, _) in
                self.addText("Joined Channel")
            }.delegateReceive("error", to: self) { (self, message) in
                self.addText("Failed to join channel: \(message.payload)")
            }
        self.socket.connect()
        
    }
    
    private func addText(_ text: String) {
        DispatchQueue.main.async {
            let updatedText = self.chatWindow.text.appending(text).appending("\n")
            self.chatWindow.text = updatedText
            
            let bottom = NSMakeRange(updatedText.count - 1, 1)
            self.chatWindow.scrollRangeToVisible(bottom)
        }
    }
    
}
