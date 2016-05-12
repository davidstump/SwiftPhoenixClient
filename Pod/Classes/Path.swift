//
//  Path.swift
//  SwiftPhoenix
//
//  Created by Kyle Oba on 8/23/15.
//  Copyright (c) 2015 David Stump. All rights reserved.
//

import Foundation

public struct Path {
  
  /**
   Reomoves trailing slash from URL string
   
   - parameter path: String path
   
   - returns: String
   */
  public static func removeTrailingSlash(path:String) -> String {
    if path.characters.count == 0 { return path }
    if path.substringWithRange(Range<String.Index>(start: path.endIndex.advancedBy(-1), end: path.endIndex)) == "/" {
      return path.substringWithRange(Range<String.Index>(start:path.startIndex, end: path.endIndex.advancedBy(-1)))
    }
    return path
  }
  
  /**
   Remove Leading Slash from URL string
   
   - parameter path: String path
   
   - returns: String
   */
  public static func removeLeadingSlash(path:String) -> String {
    if path.characters.count == 0 { return path }
    if path.substringWithRange(Range<String.Index>(start: path.startIndex, end: path.startIndex.advancedBy(1))) == "/" {
      return path.substringWithRange(Range<String.Index>(start:path.startIndex.advancedBy(1), end: path.endIndex))
    }
    return path
  }
  
  /**
   Remove both leading and trailing URL slashes
   
   - parameter path: String path
   
   - returns: String
   */
  public static func removeLeadingAndTrailingSlashes(path:String) -> String {
    return Path.removeTrailingSlash( Path.removeLeadingSlash(path) )
  }
  
  /**
   Builds proper endoint
   
   - parameter prot:          Endpoint protocol - usually 'ws'
   - parameter domainAndPort: Phoenix server root domain and port
   - parameter path:          Phoenix server socket path
   - parameter transport:     Server transport - usually "websocket"
   
   - returns: String
   */
  public static func endpointWithProtocol(prot:String, domainAndPort:String, path:String, transport:String) -> String {
    var theProt = ""
    switch prot {
    case "ws":
      theProt = "http"
    case "wss":
      theProt = "https"
    default:
      theProt = prot
    }
    
    let theDomAndPort = removeLeadingAndTrailingSlashes(domainAndPort)
    let thePath = removeLeadingAndTrailingSlashes(path)
    let theTransport = removeLeadingAndTrailingSlashes(transport)
    return "\(theProt)://\(theDomAndPort)/\(thePath)/\(theTransport)"
  }
}