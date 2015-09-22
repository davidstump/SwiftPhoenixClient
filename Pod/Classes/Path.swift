//
//  Path.swift
//  SwiftPhoenix
//
//  Created by Kyle Oba on 8/23/15.
//  Copyright (c) 2015 David Stump. All rights reserved.
//

import Foundation

public struct Path {
  
  public static func removeTrailingSlash(path:String) -> String {
    if path.characters.count == 0 { return path }
    if path.substringWithRange(Range<String.Index>(start: path.endIndex.advancedBy(-1), end: path.endIndex)) == "/" {
      return path.substringWithRange(Range<String.Index>(start:path.startIndex, end: path.endIndex.advancedBy(-1)))
    }
    return path
  }
  
  public static func removeLeadingSlash(path:String) -> String {
    if path.characters.count == 0 { return path }
    if path.substringWithRange(Range<String.Index>(start: path.startIndex, end: path.startIndex.advancedBy(1))) == "/" {
      return path.substringWithRange(Range<String.Index>(start:path.startIndex.advancedBy(1), end: path.endIndex))
    }
    return path
  }
  
  public static func removeLeadingAndTrailingSlashes(path:String) -> String {
    return Path.removeTrailingSlash( Path.removeLeadingSlash(path) )
  }
  
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