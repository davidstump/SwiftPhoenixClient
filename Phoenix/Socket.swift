//
//  Socket.swift
//  Phoenix
//
//  Created by David Stump on 8/23/14.
//  Copyright (c) 2014 David Stump. All rights reserved.
//

import Foundation

@objc class Socket: NSObject, SRWebSocketDelegate {
  var conn: SRWebSocket?
  var endPoint: String?
  var channels = Array<Phoenix.Channel>()
  var sendBuffer = Array<(Void)>()
  var sendBufferTimer: NSTimer?
  let flushEveryMs = 50
  var reconnectTimer: NSTimer?
  let reconnectAfterMs = 5000
  
  
  init(endPoint: String) {
    super.init()
    self.endPoint = endPoint
    resetBufferTimer()
    reconnect()
  }
  
  func close(callback: () -> ()) {
    if let connection = self.conn {
      connection.delegate = nil
      connection.close()
    }
    callback()
  }
  
  func reconnect() {
    close() {
      self.conn = SRWebSocket(URL: NSURL(string: self.endPoint))
      if let connection = self.conn {
        connection.delegate = self
        connection.open()
      }
    }
  }
  
  func resetBufferTimer() {
    sendBufferTimer?.invalidate()
    sendBufferTimer = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(flushEveryMs), target: self, selector: Selector("flushSendBuffer"), userInfo: nil, repeats: true)
  }
  
  func onOpen() {
    reconnectTimer?.invalidate()
    rejoinAll()
  }
  
  func onClose(event: String) {
    reconnectTimer?.invalidate()
    reconnectTimer = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(reconnectAfterMs), target: self, selector: Selector("reconnect"), userInfo: nil, repeats: true)
  }
  
  func onError(error: NSError) {
    println("Error: \(error)")
  }
  
  func connectionState() -> NSString {
    if let connection = self.conn {
      switch connection.readyState.value {
      case 0:
        return "connecting"
      case 1:
        return "open"
      case 2:
        return "closing"
      case 3:
        return "closed"
      default:
        return ""
      }
    } else {
      return "closed"
    }
  }
  
  func isConnected() -> Bool {
    return connectionState() == "open"
  }
  
  func rejoinAll() {
    for chan in channels {
      rejoin(chan as Phoenix.Channel)
    }
  }
  
  func rejoin(chan: Phoenix.Channel) {
    chan.reset()
    let (channel, topic, message) = (chan.channel, chan.topic, chan.message)
    let joinMessage = Phoenix.Message(subject: "status", body: "joining")
    let payload = Phoenix.Payload(channel: channel!, topic: topic!, event: "join", message: joinMessage)
    send(payload)
    chan.callback(chan)
  }
  
  func join(channel: String, topic: String, message: Phoenix.Message, callback: (AnyObject -> Void)) {
    let chan = Phoenix.Channel(channel: channel, topic: topic, message: message, callback: callback, socket: self)
    channels.append(chan)
    if isConnected() {
      println("joining")
      rejoin(chan)
    }
  }
  
  func leave(channel: String, topic: String, message: Phoenix.Message) {
    let leavingMessage = Phoenix.Message(subject: "status", body: "leaving")
    let payload = Phoenix.Payload(channel: channel, topic: topic, event: "leave", message: leavingMessage)
    send(payload)
    var newChannels = Array<Phoenix.Channel>()
    for chan in channels {
      let c = chan as Phoenix.Channel
      if !c.isMember(channel, topic: topic) {
        newChannels.append(c)
      }
    }
    channels = newChannels
  }
  
  func send(data: Phoenix.Payload) {
    let callback = {
      (data: Phoenix.Payload) -> Void in
      if let connection = self.conn {
        let (channel, topic, event, message) = (data.channel, data.topic, data.event, data.message)
        let payload = Phoenix.Payload(channel: channel, topic: topic, event: event, message: message)
        connection.send(Phoenix.JSONStringify(payload))
      }
    }
    if isConnected() {
      callback(data)
    } else {
      sendBuffer.append(callback(data))
    }
  }
  
  func flushSendBuffer() {
    if isConnected() && sendBuffer.count > 0 {
      for callback in sendBuffer {
        callback
      }
      sendBuffer = Array<(Void)>()
      resetBufferTimer()
    }
  }
  
  func onMessage(payload: Phoenix.Payload) {
    let (channel, topic, event, message) = (payload.channel, payload.topic, payload.event, payload.message)
    for chan in channels {
      if chan.isMember(channel, topic: topic) {
        chan.trigger(event, msg: message!)
      }
    }
  }
  
  // SRWebSocket Delegate Methods
  
  func webSocket(webSocket: SRWebSocket!, didReceiveMessage message: AnyObject!) {
    println("socket message: \(message)")
    let parsedMessage = Phoenix.JSONParseDict(message as String)
    onMessage(parsedMessage)
  }
  
  func webSocket(webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String?, wasClean: Bool) {
    println("socket closed")
    onClose("reason: \(reason)")
  }
  
  func webSocketDidOpen(webSocket: SRWebSocket!) {
    println("socket opened")
    onOpen()
  }
  
  func webSocket(webSocket: SRWebSocket!, didFailWithError error: NSError!) {
    onError(error)
  }
  
}