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


/// A collection of default values and behaviors used accross the Client
public class Defaults {
    
    /// Default timeout when sending messages
    public static let timeoutInterval: TimeInterval = 10.0
    
    /// Default interval to send heartbeats on
    public static let heartbeatInterval: TimeInterval = 30.0
    
    /// Default reconnect function
    public static let steppedBackOff: (Int) -> TimeInterval = { tries in
        return tries > 4 ? 10 : [1, 2, 5, 10][tries - 1]
    }
    
    /// Default encode function, utilizing JSONSerialization.data
    public static let encode: ([String: Any]) -> Data = { json in
        return try! JSONSerialization
            .data(withJSONObject: json,
                  options: JSONSerialization.WritingOptions())
    }
    
    /// Default decode function, utilizing JSONSerialization.jsonObject
    public static let decode: (Data) -> [String: Any]? = { data in
        guard
            let json = try? JSONSerialization
                .jsonObject(with: data,
                            options: JSONSerialization.ReadingOptions())
                as? [String: Any]
            else { return nil }
        return json
    }
}


/// Represents the multiple states that a Channel can be in
/// throughout it's lifecycle.
public enum ChannelState: String {
    case closed = "closed"
    case errored = "errored"
    case joined = "joined"
    case joining = "joining"
    case leaving = "leaving"
}

/// Represents the different events that can be sent through
/// a channel regarding a Channel's lifecycle.
public struct ChannelEvent {
    public static let heartbeat = "heartbeat"
    public static let join      = "phx_join"
    public static let leave     = "phx_leave"
    public static let reply     = "phx_reply"
    public static let error     = "phx_error"
    public static let close     = "phx_close"
    
    static func isLifecyleEvent(_ event: String) -> Bool {
        switch event {
        case join, leave, reply, error, close: return true
        default: return false
        }
    }
}
