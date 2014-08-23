//
//  message.swift
//  Phoenix
//
//  Created by David Stump on 8/23/14.
//  Copyright (c) 2014 David Stump. All rights reserved.
//

import Foundation

@objc class Message {
  var subject: String
  var body: AnyObject?
  
  init(subject: String, body: AnyObject?) {
    (self.subject, self.body) = (subject, body)
    create()
  }
  
  func create() -> [String: AnyObject?] {
    return [self.subject: self.body]
  }
}