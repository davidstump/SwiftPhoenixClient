//
//  LocalViewModel.swift
//  Examples
//
//  Created by Daniel Rees on 10/9/25.
//  Copyright © 2025 SwiftPhoenixClient. All rights reserved.
//

import Foundation
import SwiftPhoenixClient

@MainActor
final class LocalViewModel: ObservableObject {
    
    func connect() {
        
        let socket = Socket("foo", option: .init(
            heartbeatInterval: <#T##TimeInterval#>
        ))
    }
}
