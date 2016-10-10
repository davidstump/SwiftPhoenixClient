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
        var body: Any?
        public var message: Any?

        /**
         Initializes single entry message with a subject
         - parameter subject: String for message key
         - parameter body:    String for message body
         - returns: Phoenix.Message
         */
        public init(subject: String, body: Any) {
            (self.subject, self.body) = (subject, body)
            super.init()
            create()
        }

        /**
         Initializes a multi key message
         - parameter message: Dictionary containing message payload
         - returns: Phoenix.Message
         */
        public init(message: Any) {
            self.message = message
            super.init()
            create(single: false)
        }

        /**
         Creates a new single or multi key message
         - parameter single: Boolean indicating if the message is a single key or not
         - returns: Phoenix.Message
         */
        func create(single: Bool = true) -> [String: Any] {
            if single {
                return [self.subject!: self.body! as Any]
            } else {
                return self.message! as! [String: Any]
            }
        }

        /**
         Needed a way to allow for easy subscripting on a message's message
         This previously was built into AnyObject but Any is more
         flexible and easier to work with since it captures String, Array etc
         */
        public subscript(key: String) -> Any? {
            get {
                if let msg = self.message as? [AnyHashable: Any] {
                    return msg[key]
                }
                return nil
            }
        }
    }

    // MARK: Phoenix Binding
    class Binding {
        var event: String
        var callback: (Any) -> Void?

        /**
         Initializes an object for handling event/callback bindings
         - parameter event:    String indicating event name
         - parameter callback: Function to run on given event
         - returns: Tuple containing event and callback function
         */
        @discardableResult
        init(event: String, callback: @escaping (Any) -> Void?) {
            (self.event, self.callback) = (event, callback)
            create()
        }

        /**
         Creates a Phoenix.Binding object holding event/callback details
         - returns: Tuple containing event and callback function
         */
        func create() -> (String, (Any) -> Void?) {
            return (event, callback)
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
}
