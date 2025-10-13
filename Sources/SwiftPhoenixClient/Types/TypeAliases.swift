//
//  TypeAliases.swift
//  Examples
//
//  Created by Daniel Rees on 10/9/25.
//  Copyright © 2025 SwiftPhoenixClient. All rights reserved.
//

import Foundation

///
/// Type Alias that defines a callback that takes which attempt number is being
/// tried and returns a `TimerInterval` corresponding to the attempt.
///
public typealias SteppedBackoff = @Sendable (_ tries: Int) -> TimeInterval




