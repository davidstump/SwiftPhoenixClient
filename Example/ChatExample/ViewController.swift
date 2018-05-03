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
  
    
    let socket = Socket(url: "ws://localhost:4000/socket/websocket")
    var topic: String = "rooms:lobby"
    var lobbyChannel: Channel!
    
    
  
  @IBAction func sendMessage(_ sender: UIButton) {
    let payload = ["user":userField.text!, "body": messageField.text!]
    
    self.lobbyChannel
        .push("new:msg", payload: payload)
        .receive("ok") { (payload) in
            print("success", payload)
        }
        .receive("error") { (errorPayload) in
            print("error: ", errorPayload)
        }
    
    messageField.text = ""
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    socket.onOpen {
        print("Socket has opened")
    }
    
    socket.onClose {
        print("Socket has closed")
    }
    
    socket.onError { error in
        print("Socket has errored: ", error.localizedDescription)
    }
    
    socket.logger = { msg in
        print(msg)
    }

    socket.connect()
    
    let channel = socket.channel(topic, params: ["status":"joining"])
    channel.on("join") { (payload) in
        self.chatWindow.text = "You joined the room.\n"
    }
    
    channel.on("new:msg") { (payload) in
        guard let username = payload["user"], let body = payload["body"] else { return }
        let newMessage = "[\(username)] \(body)\n"
        let updatedText = self.chatWindow.text.appending(newMessage)
        self.chatWindow.text = updatedText
    }

    channel.on("user:entered") { (payload) in
        let username = "anonymous"
        self.chatWindow.text = self.chatWindow.text.appending("[\(username) entered]\n")
    }
    
    channel
        .join()
        .receive("ok") { (payload) in
            print("Joined Channel")
        }.receive("error") { (payload) in
            print("Failed to join channel: ", payload)
        }
    
    
    self.lobbyChannel = channel
    
  }

}
