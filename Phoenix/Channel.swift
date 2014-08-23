//
//  Channel.swift
//  Phoenix
//
//  Created by David Stump on 8/23/14.
//  Copyright (c) 2014 David Stump. All rights reserved.
//

import Foundation

@objc class Channel {
  var bindings = Array<Phoenix.Binding>()
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
    bindings = Array<Phoenix.Binding>()
  }
  
  func on(event: String, callback: (AnyObject -> Void)) {
    bindings.append(Phoenix.Binding(event: event, callback: callback))
  }
  
  func isMember(channel: String, topic: String) -> Bool {
    return self.channel == channel && self.topic == topic
  }
  
  func off(event: String) {
    var newBindings = Array<Phoenix.Binding>()
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