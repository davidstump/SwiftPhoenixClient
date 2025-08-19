//
//  ValueLock.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 3/30/25.
//  Copyright © 2025 SwiftPhoenixClient. All rights reserved.
//

import Foundation

/// A generic wrapper for isolating a mutable value with a lock.
///
/// See LockIsolated.swift from https://github.com/pointfreeco/swift-concurrency-extras
@dynamicMemberLookup
public final class LockIsolated<Value>: @unchecked Sendable {
  private var _value: Value
  private let lock = NSRecursiveLock()

  /// Initializes lock-isolated state around a value.
  ///
  /// - Parameter value: A value to isolate with a lock.
  public init(_ value: @autoclosure @Sendable () throws -> Value) rethrows {
    self._value = try value()
  }

  public subscript<Subject: Sendable>(dynamicMember keyPath: KeyPath<Value, Subject>) -> Subject {
    self.lock.sync {
      self._value[keyPath: keyPath]
    }
  }

  /// Perform an operation with isolated access to the underlying value.
  ///
  /// Useful for modifying a value in a single transaction.
  ///
  /// ```swift
  /// // Isolate an integer for concurrent read/write access:
  /// var count = LockIsolated(0)
  ///
  /// func increment() {
  ///   // Safely increment it:
  ///   self.count.withValue { $0 += 1 }
  /// }
  /// ```
  ///
  /// - Parameter operation: An operation to be performed on the the underlying value with a lock.
  /// - Returns: The result of the operation.
  public func withValue<T: Sendable>(
    _ operation: @Sendable (inout Value) throws -> T
  ) rethrows -> T {
    try self.lock.sync {
      var value = self._value
      defer { self._value = value }
      return try operation(&value)
    }
  }

  /// Overwrite the isolated value with a new value.
  ///
  /// ```swift
  /// // Isolate an integer for concurrent read/write access:
  /// var count = LockIsolated(0)
  ///
  /// func reset() {
  ///   // Reset it:
  ///   self.count.setValue(0)
  /// }
  /// ```
  ///
  /// > Tip: Use ``withValue(_:)`` instead of ``setValue(_:)`` if the value being set is derived
  /// > from the current value. That is, do this:
  /// >
  /// > ```swift
  /// > self.count.withValue { $0 += 1 }
  /// > ```
  /// >
  /// > ...and not this:
  /// >
  /// > ```swift
  /// > self.count.setValue(self.count + 1)
  /// > ```
  /// >
  /// > ``withValue(_:)`` isolates the entire transaction and avoids data races between reading and
  /// > writing the value.
  ///
  /// - Parameter newValue: The value to replace the current isolated value with.
  public func setValue(_ newValue: @autoclosure @Sendable () throws -> Value) rethrows {
    try self.lock.sync {
      self._value = try newValue()
    }
  }
}

extension LockIsolated where Value: Sendable {
  /// The lock-isolated value.
  public var value: Value {
    self.lock.sync {
      self._value
    }
  }
}

extension NSRecursiveLock {
  @inlinable @discardableResult
  @_spi(Internals) public func sync<R>(work: () throws -> R) rethrows -> R {
    self.lock()
    defer { self.unlock() }
    return try work()
  }
}
