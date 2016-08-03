//
//  Phoenix.swift
//  SwiftPhoenix
//
//  Created by David Stump on 12/1/14.
//  Copyright (c) 2014 David Stump. All rights reserved.
//

import Foundation
import Starscream

public struct Phoenix {

  // MARK: Phoenix Message
  public class Message: Serializable {
    var subject: String?
    var body: AnyObject?
    public var message: AnyObject?

    /**
     Initializes single entry message with a subject

     - parameter subject: String for message key
     - parameter body:    String for message body

     - returns: Phoenix.Message
     */
    public init(subject: String, body: AnyObject) {
      (self.subject, self.body) = (subject, body)
      super.init()
      create()
    }

    /**
     Initializes a multi key message

     - parameter message: Dictionary containing message payload

     - returns: Phoenix.Message
     */
    public init(message: AnyObject) {
      self.message = message
      super.init()
      create(false)
    }

    /**
     Creates a new single or multi key message

     - parameter single: Boolean indicating if the message is a single key or not

     - returns: Phoenix.Message
     */
    func create(single: Bool = true) -> [String: AnyObject] {
      if single {
        return [self.subject!: self.body!]
      } else {
        return self.message! as! [String: AnyObject]
      }
    }
  }

  // MARK: Phoenix Binding
  class Binding {
    var event: String
    var callback: AnyObject -> Void?

    /**
     Initializes an object for handling event/callback bindings

     - parameter event:    String indicating event name
     - parameter callback: Function to run on given event

     - returns: Tuple containing event and callback function
     */
    init(event: String, callback: AnyObject -> Void?) {
      (self.event, self.callback) = (event, callback)
      create()
    }

    /**
     Creates a Phoenix.Binding object holding event/callback details

     - returns: Tuple containing event and callback function
     */
    func create() -> (String, AnyObject -> Void?) {
      return (event, callback)
    }
  }

  // MARK: Phoenix Channel
  public class Channel {
    var bindings: [Phoenix.Binding] = []
    var topic: String?
    var message: Phoenix.Message?
    var callback: (AnyObject -> Void?)
    weak var socket: Phoenix.Socket?

    /**
     Initializes a new Phoenix.Channel mapping to a server-side channel

     - parameter topic:    String topic for given channel
     - parameter message:  Phoenix.Message object containing message to send
     - parameter callback: Function to pass along with the channel instance
     - parameter socket:   Phoenix.Socket for websocket connection

     - returns: Phoenix.Channel
     */
    init(topic: String, message: Phoenix.Message, callback: (AnyObject -> Void), socket: Phoenix.Socket) {
      (self.topic, self.message, self.callback, self.socket) = (topic, message, { callback($0) }, socket)
      reset()
    }

    /**
     Removes existing bindings
     */
    func reset() {
      bindings = []
    }

    /**
     Assigns Binding events to the channel bindings array

     - parameter event:    String event name
     - parameter callback: Function to run on event
     */
    public func on(event: String, callback: (AnyObject -> Void)) {
      bindings.append(Phoenix.Binding(event: event, callback: { callback($0) }))
    }

    /**
     Determine if a topic belongs in this channel

     - parameter topic: String topic name for comparison

     - returns: Boolean
     */
    func isMember(topic  topic: String) -> Bool {
      return self.topic == topic
    }

    /**
     Removes an event binding from this cahnnel

     - parameter event: String event name
     */
    func off(event: String) {
      var newBindings: [Phoenix.Binding] = []
      for binding in bindings {
        if binding.event != event {
          newBindings.append(Phoenix.Binding(event: binding.event, callback: binding.callback))
        }
      }
      bindings = newBindings
    }

    /**
     Triggers an event on this channel

     - parameter triggerEvent: String event name
     - parameter msg:          Phoenix.Message to pass into event callback
     */
    func trigger(triggerEvent: String, msg: Phoenix.Message) {
      for binding in bindings {
        if binding.event == triggerEvent {
          binding.callback(msg)
        }
      }
    }

    /**
     Sends and event and message through the socket

     - parameter event:   String event name
     - parameter message: Phoenix.Message payload
     */
    func send(event: String, message: Phoenix.Message) {
      print("conn sending")
      let payload = Phoenix.Payload(topic: topic!, event: event, message: message)
      socket?.send(payload)
    }

    /**
     Leaves the socket

     - parameter message: Phoenix.Message to pass to the Socket#leave function
     */
    func leave(message: Phoenix.Message) {
      if let sock = socket {
        sock.leave(topic: topic!, message: message)
      }
      reset()
    }
  }

  // MARK: Phoenix Payload
  public class Payload {
    var topic: String
    var event: String
    var message: Phoenix.Message

