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
  let socket = Socket(domainAndPort: "localhost:4000", path: "socket", transport: "websocket")
  var topic: String? = "rooms:lobby"
  
  @IBAction func sendMessage(_ sender: UIButton) {
    let message = Message(message: ["user":userField.text!, "body": messageField.text!])
    print(message.toJsonString())
    
    let payload = Payload(topic: topic!, event: "new:msg", message: message)
    socket.send(data: payload)
    messageField.text = ""
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // Join the socket and establish handlers for users entering and submitting messages
    socket.join(topic: topic!, message: Message(subject: "status", body: "joining")) { channel in
      let chan = channel as! Channel
      
      chan.on(event: "join") { message in
        self.chatWindow.text = "You joined the room.\n"
      }
      
      chan.on(event: "new:msg") { message in
        guard let message = message as? Message,
              let username = message["user"],
              let body     = message["body"] else {
                return
        }
        let newMessage = "[\(username)] \(body)\n"
        let updatedText = self.chatWindow.text.appending(newMessage)
        self.chatWindow.text = updatedText
      }
      
      chan.on(event: "user:entered") { message in
        let username = "anonymous"
        self.chatWindow.text = self.chatWindow.text.appending("[\(username) entered]\n")
      }
      
      chan.on(event: "error") { message in
        guard let message = message as? Message,
          let body = message["body"] else {
            return
        }
        let newMessage = "[ERROR] \(body)\n"
        let updatedText = self.chatWindow.text.appending(newMessage)
        self.chatWindow.text = updatedText
      }
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }

}
