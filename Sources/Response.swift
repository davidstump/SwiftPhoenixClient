//
//  Response.swift
//  SwiftPhoenixClient
//
//  All the credit in the world to the Birdsong repo for a good swift
//  implementation of Presence. Please check out that repo/library for
//  a good Swift Channels alternative
//
//  Created by Simon Manning on 6/07/2016.
//

import Foundation

public class Response {
  public let ref: String
  public let topic: String
  public let event: String
  public let payload: [String: AnyObject]
  
  init?(data: NSData) {
    do {
      let jsonObject = try JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions()) as! [String: AnyObject]
      if let ref = jsonObject["ref"] as? String {
        self.ref = ref
      }
      else {
        self.ref = ""
      }
      topic = jsonObject["topic"] as! String
      event = jsonObject["event"] as! String
      payload = jsonObject["payload"] as! [String: AnyObject]
    }
    catch {
      return nil
    }
  }
}
