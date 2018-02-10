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
  @IBOutlet var userField: UITextField!
  @IBOutlet var messageField: UITextField!
  @IBOutlet var chatWindow: UITextView!
  @IBOutlet var sendButton: UIButton!
    let socket = Socket(url: "ws://localhost:4000/socket/websocket")
  var topic: String? = "rooms:lobby"
  
  @IBAction func sendMessage(_ sender: UIButton) {
    let payload = ["user":userField.text!, "body": messageField.text!]
    let outbound = Outbound(topic: topic!, event: "new:msg", payload: payload)
    

    socket
        .send(outbound: outbound)
        .receive("ok") { (payload) in
            print("success", payload)
        }
        .receive("error") { (errorPayload) in
            print("error: ", errorPayload)
        }
        .always {
            print("always")
        }
    
    messageField.text = ""
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    socket.join(topic: topic!, payload: ["status":"joining"]) { (channel) in
        channel.on(event: "join", handler: { (payload) in
            self.chatWindow.text = "You joined the room.\n"
        })
        
        channel.on(event: "new:msg", handler: { (payload) in
            guard let username = payload["user"], let body = payload["body"] else { return }
            let newMessage = "[\(username)] \(body)\n"
            let updatedText = self.chatWindow.text.appending(newMessage)
            self.chatWindow.text = updatedText
        })
        
        channel.on(event: "user:entered", handler: { (payload) in
            let username = "anonymous"
            self.chatWindow.text = self.chatWindow.text.appending("[\(username) entered]\n")
        })
    }
    
    socket.open()
  }

}
