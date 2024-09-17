//
//  ChatRoomViewController.swift
//  Basic
//
//  Created by Daniel Rees on 12/22/20.
//  Copyright © 2021 SwiftPhoenixClient. All rights reserved.
//

import UIKit
import SwiftPhoenixClient

struct Shout {
  let name: String
  let message: String
}

/*
 ChatRoom provides a "real" example of using SwiftPhoenixClient, including how
 to use the Rx extensions for it. It also utilizes logic to disconnect/reconnect
 the socket when the app enters and exits the foreground.
 
 NOTE: iOS can, at will, kill your connection if the app enters the background without
 notiftying your process that it has been killed. Thus resulting in a disconnected
 socket when the app comes back to the foreground. The best way around this is to
 listen to UIApplication.didBecomeActiveNotification events and manually check if the socket is still connected
 and attempt to reconnect and rejoin any channels.
 
 In this example, the channel is left and socket is disconnected when the app enters
 the background and then a new channel is created and joined and the socket is connected
 when the app enters the foreground.
 
 This example utilizes the PhxChat example at https://github.com/dwyl/phoenix-chat-example
 */
class ChatRoomViewController: UIViewController {
  
  // MARK: - Child Views
  @IBOutlet weak var messageInput: UITextField!
  @IBOutlet weak var tableView: UITableView!
  
  // MARK: - Attributes
  private let username: String = "ChatRoom"
//  private let socket = Socket("http://localhost:4000/socket/websocket")
  	private let socket = Socket("https://phoenix-chat.fly.dev/socket/websocket")
  private let topic: String = "room:lobby"
  
  private var lobbyChannel: Channel?
  private var shouts: [Shout] = []
  
  // Notifcation Subscriptions
  private var didbecomeActiveObservervation: NSObjectProtocol?
  private var willResignActiveObservervation: NSObjectProtocol?
  
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.tableView.dataSource = self
    
    // When app enters foreground, be sure that the socket is connected
    self.observeDidBecomeActive()
    
    // Connect to the chat for the first time
    self.connectToChat()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    // When the Controller is removed from the view hierarchy, then stop
    // observing app lifecycle and disconnect from the chat
    self.removeAppActiveObservation()
    self.disconnectFromChat()
  }
  
  // MARK: - IB Actions
  @IBAction func onExitButtonPressed(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }
  
  
  @IBAction func onSendButtonPressed(_ sender: Any) {
    // Create and send the payload
    let payload = ["name": username, "message": messageInput.text!]
    self.lobbyChannel?.push("shout", payload: payload)
    
    // Clear the text intput
    self.messageInput.text = ""
  }
  
  
  //----------------------------------------------------------------------
  // MARK: - Background/Foreground reconnect strategy
  //----------------------------------------------------------------------
  private func observeDidBecomeActive() {
    //Make sure there's no other observations
    self.removeAppActiveObservation()
    
    self.didbecomeActiveObservervation = NotificationCenter.default
      .addObserver(forName: UIApplication.didBecomeActiveNotification,
                   object: nil,
                   queue: .main) { [weak self] _ in self?.connectToChat() }
    
    // When the app resigns being active, the leave any existing channels
    // and disconnect from the websocket.
    self.willResignActiveObservervation = NotificationCenter.default
      .addObserver(forName: UIApplication.willResignActiveNotification,
                   object: nil,
                   queue: .main) { [weak self] _ in self?.disconnectFromChat() }
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
  
  private func connectToChat() {
    // Setup the socket to receive open/close events
    socket.delegateOnOpen(to: self) { (self) in
      print("CHAT ROOM: Socket Opened")
    }
    
    socket.delegateOnClose(to: self) { (self) in
      print("CHAT ROOM: Socket Closed")
      
    }
    
    socket.delegateOnError(to: self) { (self, error) in
      let (error, response) = error
      if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode > 400 {
        print("CHAT ROOM: Socket Errored. \(statusCode)")
        self.socket.disconnect()
      } else {
        print("CHAT ROOM: Socket Errored. \(error)")
      }
    }
    
    socket.logger = { msg in print("LOG:", msg) }
    
    // Setup the Channel to receive and send messages
    let channel = socket.channel(topic, params: ["status": "joining"])
    channel.delegateOn("shout", to: self) { (self, message) in
      let payload = message.payload
      guard
        let name = payload["name"] as? String,
        let message = payload["message"] as? String else { return }
      
      let shout = Shout(name: name, message: message)
      self.shouts.append(shout)
      
      
      DispatchQueue.main.async {
        let indexPath = IndexPath(row: self.shouts.count - 1, section: 0)
        self.tableView.reloadData() //reloadRows(at: [indexPath], with: .automatic)
        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
      }
    }
    
    // Now connect the socket and join the channel
    self.lobbyChannel = channel
    self.lobbyChannel?
      .join()
      .delegateReceive("ok", to: self, callback: { (self, _) in
        print("CHANNEL: rooms:lobby joined")
      })
      .delegateReceive("error", to: self, callback: { (self, message) in
        print("CHANNEL: rooms:lobby failed to join. \(message.payload)")
      })
    
    self.socket.connect()
  }
  
  private func disconnectFromChat() {
    if let channel = self.lobbyChannel {
      channel.leave()
      self.socket.remove(channel)
    }
    
    self.socket.disconnect()
    self.shouts = []
  }
}


extension ChatRoomViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.shouts.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "shout_cell")
    
    let shout = self.shouts[indexPath.row]
    
    cell.textLabel?.text = shout.message
    cell.detailTextLabel?.text = shout.name
    
    return cell
  }
}
