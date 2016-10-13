//
//  Binding.swift
//  SwiftPhoenixClient
//

import Swift

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
     Creates a Binding object holding event/callback details
     - returns: Tuple containing event and callback function
     */
    func create() -> (String, (Any) -> Void?) {
        return (event, callback)
    }
}
