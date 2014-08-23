//
//  Payload.swift
//  Phoenix
//
//  Created by David Stump on 8/23/14.
//  Copyright (c) 2014 David Stump. All rights reserved.
//

import Foundation

@objc class Payload {
  var channel: String
  var topic: String
  var event: String
  var message: Phoenix.Message?
  
  init(channel: String, topic: String, event: String, message: Phoenix.Message?) {
    (self.channel, self.topic, self.event, self.message) = (channel, topic, event, message)
    create()
  }
  
  func create() -> [String: AnyObject?] {
    return ["channel": channel, "topic": topic, "event": event, "message": message]
  }
  
}