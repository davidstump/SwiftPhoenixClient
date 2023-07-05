import Foundation

/// Defines functions to decode text or data from a Server into client `Message` struct
/// and also to encode a client `Message` struct into text or data to send to a server.
public protocol Serializer {
    
    /// Encodes a `Message` from the client into a string to be sent to the server
    func encode(message: MessageV6) -> String
    
    /// Decodes text from a Phoenix server into a `Message`
    func decode(text: String) -> MessageV6
    
    /// Encodes a `Message` from the client into binary data to be sent to the server
    func binaryEncode(message: MessageV6) -> Data
    
    /// Decodes binary data from a Phoenix server into a `Message`
    func binaryDecode(data: Data) -> MessageV6
}


/// A default implementation of `Serializer` which provides encoding and decoding that
/// is compliant with v2 serialization of messages from a phoenix server.
///
/// A message from the server will always be in the format of
///
///     [join_ref, ref, topic, event, payload]
///
/// where `payload` may be the actual body or it may be the reply status and then
/// the actual body. `join_ref` and `ref` may be nil if the message is from a broadcast.
///
/// See https://github.com/phoenixframework/phoenix/blob/main/lib/phoenix/socket/serializers/v2_json_serializer.ex
/// for additional details.
class VSN2Serializer: Serializer {
    
    func encode(message: MessageV6) -> String {        
        let payload: [Any?] = [
            message.joinRef,
            message.ref,
            message.topic,
            message.event,
            message.textPayload!
        ]
        let jsonData = try! JSONSerialization
            .data(withJSONObject: payload,
                options: JSONSerialization.WritingOptions())
        let json = String(data: jsonData, encoding: .utf8)
        
        return json!
    }
    
    func decode(text: String) -> MessageV6 {
        fatalError("TODO")
    }
    
    func binaryEncode(message: MessageV6) -> Data {
        fatalError("TODO")
    }
    
    func binaryDecode(data: Data) -> MessageV6 {
        fatalError("TODO")
    }
    
    // MARK: - Private -
    private func decodePush(_ data: Data) -> MessageV6 {
        fatalError("TODO")
    }
    
    private func decodeReply(_ data: Data) -> MessageV6 {
        fatalError("TODO")
    }
    
    private func decodeBroadcast(_ data: Data) -> MessageV6 {
        fatalError("TODO")
    }
}
