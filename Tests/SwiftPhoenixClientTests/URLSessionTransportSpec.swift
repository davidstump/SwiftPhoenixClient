//
//  URLSessionTransportSpec.swift
//  SwiftPhoenixClientTests
//
//  Created by Daniel Rees on 4/1/21.
//  Copyright © 2021 SwiftPhoenixClient. All rights reserved.
//

import Quick
import Nimble
@testable import SwiftPhoenixClient

class URLSessionTransportSpec: QuickSpec {
  
  override func spec() {
    
    describe("init") {
      it("replaces http with ws protocols") {
        if #available(iOS 13, *) {
          expect(
            URLSessionTransport(url: URL(string:"http://localhost:4000/socket/websocket")!)
              .url.absoluteString
          ).to(equal("ws://localhost:4000/socket/websocket"))
          
          expect(
            URLSessionTransport(url: URL(string:"https://localhost:4000/socket/websocket")!)
              .url.absoluteString
          ).to(equal("wss://localhost:4000/socket/websocket"))
          
          expect(
            URLSessionTransport(url: URL(string:"ws://localhost:4000/socket/websocket")!)
              .url.absoluteString
          ).to(equal("ws://localhost:4000/socket/websocket"))
          
          expect(
            URLSessionTransport(url: URL(string:"wss://localhost:4000/socket/websocket")!)
              .url.absoluteString
          ).to(equal("wss://localhost:4000/socket/websocket"))
          
        } else {
          // Fallback on earlier versions
          expect("wrong iOS version").to(equal("You must run this test on an iOS 13 device"))
        }
      }
        
      it("accepts an override for the configuration") {
        if #available(iOS 13, *) {
          let configuration = URLSessionConfiguration.default
          expect(
            URLSessionTransport(url: URL(string:"wss://localhost:4000")!, configuration: configuration)
                .configuration
          ).to(equal(configuration))
        } else {
          // Fallback on earlier versions
          expect("wrong iOS version").to(equal("You must run this test on an iOS 13 device"))
        }
      }
    }
  }
}

