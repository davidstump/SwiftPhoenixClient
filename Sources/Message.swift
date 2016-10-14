//
//  Message.swift
//  SwiftPhoenixClient
//

import Swift

public class Message: Serializable {
    var subject: String?
    var body: Any?
    public var message: Any?

    /**
     Initializes single entry message with a subject
     - parameter subject: String for message key
     - parameter body:    String for message body
     - returns: Message
     */
    public init(subject: String, body: Any) {
        (self.subject, self.body) = (subject, body)
        super.init()
        create()
    }

    /**
     Initializes a multi key message
     - parameter message: Dictionary containing message payload
     - returns: Message
     */
    public init(message: Any) {
        self.message = message
        super.init()
        create(single: false)
    }

    /**
     Creates a new single or multi key message
     - parameter single: Boolean indicating if the message is a single key or not
     - returns: Message
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
