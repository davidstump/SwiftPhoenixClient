//
//  binding.swift
//  Phoenix
//
//  Created by David Stump on 8/23/14.
//  Copyright (c) 2014 David Stump. All rights reserved.
//

import Foundation

@objc class Binding {
  var event: String
  var callback: AnyObject -> Void?
  
  init(event: String, callback: AnyObject -> Void?) {
    (self.event, self.callback) = (event, callback)
    create()
  }
  
  func create() {
    (event, callback)
  }
}