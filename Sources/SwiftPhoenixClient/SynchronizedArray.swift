//
//  SynchronizedArray.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 4/12/23.
//  Copyright © 2023 SwiftPhoenixClient. All rights reserved.
//

import Foundation

/// A thread-safe array.
public class SynchronizedArray<Element> {
    fileprivate let queue = DispatchQueue(label: "spc_sync_array", attributes: .concurrent)
    fileprivate var array: [Element]
    
    public init(_ array: [Element] = []) {
        self.array = array
    }
    
    public func copy() -> [Element] {
        queue.sync { self.array }
    }
    
    func append( _ newElement: Element) {
        queue.async(flags: .barrier) {
            self.array.append(newElement)
        }
    }
    
    func first(where predicate: (Element) -> Bool) -> Element? {
        queue.sync { self.array.first(where: predicate) }
    }
    
    func forEach(_ body: (Element) -> Void) {
        queue.sync { self.array }.forEach(body)
    }
    
    func removeAll() {
        queue.async(flags: .barrier) {
            self.array.removeAll()
        }
    }
    
    func removeAll(where shouldBeRemoved: @escaping (Element) -> Bool) {
        queue.async(flags: .barrier) {
            self.array.removeAll(where: shouldBeRemoved)
        }
    }
}
