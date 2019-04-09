// Copyright (c) 2019 David Stump <david@davidstump.net>
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


/// Data that is received from the Server.
public class Message {
    
    /// Reference number. Empty if missing
    public let ref: String
    
    /// Join Reference number
    internal let joinRef: String?
    
    /// Message topic
    public let topic: String
    
    /// Message event
    public let event: String
    
    /// Message payload
    public var payload: Payload
    
    /// Convenience accessor. Equivalent to getting the status as such:
    /// ```swift
    /// message.payload["status"]
    /// ```
    public var status: String? {
        return payload["status"] as? String
    }

    init(ref: String = "",
         topic: String = "",
         event: String = "",
         payload: Payload = [:],
         joinRef: String? = nil) {
        self.ref = ref
        self.topic = topic
        self.event = event
        self.payload = payload
        self.joinRef = joinRef
    }
    
    init?(json: [String: Any]) {
        self.ref = json["ref"] as? String ?? ""
        self.joinRef = json["join_ref"] as? String
        
        if
            let topic = json["topic"] as? String,
            let event = json["event"] as? String,
            let payload = json["payload"] as? Payload {
            
            self.topic = topic
            self.event = event
            self.payload = payload
        } else {
            return nil
        }
    }
}