    /**
     Initializes a formatted Phoenix.Payload

     - parameter topic:   String topic name
     - parameter event:   String event name
     - parameter message: Phoenix.Message payload

     - returns: Phoenix.Payload
     */
    public init(topic: String, event: String, message: Phoenix.Message) {
      (self.topic, self.event, self.message) = (topic, event, message)
    }

  }

  // MARK: Phoenix Socket
  public class Socket: NSObject, WebSocketDelegate {
    var conn: WebSocket?
    var endPoint: String?
    var channels: [Phoenix.Channel] = []

    var sendBuffer: [Void] = []
    var sendBufferTimer = NSTimer()
    let flushEveryMs = 1.0

    var reconnectTimer = NSTimer()
    let reconnectAfterMs = 1.0

    var heartbeatTimer = NSTimer()
    let heartbeatDelay = 30.0

    var messageReference: UInt64 = UInt64.min // 0 (max: 18,446,744,073,709,551,615)

    /**
     Initializes a Socket connection

     - parameter domainAndPort: Phoenix server root path and proper port
     - parameter path:          Websocket path on Phoenix Server
     - parameter transport:     Transport for Phoenix.Server - traditionally "websocket"
     - parameter prot:          Connection protocol - default is HTTP

     - returns: Phoenix.Socket
     */
    public init(domainAndPort:String, path:String, transport:String, prot:String = "http") {
      self.endPoint = Path.endpointWithProtocol(prot, domainAndPort: domainAndPort, path: path, transport: transport)
      super.init()
      resetBufferTimer()
      reconnect()
    }

    /**
     Closes socket connection

     - parameter callback: Function to run after close
     */
    public func close(callback: (() -> ()) = {}) {
      if let connection = self.conn {
        connection.delegate = nil
        connection.disconnect()
      }
      invalidateTimers()
      callback()
    }

    /**
      Invalidate open timers to allow socket to be deallocated when closed
    */
    func invalidateTimers() {
      heartbeatTimer.invalidate()
      reconnectTimer.invalidate()
      sendBufferTimer.invalidate()

      heartbeatTimer = NSTimer()
      reconnectTimer = NSTimer()
      sendBufferTimer = NSTimer()
    }

