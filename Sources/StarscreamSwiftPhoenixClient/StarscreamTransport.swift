//
//  StarscreamTransport.swift
//  StarscreamSwiftPhoenixClient
//
//  Created by Daniel Rees on 12/30/20.
//  Copyright © 2021 SwiftPhoenixClient. All rights reserved.
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
public class StarscreamTransport: NSObject, PhoenixTransport, WebSocketDelegate {
  
  /// The URL to connect to
  private let url: URL
  
  /// The underlying Starscream WebSocket that data is transfered over.
  private var socket: WebSocket? = nil
  
  
  
  /**
   Initializes a `Transport` layer built using Starscream's WebSocket, which is available for
   previous iOS targets back to iOS 10.
   
   If you are targeting iOS 13 or later, then you do not need to use this transport layer unless
   you specifically prefer using Starscream as the underlying Socket connection.
   
   Example:
   
   ```swift
   let url = URL("wss://example.com/socket")
   let transport: Transport = StarscreamTransport(url: url)
   ```
   
   - parameter url: URL to connect to
   */
  public init(url: URL) {
    self.url = url
    super.init()
  }
  
  
  // MARK: - Transport
  public var readyState: PhoenixTransportReadyState = .closed
  public var delegate: PhoenixTransportDelegate? = nil
  
  public func connect() {
    // Set the trasport state as connecting
    self.readyState = .connecting
    
    let socket = WebSocket(url: url)
    socket.delegate = self
    socket.connect()
    
    self.socket = socket
  }
  
  public func disconnect(code: Int, reason: String?) {
    /*
     TODO:
     1. Provide a "strict" mode that fails if an invalid close code is given
     2. If strict mode is disabled, default to CloseCode.invalid
     3. Provide default .normalClosure function
     */
    guard
      let closeCode = CloseCode.init(rawValue: UInt16(code)) else {
      fatalError("Could not create a CloseCode with invalid code: [\(code)].")
    }
    
    self.readyState = .closing
    self.socket?.disconnect(closeCode: closeCode.rawValue)
  }
  
  public func send(data: Data) {
    self.socket?.write(data: data)
  }
  
  
  // MARK: - WebSocketDelegate
  public func websocketDidConnect(socket: WebSocketClient) {
    self.readyState = .open
    self.delegate?.onOpen()
  }

  public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
    
    let closeCode = (error as? WSError)?.code ?? Socket.CloseCode.abnormal.rawValue
    // Set the state of the Transport to closed
    self.readyState = .closed
    
    // Inform the Transport's delegate that an error occurred.
    if let safeError = error { self.delegate?.onError(error: safeError) }
    
    // An abnormal error is results in an abnormal closure, such as internet getting dropped
    // so inform the delegate that the Transport has closed abnormally. This will kick off
    // the reconnect logic.
    self.delegate?.onClose(code: closeCode)
  }

  public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
    self.delegate?.onMessage(message: text)
  }

  public func websocketDidReceiveData(socket: WebSocketClient, data: Data) { /* no-op */ }
}
