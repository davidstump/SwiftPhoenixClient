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
    fileprivate var array = [Element]()

    func append( _ newElement: Element) {
        queue.async(flags: .barrier) {
            self.array.append(newElement)
        }
    }
    
    func removeAll(where shouldBeRemoved: @escaping (Element) -> Bool) {
        queue.async(flags: .barrier) {
            self.array.removeAll(where: shouldBeRemoved)
        }
    }
    
    func removeAll() {
        queue.async(flags: .barrier) {
            self.array.removeAll()
        }
    }
    
    func forEach(_ body: @escaping (Element) -> Void) {
        queue.async(flags: .barrier) {
            self.array.forEach(body)
        }
    }
    
    func filter(_ isIncluded: (Element) -> Bool) -> SynchronizedArray<Element> {
        let result = SynchronizedArray<Element>()
        queue.sync {
            self.array.filter(isIncluded).forEach {
                result.append($0)
            }
        }
        return result
    }
}


