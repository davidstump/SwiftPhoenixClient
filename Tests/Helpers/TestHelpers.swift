// Copyright (c) 2021 David Stump <david@davidstump.net>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
@testable import SwiftPhoenixClient

enum TestError: Error {
  case stub
}

func toWebSocketText(data: [String: Any]) -> String {
  let encoded = Defaults.encode(data)
  return String(decoding: encoded, as: UTF8.self)
}


/// Transforms two Dictionaries into NSDictionaries so they can be conpared
func transform(_ lhs: [AnyHashable: Any],
               and rhs: [AnyHashable: Any]) -> (lhs: NSDictionary, rhs: NSDictionary) {
  return (NSDictionary(dictionary: lhs), NSDictionary(dictionary: rhs))
}


extension Channel {
  /// Utility method to easily filter the bindings for a channel by their event
  func getBindings(_ event: String) -> [Binding]? {
    return self.bindingsDel.filter({ $0.event == event })
  }
}
