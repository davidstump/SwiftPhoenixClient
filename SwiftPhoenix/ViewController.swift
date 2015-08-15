//
//  ViewController.swift
//  SwiftPhoenix
//
//  Created by David Stump on 11/30/14.
//  Copyright (c) 2014 David Stump. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController {
  @IBOutlet var userField: UITextField!
  @IBOutlet var messageField: UITextField!
  @IBOutlet var chatWindow: UITextView!
  @IBOutlet var sendButton: UIButton!
  let socket = Phoenix.Socket(endPoint: "ws://localhost:4000/ws")
  var topic: String? = "lobby"
  
  @IBAction func sendMessage(sender: AnyObject) {
    let message = Phoenix.Message(message: ["user":userField.text, "body": messageField.text])
    println(message.toJsonString())
    let payload = Phoenix.Payload(channel: "rooms", topic: topic!, event: "new:msg", message: message)
    socket.send(payload)
    messageField.text = ""
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Join the socket and establish handlers for users entering and submitting messages
    socket.join("rooms", topic: topic!, message: Phoenix.Message(subject: "status", body: "joining")) { channel in
      let chan = channel as! Phoenix.Channel
      
      chan.on("join") { message in
        self.chatWindow.text = "You joined the room.\n"
      }
      
      chan.on("new:msg") { message in
        let msg = message as! Phoenix.Message
        var (username: AnyObject?, body: AnyObject?) = (msg.message?["user"]!, msg.message?["body"]!)
        let newMessage = "[\(username!)] \(body!)\n"
        let updatedText = self.chatWindow.text.stringByAppendingString(newMessage)
        self.chatWindow.text = updatedText
      }
      
      chan.on("user:entered") { message in
        var username = "anonymous"
        let updatedText = self.chatWindow.text.stringByAppendingString("[\(username) entered]\n")
        self.chatWindow.text = updatedText
      }
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  
}

