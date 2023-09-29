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


public struct NewPayload {
    
    public let status: String?
    public let body: PayloadBody
    
    init(status: String? = nil,
         body: PayloadBody) {
        self.status = status
        self.body = body
    }
}

public enum PayloadBody {
    case binary(Data)
    case text(String)
}


/// A message received from or dispatched to the server. See
/// https://github.com/phoenixframework/phoenix/blob/main/lib/phoenix/socket/message.ex for
/// additional details.
public class MessageV6 {
    
    /// The unique string ref when joining
    internal let joinRef: String?
    
    /// The unique string ref
    public let ref: String?
    
    /// The string topic or topic:subtopic pair namespace, for example "messages", "messages:123"
    public let topic: String
    
    /// The string event name, for example "phx_join"
    public let event: String
    
    /// The message payload. If it is a reply, then it will contain a non-nil `status`
    public let payload: NewPayload
    
    internal init(joinRef: String?,
                  ref: String,
                  topic: String,
                  event: String,
                  payload: PayloadBody) {
        self.joinRef = joinRef
        self.ref = ref
        self.topic = topic
        self.event = event
        self.payload = NewPayload(body: payload)
    }
    
    /// Convenience accessor, fetches the status from the payload.
    public var status: String? {
        return payload.status
    }
    
    /// Convenience accessor, fetches the payload as a text. Nil if message was not
    /// a text opcode.
    public var textPayload: String? {
        switch self.payload.body {
        case .text(let payload):
            return payload
        default:
            return nil
        }
    }
    
    /// Convenience accessor, fetches the payload as a text. Nil if message was not
    /// a binary opcode.
    public var binaryPayload: Data? {
        switch self.payload.body {
        case .binary(let payload):
            return payload
        default:
            return nil
        }
    }
    
    
}


