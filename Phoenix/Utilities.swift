//
//  Utilities.swift
//  Phoenix
//
//  Created by David Stump on 8/23/14.
//  Copyright (c) 2014 David Stump. All rights reserved.
//

import Foundation

func JSONStringify(jsonObj: AnyObject) -> String {
  var e: NSError?
  let jsonData = NSJSONSerialization.dataWithJSONObject(
    jsonObj,
    options: NSJSONWritingOptions(0),
    error: &e)
  if let e = e {
    return ""
  } else {
    return NSString(data: jsonData, encoding: NSUTF8StringEncoding)
  }
}

func JSONParseDict(jsonString:String) -> Phoenix.Payload {
  var e: NSError?
  var data:NSData = jsonString.dataUsingEncoding(NSUTF8StringEncoding)!
  var jsonObj = NSJSONSerialization.JSONObjectWithData(
    data,
    options: NSJSONReadingOptions(0),
    error: &e) as Phoenix.Payload
  if let e = e {
    return Phoenix.Payload(channel: "", topic: "", event: "", message: nil)
  } else {
    return jsonObj
  }
}