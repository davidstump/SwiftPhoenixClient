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

///
/// Defines a message dispatched over client to channels and vice-versa.
///
/// The serialized format to and from the server will be in the shape of
///
///     [join_ref,ref,topic,event,payload]
///
/// Also provides a structure of a Reply from the server. The serialized format
/// to and from the server will be in the shape of
///
///     [join_ref,ref,topic,nil,%{"status": status, "response": payload}]
///
public struct Message {
        
    /// The unique string ref when joining
    let joinRef: String?
    
    /// The unique string ref
    let ref: String?
    
    /// The string topic or topic:subtopic pair namespace, for example
    /// "messages", "messages:123"
    let topic: String
    
    /// The string event name, for example "phx_join"
    let event: String
    
    /// The reply status as a string
    let status: String?
    
    /// The payload of the message to send or that was received.`
    public let payload: MessagePayload
    
    static func reply(
        joinRef: String?,
        ref: String?,
        topic: String,
        status: String,
        payload: MessagePayload
    ) -> Message {
        return Message(
            joinRef: joinRef,
            ref: ref,
            topic: topic,
            event: ChannelEvent.reply,
            status: status,
            payload: payload
        )
    }
    
    static func message(
        joinRef: String?,
        ref: String?,
        topic: String,
        event: String,
        payload: MessagePayload
    ) -> Message {
        return Message(
            joinRef: joinRef,
            ref: ref,
            topic: topic,
            event: event,
            status: nil,
            payload: payload
        )
    }
    
    static func broadcast(
        topic: String,
        event: String,
        payload: MessagePayload
    ) -> Message {
        return Message(
            joinRef: nil,
            ref: nil,
            topic: topic,
            event: event,
            status: nil,
            payload: payload
        )
    }
}
