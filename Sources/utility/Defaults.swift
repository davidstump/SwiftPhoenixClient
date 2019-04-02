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
class Defaults {
    
    /// Default timeout when sending messages
    static let timeoutInterval: TimeInterval = 10.0
    
    /// Default interval to send heartbeats on
    static let heartbeatInterval: TimeInterval = 30.0
    
    /// Default reconnect function
    static let steppedBackOff: (Int) -> TimeInterval = { tries in
        return tries > 4 ? 10 : [1, 2, 5, 10][tries - 1]
    }
    
    /// Default encode function, utilizing JSONSerialization.data
    static let encode: ([String: Any]) -> Data = { json in
        return try! JSONSerialization
            .data(withJSONObject: json,
                  options: JSONSerialization.WritingOptions())
    }
    
    /// Default decode function, utilizing JSONSerialization.jsonObject
    static let decode: (Data) -> [String: Any]? = { data in
        guard
            let json = try? JSONSerialization
                .jsonObject(with: data,
                            options: JSONSerialization.ReadingOptions())
                as? [String: Any]
            else { return nil }
        return json
    }
}
