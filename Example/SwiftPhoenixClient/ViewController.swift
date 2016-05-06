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
  let socket = Phoenix.Socket(domainAndPort: "localhost:4000", path: "socket", transport: "websocket")
  var topic: String? = "rooms:lobby"
  
  @IBAction func sendMessage(sender: AnyObject) {
    let message = Phoenix.Message(message: ["user":userField.text!, "body": messageField.text!])
    print(message.toJsonString())
    
    let payload = Phoenix.Payload(topic: topic!, event: "new:msg", message: message)
    socket.send(payload)
    messageField.text = ""
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // Join the socket and establish handlers for users entering and submitting messages
    socket.join(topic: topic!, message: Phoenix.Message(subject: "status", body: "joining")) { channel in
      let chan = channel as! Phoenix.Channel
      
      chan.on("join") { message in
        self.chatWindow.text = "You joined the room.\n"
      }
      
      chan.on("new:msg") { message in
        guard let message = message as? Phoenix.Message,
              let username = message.message?["user"],
              let body     = message.message?["body"] else {
                return
        }
        let newMessage = "[\(username!)] \(body!)\n"
        let updatedText = self.chatWindow.text.stringByAppendingString(newMessage)
        self.chatWindow.text = updatedText
      }
      
      chan.on("user:entered") { message in
        let username = "anonymous"
        let updatedText = self.chatWindow.text.stringByAppendingString("[\(username) entered]\n")
        self.chatWindow.text = updatedText
      }
      
      chan.on("error") { message in
        guard let message = message as? Phoenix.Message,
          let body = message.message?["body"] else {
            return
        }
        let newMessage = "[ERROR] \(body!)\n"
        let updatedText = self.chat.text.stringByAppendingString(newMessage)
        self.chat.text = updatedText
      }
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }

}

