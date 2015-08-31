//
//  PathTests.swift
//  SwiftPhoenix
//
//  Created by Kyle Oba on 8/23/15.
//  Copyright (c) 2015 David Stump. All rights reserved.
//

import UIKit
import XCTest
import SwiftPhoenixClient

class PathTests: XCTestCase {

  let pathWithSlashes = "/socket/websocket/"
  let pathWithLeadingSlash = "/socket/websocket"
  let pathWithTrailingSlash = "/socket/websocket"
  let pathWithNoLeadingOrTrailingSlash = "socket/websocket"
  let pathWithOnlySlash = "/"
  let pathWithBlank = ""

  func testRemoveLeadingAndTrailingSlashes() {
    // This is an example of a functional test case.
//    XCTAssert(true, "Pass")
    XCTAssertEqual(Path.removeLeadingAndTrailingSlashes(pathWithSlashes), "socket/websocket", "Strips slashes from beginning and end of string")
    XCTAssertEqual(Path.removeLeadingAndTrailingSlashes(pathWithLeadingSlash), "socket/websocket", "Strips slashes from beginning of string")
    XCTAssertEqual(Path.removeLeadingAndTrailingSlashes(pathWithTrailingSlash), "socket/websocket", "Strips slashes from end of string")
    XCTAssertEqual(Path.removeLeadingAndTrailingSlashes(pathWithNoLeadingOrTrailingSlash), "socket/websocket", "Preserves path even without leading and trailing slashes")
    XCTAssertEqual(Path.removeLeadingAndTrailingSlashes(pathWithOnlySlash), "", "Removes only a slash")
    XCTAssertEqual(Path.removeLeadingAndTrailingSlashes(pathWithBlank), "", "Handles blank")
  }

  func testendpointWithProtocol() {
    XCTAssertEqual(Path.endpointWithProtocol("ws", domainAndPort: "localhost:4000", path: "socket", transport: "websocket"), "http://localhost:4000/socket/websocket", "Should format a Phoenix endpoint URL.")
  }
  
}
