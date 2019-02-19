//
//  Binding.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 2/19/19.
//

struct Binding {
    
    // The event that the Binding is bound to
    let event: String
    
    // The reference number of the Binding
    let ref: Int
    
    // The callback to be triggered
    let callback: Delegated<Message, Void>
    
    
    init(_ event: String, _ ref: Int, _ callback: Delegated<Message, Void>) {
        self.event = event
        self.ref = ref
        self.callback = callback
    }
}
