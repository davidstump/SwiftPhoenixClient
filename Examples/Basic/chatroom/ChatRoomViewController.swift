//
//  ChatRoomViewController.swift
//  Basic
//
//  Created by Daniel Rees on 12/22/20.
//  Copyright © 2021 SwiftPhoenixClient. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftPhoenixClient
import RxSwiftPhoenixClient

struct Shout {
  let name: String
  let message: String
}

class ChatRoomViewController: UIViewController {
  
  // MARK: - Child Views
  @IBOutlet weak var messageInput: UITextField!
  @IBOutlet weak var tableView: UITableView!
  
  // MARK: - Attributes
  private let username: String = "ChatRoom"
//  private let socket = Socket("https://phxchat.herokuapp.com/socket/websocket")
  private let socket = Socket("http://localhost:4000/socket/websocket")
  private let topic: String = "room:lobby"
  
  private var lobbyChannel: Channel?
  private var shouts: [Shout] = []
  
  private let disposeBag = DisposeBag()
  
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.tableView.dataSource = self

    
    // Setup the socket to receive open/close events
    socket.delegateOnOpen(to: self) { (self) in
      print("CHAT ROOM: Socket Opened")
    }
    
    socket.delegateOnClose(to: self) { (self) in
      print("CHAT ROOM: Socket Closed")
      
    }
    
    socket.delegateOnError(to: self) { (self, error) in
      print("CHAT ROOM: Socket Errored. \(error)")
    }
    
    socket.logger = { msg in print("LOG:", msg) }
    
    // Setup the Channel to receive and send messages
    let channel = socket.channel(topic, params: ["status": "joining"])
    channel.rx
      .on("shout")
      .observeOn(MainScheduler.asyncInstance)
      .subscribe( onNext: { (message) in
        let payload = message.payload
        guard
            let name = payload["name"] as? String,
            let message = payload["message"] as? String else { return }
        
        let shout = Shout(name: name, message: message)
        self.shouts.append(shout)
        
        let indexPath = IndexPath(row: self.shouts.count - 1, section: 0)
        self.tableView.reloadData() //reloadRows(at: [indexPath], with: .automatic)
        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
      }).disposed(by: disposeBag)
    
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
    
  
  // MARK: - IB Actions
  @IBAction func onExitButtonPressed(_ sender: Any) {
    self.socket.disconnect()
    self.navigationController?.popViewController(animated: true)
  }
  
  
  @IBAction func onSendButtonPressed(_ sender: Any) {
    // Create and send the payload
    let payload = ["name": username, "message": messageInput.text!]
    self.lobbyChannel?.push("shout", payload: payload)
    
    // Clear the text intput
    self.messageInput.text = ""
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
