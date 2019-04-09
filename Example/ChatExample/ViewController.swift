//
//  ViewController.swift
//  SwiftPhoenixClient
//
//  Created by Kyle Oba on 08/25/2015.
//  Copyright (c) 2015 Kyle Oba. All rights reserved.
//

import UIKit
import SwiftPhoenixClient

class ViewController: UIViewController {
    
    //----------------------------------------------------------------------
    // MARK: - Child Views
    //----------------------------------------------------------------------
    @IBOutlet var userField: UITextField!
    @IBOutlet var messageField: UITextField!
    @IBOutlet var chatWindow: UITextView!
    @IBOutlet var sendButton: UIButton!
  
    @IBOutlet weak var socketButton: UIButton!
    
    let socket = Socket("ws://localhost:4000/socket/websocket")
    var topic: String = "rooms:lobby"
    var lobbyChannel: Channel!
    
  
    override func viewDidLoad() {
        super.viewDidLoad()

        
        // To automatically manage retain cycles, use `delegate*(to:)` methods.
        // If you would prefer to handle them yourself, youcan use the same
        // methods without the `delegate` functions, just be sure you avoid
        // memory leakse with `[weak self]`
        socket.delegateOnOpen(to: self) { (self) in
            self.addText("Socket Opened")
            self.socketButton.setTitle("Disconnect", for: .normal)
        }
        
        socket.delegateOnClose(to: self) { (self) in
            self.addText("Socket Closed")
            self.socketButton.setTitle("Connect", for: .normal)
        }

        socket.delegateOnError(to: self) { (self, error) in
            self.addText("Socket Errored: " + error.localizedDescription)
        }
        
        socket.logger = { msg in print("LOG:", msg) }
    }
    
    
    //----------------------------------------------------------------------
    // MARK: - IBActions
    //----------------------------------------------------------------------
    @IBAction func onSocketButtonPressed(_ sender: Any) {
        if socket.isConnected {
            disconnectAndLeave()
        } else {
            connectAndJoin()
        }
    }
    
    @IBAction func sendMessage(_ sender: UIButton) {
        let payload = ["user":userField.text!, "body": messageField.text!]
        
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
    
    //----------------------------------------------------------------------
    // MARK: - Private
    //----------------------------------------------------------------------
    private func disconnectAndLeave() {
        // Be sure the leave the channel or call socket.remove(lobbyChannel)
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
        let updatedText = self.chatWindow.text.appending(text).appending("\n")
        self.chatWindow.text = updatedText
    }

}
