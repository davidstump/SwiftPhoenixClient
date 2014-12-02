//
//  Phoenix.swift
//  SwiftPhoenix
//
//  Created by David Stump on 12/1/14.
//  Copyright (c) 2014 David Stump. All rights reserved.
//

import Foundation

struct Phoenix {
  
  // MARK: Phoenix Message
  class Message: Serializable {
    var subject: String?
    var body: AnyObject?
    var message: AnyObject?
    
    init(subject: String, body: AnyObject) {
      (self.subject, self.body) = (subject, body)
      super.init()
      create()
    }
    
    init(message: AnyObject) {
      self.message = message
      super.init()
      create(single: false)
    }
    
    func create(single: Bool = true) -> [String: AnyObject] {
      if single {
        return [self.subject!: self.body!]
      } else {
        return self.message! as [String: AnyObject]
      }
    }
  }
  
  // MARK: Phoenix Binding
  class Binding {
    var event: String
    var callback: AnyObject -> Void?
    
    init(event: String, callback: AnyObject -> Void?) {
      (self.event, self.callback) = (event, callback)
      create()
    }
    
    func create() -> (String, AnyObject -> Void?) {
      return (event, callback)
    }
  }
  
  // MARK: Phoenix Channel
  class Channel {
    var bindings: [Phoenix.Binding] = []
    var channel: String?
    var topic: String?
    var message: Phoenix.Message?
    var callback: (AnyObject -> Void?)
    var socket: Phoenix.Socket?
    
    init(channel: String, topic: String, message: Phoenix.Message, callback: (AnyObject -> Void), socket: Phoenix.Socket) {
      (self.channel, self.topic, self.message, self.callback, self.socket) = (channel, topic, message, callback, socket)
      reset()
    }
    
    func reset() {
      bindings = []
    }
    
    func on(event: String, callback: (AnyObject -> Void)) {
      bindings.append(Phoenix.Binding(event: event, callback: callback))
    }
    
    func isMember(channel: String, topic: String) -> Bool {
      return self.channel == channel && self.topic == topic
    }
    
    func off(event: String) {
      var newBindings: [Phoenix.Binding] = []
      for binding in bindings {
        if binding.event != event {
          newBindings.append(Phoenix.Binding(event: binding.event, callback: binding.callback))
        }
      }
      bindings = newBindings
    }
    
    func trigger(triggerEvent: String, msg: Phoenix.Message) {
      for binding in bindings {
        if binding.event == triggerEvent {
          binding.callback(msg)
        }
      }
    }
    
    func send(event: String, message: Phoenix.Message) {
      println("conn sending")
      let payload = Phoenix.Payload(channel: channel!, topic: topic!, event: event, message: message)
      socket?.send(payload)
    }
    
    func leave(message: Phoenix.Message) {
      if let sock = socket {
        sock.leave(channel!, topic: topic!, message: message)
      }
      reset()
    }
  }
  
  // MARK: Phoenix Payload
  class Payload {
    var channel: String
    var topic: String
    var event: String
    var message: Phoenix.Message
    
    init(channel: String, topic: String, event: String, message: Phoenix.Message) {
      (self.channel, self.topic, self.event, self.message) = (channel, topic, event, message)
      create()
    }
    
    func create() -> [String: AnyObject?] {
      return ["channel": channel, "topic": topic, "event": event, "message": message]
    }
    
  }
  
  // MARK: Phoenix Socket
  class Socket: NSObject, WebSocketDelegate {
    var conn: WebSocket?
    var endPoint: String?
    var channels: [Phoenix.Channel] = []
    var sendBuffer: [Void] = []
    var sendBufferTimer: NSTimer?
    let flushEveryMs = 50
    var reconnectTimer: NSTimer?
    let reconnectAfterMs = 5000
    
    
    init(endPoint: String) {
      self.endPoint = endPoint
      super.init()
      resetBufferTimer()
      reconnect()
    }
    
    func close(callback: () -> ()) {
      if let connection = self.conn {
        connection.delegate = nil
        connection.disconnect()
      }
      callback()
    }
    
    func reconnect() {
      close() {
        self.conn = WebSocket(url: NSURL(string: self.endPoint!)!)
        if let connection = self.conn {
          connection.delegate = self
          connection.connect()
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
    
    func isConnected() -> Bool {
      if let connection = self.conn {
        return connection.isConnected
      } else {
        return false
      }
      
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
      var newChannels: [Phoenix.Channel] = []
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
        (payload: Phoenix.Payload) -> Void in
        if let connection = self.conn {
          let json = self.payloadToJson(payload)
          println("json: \(json)")
          connection.writeString(json)
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
        sendBuffer = []
        resetBufferTimer()
      }
    }
    
    func onMessage(payload: Phoenix.Payload) {
      let (channel, topic, event, message) = (payload.channel, payload.topic, payload.event, payload.message)
      for chan in channels {
        if chan.isMember(channel, topic: topic) {
          chan.trigger(event, msg: message)
        }
      }
    }
    
    // WebSocket Delegate Methods
    func websocketDidReceiveMessage(message: String) {
      println("socket message: \(message)")
      let json = JSON.parse(message as NSString)
      let (channel, topic, event) = (
        unwrappedJsonString(json["channel"].asString),
        unwrappedJsonString(json["topic"].asString),
        unwrappedJsonString(json["event"].asString)
      )
      let msg: [String: AnyObject] = json["message"].asDictionary!
      
      let messagePayload = Phoenix.Payload(channel: channel, topic: topic, event: event, message: Phoenix.Message(message: msg))
      onMessage(messagePayload)
    }
    
    func websocketDidReceiveData(data: NSData) {
      println("got some data: \(data.length)")
    }
    
    func websocketDidDisconnect(error: NSError?) {
      println("socket closed: \(error?.localizedDescription)")
      onClose("reason: \(error?.localizedDescription)")
    }
    
    func websocketDidConnect() {
      println("socket opened")
      onOpen()
    }
    
    func websocketDidWriteError(error: NSError?) {
      onError(error!)
    }
    
    func unwrappedJsonString(string: String?) -> String {
      if let stringVal = string {
        return stringVal
      } else {
        return ""
      }
    }
    
    func payloadToJson(payload: Phoenix.Payload) -> String {
      var json = "{\"channel\": \"\(payload.channel)\", \"topic\": \"\(payload.topic)\", \"event\": \"\(payload.event)\", "
      if NSString(string: payload.message.toJsonString()).containsString("message") {
        let jsonMessage = JSON.parse(payload.message.toJsonString())["message"].toString()
        json += "\"message\": \(jsonMessage)"
      } else {
        json += "\"message\": \(payload.message.toJsonString())"
      }
      json += "}"
      println("payloadJson: \(json)")
      return json
    }
  }
}