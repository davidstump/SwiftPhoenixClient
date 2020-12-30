//
//  StarscreamTransport.swift
//  StarscreamSwiftPhoenixClient
//
//  Created by Daniel Rees on 12/30/20.
//  Copyright © 2020 SwiftPhoenixClient. All rights reserved.
//

import Foundation
import SwiftPhoenixClient
import Starscream


/**
 A `Transport` implemenetation that relies on a WebSocket provided by the `Starscream` library.
 
 https://github.com/daltoniam/Starscream
 
 This `Transport` implementation is available on iOS 10 where as the `URLSessionTransport` that
 ships as the default in `SwiftPhoenixClient` is only available starting in iOS 13.
 
 In order to use this `Transport`, you will have to provide it to the `Socket` class during
 iniitialization.
 
 ```swift
 let socket = Socket("https://example.com/") { url in return StarscreamTransport(url: url) }
 ```
 */
@available(macOS 10.12, iOS 10, watchOS 3, tvOS 10, *)
public class StarscreamTransport: NSObject, Transport {
  
  /// The URL to connect to
  private let url: URL
  
  /// The underlying Starscream WebSocket that data is transfered over.
  private let socket: WebSocket? = nil
  
  
  
  /**
   Initializes a `Transport` layer built using Starscream's WebSocket, which is a viable
   socket to use prior to iOS 13.
   
   Example:
   
   ```swift
   let url = URL("wss://example.com/socket")
   let transport: Transport = StarscreamTransport(url: url)
   ```
   
   - parameter url: URL to connect to
   */
  init(url: URL) {
    self.url = url
    super.init()
  }
  
  
  // MARK: - Transport
  public var readyState: TransportReadyState = .closed
  public var delegate: TransportDelegate? = nil
  
  public func connect() {
    // Set the trasport state as connecting
    self.readyState = .connecting
    
    let request = URLRequest(url: url)
    self.socket = WebSocket(request: request)
    self.socket.delegate = self
    self.socket.connect()
  }
  
  public func disconnect(code: Int, reason: String?) {
    /*
     TODO:
     1. Provide a "strict" mode that fails if an invalid close code is given
     2. If strict mode is disabled, default to CloseCode.invalid
     3. Provide default .normalClosure function
     */
    guard let closeCode = URLSessionWebSocketTask.CloseCode.init(rawValue: code) else {
      fatalError("Could not create a CloseCode with invalid code: [\(code)].")
    }
    
    self.readyState = .closing
    self.socket?.disconnect(closeCode: closeCode)
  }
  
  public func send(data: Data) {
    self.socket.write(data: data)
    
  }
  
  
  // MARK: - WebSocketDelegate
  func didReceive(event: WebSocketEvent, client: WebSocket) {
    switch event {
    case .connected(let headers):
        isConnected = true
        print("websocket is connected: \(headers)")
      case .disconnected(let reason, let code):
        isConnected = false
        print("websocket is disconnected: \(reason) with code: \(code)")
      case .text(let string):
        print("Received text: \(string)")
      case .binary(let data):
        print("Received data: \(data.count)")
      case .cancelled:
        isConnected = false
      case .error(let error):
        isConnected = false
        handleError(error)
    default:
        
    }
  }
  
  
}
