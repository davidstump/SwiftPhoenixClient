//
//  Outbound.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 2/10/18.
//

import Foundation

public class Push {
    
    /// Topic to send in an outbound message
    public let topic: String
    
    /// Event to send in an outbound message
    public let event: String
    
    /// Paylopad to send in an outbound message
    public let payload: Payload
    
    /// Ref ID of an outbound message
    let ref: String
    
    
    /// Caches a status if received before handler was registered
    fileprivate var receivedStatus: String?
    
    /// Caches a payload if received before handler was registered
    fileprivate var receivedResponse: Payload?
    
    
    /// Custom handlers which will fire when an outbound message is sent to the server
    /// such as "ok", "error", etc
    fileprivate var handlers: [String: [(Payload) -> ()]] = [:]
    
    /// Custom handlers which will always fire on any send event
    fileprivate var alwaysHandlers: [() -> ()] = []


    
    /// Initializes a new Outbound message to be sent through the Socket
    ///
    /// - parameter topic: Topic to send to
    /// - parameter event: Event to send
    /// - parameter payload: Payload to send
    /// - parameter ref: Optional. Ref number to send. Use socket.makeRef to get a reference number
    public init(topic: String, event: String, payload: Payload, ref: String) {
        self.topic = topic
        self.event = event
        self.payload = payload
        self.ref = ref
    }
    
    
    /// Converts the object to JSON data
    ///
    /// - throws: If object could not be serialized into JSON data
    /// - return: JSON data representation of the object
    public func toJson() throws -> Data {
        let dict = [
            "topic": topic,
            "event": event,
            "payload": payload,
            "ref": ref,
            ] as [String : Any]
        
        return try JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions())
    }
    
    //----------------------------------------------------------------------
    // MARK: - Handler Registration
    //----------------------------------------------------------------------
    /// Receive a specific event when sending an Outbound message
    ///
    /// Example:
    ///     channel
    ///         .send(event:"custom", payload: ["body": "example"])
    ///         .receive("error") { payload in
    ///             print("Error: ", payload)
    ///         }
    ///
    @discardableResult
    public func receive(_ status: String, handler: @escaping ((Payload) -> Void)) -> Push {
        if receivedStatus == status,
            let receivedResponse = receivedResponse {
            handler(receivedResponse)
        } else {
            if (handlers[status] == nil) {
                handlers[status] = [handler]
            } else {
                handlers[status]?.append(handler)
            }
        }

        return self
    }
    
    /// Always receive a callback on any event
    @discardableResult
    public func always(_ handler: @escaping () -> ()) -> Push {
        alwaysHandlers.append(handler)
        return self
    }
    
    
    //----------------------------------------------------------------------
    // MARK: - Response Handling
    //----------------------------------------------------------------------
    func handleResponse(_ response: Response) {
        receivedStatus = response.payload["status"] as? String
        receivedResponse = response.payload
        
        fireCallbacksAndCleanup()
    }
    
    func handleParseError() {
        receivedStatus = "error"
        receivedResponse = ["reason": "Invalid payload request." as AnyObject]
        
        fireCallbacksAndCleanup()
    }
    
    func handleNotConnected() {
        receivedStatus = "error"
        receivedResponse = ["reason": "Not connected to socket." as AnyObject]
        
        fireCallbacksAndCleanup()
    }
    
    func fireCallbacksAndCleanup() {
        defer {
            handlers.removeAll()
            alwaysHandlers.removeAll()
        }
        
        guard let status = receivedStatus else { return }
        alwaysHandlers.forEach({$0()})
        
        if let matchingCallbacks = handlers[status], let receivedResponse = receivedResponse {
                matchingCallbacks.forEach({$0(receivedResponse)})
        }
    }
}
