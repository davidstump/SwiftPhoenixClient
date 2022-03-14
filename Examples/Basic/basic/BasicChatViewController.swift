//
//  BasicChatViewController.swift
//  Basic
//
//  Created by Daniel Rees on 10/23/20.
//  Copyright © 2021 SwiftPhoenixClient. All rights reserved.
//

import UIKit
import SwiftPhoenixClient

/*
 Testing with Basic Chat
 
 This class is designed to provide as a sandbox to test various client features in a "real"
 environment where network can be dropped, disconnected, servers can quit, etc.
 
 For a more advanced example, see the ChatRoomViewController
 
 This example is intended to connect to a local chat server.
 
 Setup
 1. Select which Transpart is being tested.
 
 Steps
 1. Connect the Socket
 2. Verify System pings come through
 3. Send a message and verify it is returned by the server
 4. From a web client, send a message and verify it is received by the app.
 5. Disconnect and Connect the Socket again
 6. Kill the server, verifying that the retry starts
 7. Start the server again, verifying that the client reconnects
 8. After the client reconnects, verify pings and messages work as before
 9. Disconnect the client and kill the server again
 10. While the server is disconnected, connect the client
 11. Start the server and verify that the client connects once the server is available
 
 */

let endpoint = "http://localhost:4000/socket/websocket"

class BasicChatViewController: UIViewController {
  
  // MARK: - Child Views
  
  @IBOutlet weak var connectButton: UIButton!
  
  @IBOutlet weak var pauseButton: UIButton!
  @IBOutlet weak var messageField: UITextField!
  @IBOutlet weak var chatWindow: UITextView!
  
  
  // Notifcation Subscriptions
  private var didbecomeActiveObservervation: NSObjectProtocol?
  private var willResignActiveObservervation: NSObjectProtocol?
  
  // MARK: - Variables
  let username: String = "Basic"
  var topic: String = "rooms:lobby"
  
  
  
  // Test the URLSessionTransport
  let socket = Socket(endpoint)
  
  // Test the StarscreamTransport
//  let socket = Socket(endPoint: endpoint, transport: { url in return StarscreamTransport(url: url) })
    
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
      
      self.removeAppActiveObservation()
    } else {
      connectAndJoin()
      
      // When app enters foreground, be sure that the socket is connected
      self.observeDidBecomeActive()
    }
  }
  
  private var isPaused: Bool = false
  @IBAction func onPausePressed(_ sender: Any) {
  
    if isPaused {
      self.socket.connect()
      self.pauseButton.setTitle("Pause", for: .normal)
    } else {
      self.socket.disconnect(code: .goingAway)
      self.pauseButton.setTitle("Resume", for: .normal)
    }
    
    self.isPaused = !isPaused
    
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
  private func observeDidBecomeActive() {
    //Make sure there's no other observations
    self.removeAppActiveObservation()
    
    self.didbecomeActiveObservervation = NotificationCenter.default
      .addObserver(forName: UIApplication.didBecomeActiveNotification,
                   object: nil,
                   queue: .main) { [weak self] _ in self?.socket.pauseConnection() }
    
    // When the app resigns being active, the leave any existing channels
    // and disconnect from the websocket.
    self.willResignActiveObservervation = NotificationCenter.default
      .addObserver(forName: UIApplication.willResignActiveNotification,
                   object: nil,
                   queue: .main) { [weak self] _ in self?.socket.resumeConnection() }
  }
  
  private func removeAppActiveObservation() {
    if let observer = self.didbecomeActiveObservervation {
      NotificationCenter.default.removeObserver(observer)
      self.didbecomeActiveObservervation = nil
    }
    
    if let observer = self.willResignActiveObservervation {
      NotificationCenter.default.removeObserver(observer)
      self.willResignActiveObservervation = nil
    }
  }
  
  
  
  
  
  
  
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
