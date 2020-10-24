// Copyright (c) 2020 David Stump <david@davidstump.net>
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

@testable import SwiftPhoenixClient

class SocketSpy: Socket {
  
  private(set) var pushCalled: Bool?
  private(set) var pushCallCount: Int = 0
  private(set) var pushArgs: [Int: (topic: String, event: String, payload: Payload, ref: String?, joinRef: String?)] = [:]
  
  override func push(topic: String,
                     event: String,
                     payload: Payload,
                     ref: String? = nil,
                     joinRef: String? = nil) {
    self.pushCalled = true
    self.pushCallCount += 1
    self.pushArgs[pushCallCount] = (topic: topic, event: event, payload: payload, ref: ref, joinRef: joinRef)
    super.push(topic: topic,
               event: event,
               payload: payload,
               ref: ref,
               joinRef: joinRef)
  }

  
}