    /**
     Initializes a 30s timer to let Phoenix know this device is still alive
     */
    func startHeartbeatTimer() {
      heartbeatTimer.invalidate()
      heartbeatTimer = NSTimer.scheduledTimerWithTimeInterval(heartbeatDelay, target: self, selector: #selector(Phoenix.Socket.heartbeat), userInfo: nil, repeats: true)
    }

    /**
     Heartbeat payload (Phoenix.Message) to send with each pulse
     */
    func heartbeat() {
      let message = Phoenix.Message(message: ["body": "Pong"])
      let payload = Phoenix.Payload(topic: "phoenix", event: "heartbeat", message: message)
      send(payload)
    }

    /**
     Reconnects to a closed socket connection
     */
    public func reconnect() {
      close() {
        self.conn = WebSocket(url: NSURL(string: self.endPoint!)!)
        if let connection = self.conn {
          connection.delegate = self
          connection.connect()
        }
      }
    }

    /**
     Resets the message buffer timer and invalidates any existing ones
     */
    func resetBufferTimer() {
      sendBufferTimer.invalidate()
      sendBufferTimer = NSTimer.scheduledTimerWithTimeInterval(flushEveryMs, target: self, selector: #selector(Phoenix.Socket.flushSendBuffer), userInfo: nil, repeats: true)
      sendBufferTimer.fire()
    }

    /**
     Kills reconnect timer and joins all open channels
     */
    func onOpen() {
      reconnectTimer.invalidate()
      startHeartbeatTimer()
      rejoinAll()
    }

    /**
     Starts reconnect timer onClose

     - parameter event: String event name
     */
    func onClose(event: String) {
      reconnectTimer.invalidate()
      reconnectTimer = NSTimer.scheduledTimerWithTimeInterval(reconnectAfterMs, target: self, selector: #selector(Phoenix.Socket.reconnect), userInfo: nil, repeats: true)
    }

    /**
     Triggers error event

     - parameter error: NSError
     */
    func onError(error: NSError) {
      print("Error: \(error)")
      for chan in channels {
        let msg = Phoenix.Message(message: ["body": error.localizedDescription])
        chan.trigger("error", msg: msg)
      }
    }

    /**
     Indicates if connection is established

     - returns: Bool
     */
    func isConnected() -> Bool {
      if let connection = self.conn {
        return connection.isConnected
      } else {
        return false
      }

    }

    /**
     Rejoins all Phoenix.Channel instances
     */
    func rejoinAll() {
      for chan in channels {
        rejoin(chan as Phoenix.Channel)
      }
    }

    /**
     Rejoins a given Phoenix Channel

     - parameter chan: Phoenix.Channel
     */
    func rejoin(chan: Phoenix.Channel) {
      chan.reset()
      if let topic = chan.topic, joinMessage = chan.message {
          let payload = Phoenix.Payload(topic: topic, event: "phx_join", message: joinMessage)
          send(payload)
          chan.callback(chan)
      }
    }

    /**
     Joins socket

     - parameter topic:    String topic name
     - parameter message:  Phoenix.Message payload
     - parameter callback: Function to trigger after join
     */
    public func join(topic  topic: String, message: Phoenix.Message, callback: (AnyObject -> Void)) {
      let chan = Phoenix.Channel(topic: topic, message: message, callback: callback, socket: self)
      channels.append(chan)
      if isConnected() {
        print("joining")
        rejoin(chan)
      }
    }

    /**
     Leave open socket

     - parameter topic:   String topic name
     - parameter message: Phoenix.Message payload
     */
    public func leave(topic  topic: String, message: Phoenix.Message) {
      let leavingMessage = Phoenix.Message(subject: "status", body: "leaving")
      let payload = Phoenix.Payload(topic: topic, event: "phx_leave", message: leavingMessage)
      send(payload)
      var newChannels: [Phoenix.Channel] = []
      for chan in channels {
        let c = chan as Phoenix.Channel
        if !c.isMember(topic: topic) {
          newChannels.append(c)
        }
      }
      channels = newChannels
    }

    /**
     Send payload over open socket

     - parameter data: Phoenix.Payload
     */
    public func send(data: Phoenix.Payload) {
      let callback = {
        (payload: Phoenix.Payload) -> Void in
        if let connection = self.conn {
          let json = self.payloadToJson(payload)
          print("json: \(json)")
          connection.writeString(json)
        }
      }
      if isConnected() {
        callback(data)
      } else {
        sendBuffer.append(callback(data))
      }
    }

    /**
     Flush message buffer
     */
    func flushSendBuffer() {
      if isConnected() && sendBuffer.count > 0 {
        for callback in sendBuffer {
          callback
        }
        sendBuffer = []
        resetBufferTimer()
      }
    }

    /**
     Trigger event on message received

     - parameter payload: Phoenix.Payload
     */
    func onMessage(payload: Phoenix.Payload) {
      let (topic, event, message) = (payload.topic, payload.event, payload.message)
      for chan in channels {
        if chan.isMember(topic: topic) {
          chan.trigger(event, msg: message)
        }
      }
    }

    // WebSocket Delegate Methods
    public func websocketDidReceiveMessage(socket: WebSocket, text: String) {
      print("socket message: \(text)")
      let json = JSON.parse(text as NSString as String as String)
      let (topic, event) = (
        unwrappedJsonString(json["topic"].asString),
        unwrappedJsonString(json["event"].asString)
      )
      let msg: [String: AnyObject] = json["payload"].asDictionary!

      let messagePayload = Phoenix.Payload(topic: topic, event: event, message: Phoenix.Message(message: msg))
      onMessage(messagePayload)
    }

    public func websocketDidReceiveData(socket: WebSocket, data: NSData) {
      print("got some data: \(data.length)")
    }

    public func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
      if let err = error { onError(err) }
      print("socket closed: \(error?.localizedDescription)")
      onClose("reason: \(error?.localizedDescription)")
    }

    public func websocketDidConnect(socket: WebSocket) {
      print("socket opened")
      onOpen()
    }

    public func websocketDidWriteError(error: NSError?) {
      onError(error!)
    }

    func unwrappedJsonString(string: String?) -> String {
      if let stringVal = string {
        return stringVal
      } else {
        return ""
      }
    }

    func makeRef() -> UInt64 {
      let newRef = messageReference + 1
      messageReference = (newRef == UINT64_MAX) ? 0 : newRef
      return newRef
    }

    func payloadToJson(payload: Phoenix.Payload) -> String {
      let ref = makeRef()
      var json = "{\"topic\": \"\(payload.topic)\", \"event\": \"\(payload.event)\", \"ref\": \"\(ref)\", "
      if NSString(string: payload.message.toJsonString()).containsString("message") {
        let msg = JSON.parse(String(payload.message.toJsonString()))["message"]
        let jsonMessage = msg.toString(true)
        json += "\"payload\": \(jsonMessage)"
      } else {
        json += "\"payload\": \(payload.message.toJsonString())"
      }
      json += "}"

      return json
    }
  }
}
