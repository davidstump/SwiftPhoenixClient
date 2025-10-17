//
//  SocketOptions.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 10/9/25.
//  Copyright © 2025 SwiftPhoenixClient. All rights reserved.
//

import Foundation


/// Options for initializing a ``Socket``.
public struct SocketOptions: Sendable {
    
    /// The ``WebSocket`` ``TransportV2``. Defaults to ``URLSessionWebsocketTransport``
    public var transport: TransportV2
    
    /// When true, enables debug logging. Default false.
    public var debug: Bool
    
    /// The ``TransportSerializer`` used to translate messages between the
    /// Phoenix server and the client.
    public var serializer: TransportSerializer
    
    /// The timeout to trigger push timeouts.
    public var timeout: TimeInterval
    
    /// The interval between sending a heartbeat
    public var heartbeatInterval: TimeInterval
    
    /// The optional function that returns the socket reconnect interval, in
    /// seconds. Defaults to a ``SteppedBackoff`` of
    ///
    ///     [0.01, 0.05, 0.1, 0.15, 0.2, 0.25, 0.5, 1.0, 2.0][tries - 1]
    public var reconnectAfter: SteppedBackoff
    
    /// The optional function that returns the rejoin TimeInterval for
    /// individual channels. Defaults to a ``SteppedBackoff`` of
    ///
    ///     [1, 2, 5][tries - 1]
    public var rejoinAfter: SteppedBackoff
    
    // TODO: Logger
    
    /// The optional params to pass when connecting
    public var params: (@Sendable () -> [String: String])?
    
    /// Custom headers to be added to the socket connection request
    public var headers: [String : String]
    
    /// The optional authentication token to be exposed on the server
    /// under the `:auth_token` connect_info key.
    public var authToken: String? = nil
    
    /// The serializer's protocol version to send on connect.
    public var vsn: String
    
    /// Disables heartbeats from being sent. Default is false.
    public var skipHeartbeat: Bool
    
    
    public init(
        transport: TransportV2 = URLSessionWebsocketTransport(),
        debug: Bool = false,
        encoder: PayloadEncoder = PhoenixPayloadEncoder(),
        decoder: PayloadDecoder = PhoenixPayloadDecoder(),
        timeout: TimeInterval = Self.Defaults.timeoutInterval,
        heartbeatInterval: TimeInterval = Self.Defaults.heartbeatInterval,
        reconnectAfter: @escaping SteppedBackoff = Self.Defaults.reconnectAfter,
        rejoinAfter: @escaping SteppedBackoff = Self.Defaults.rejoinAfter,
        params: [String: String]? = nil,
        headers: [String: String] = [:],
        authToken: String? = nil,
        vsn: String = Self.Defaults.vsn,
        skipHeartbeat: Bool = false
         
    ) {
        let paramsClosure: (@Sendable () -> [String: String])? = if let params {
            { params }
        } else {
            nil
        }
        
        self.init(
            transport: transport,
            debug: debug,
            encoder: encoder,
            decoder: decoder,
            timeout: timeout,
            heartbeatInterval: heartbeatInterval,
            reconnectAfter: reconnectAfter,
            rejoinAfter: rejoinAfter,
            params: paramsClosure,
            authToken: authToken,
            vsn: vsn,
            skipHeartbeat: skipHeartbeat
        )
    }
    
    public init(
        transport: TransportV2 = URLSessionWebsocketTransport(),
        debug: Bool = false,
        encoder: PayloadEncoder = PhoenixPayloadEncoder(),
        decoder: PayloadDecoder = PhoenixPayloadDecoder(),
        timeout: TimeInterval = Self.Defaults.timeoutInterval,
        heartbeatInterval: TimeInterval = Self.Defaults.heartbeatInterval,
        reconnectAfter: @escaping SteppedBackoff = Self.Defaults.reconnectAfter,
        rejoinAfter: @escaping SteppedBackoff = Self.Defaults.rejoinAfter,
        params:  (@Sendable () -> [String: String])?,
        headers: [String: String] = [:],
        authToken: String? = nil,
        vsn: String = Self.Defaults.vsn,
        skipHeartbeat: Bool = false
    ) {
        self.transport = transport
        self.debug = debug
        self.serializer = PhoenixTransportSerializer(
            payloadEncoder: encoder,
            payloadDecoder: decoder
        )
        self.timeout = timeout
        self.heartbeatInterval = heartbeatInterval
        self.reconnectAfter = reconnectAfter
        self.rejoinAfter = rejoinAfter
        self.params = params
        self.headers = headers
        self.vsn = vsn
        self.skipHeartbeat = skipHeartbeat
    }
    
    
    // MARK: ----- Defaults
    public class Defaults {
        
        /// The default timeout to trigger push timeouts.
        public static let timeoutInterval: TimeInterval = 10.0
        
        /// Default interval to send heartbeats on
        public static let heartbeatInterval: TimeInterval = 30.0
        
        /// Default reconnect algorithm for the socket
        public static let reconnectAfter: SteppedBackoff = { tries in
            guard tries > 0 else { return 0.01 }
            guard tries < 10 else { return 5.0 }
            return [0.01, 0.05, 0.1, 0.15, 0.2, 0.25, 0.5, 1.0, 2.0][tries - 1]
        }
        
        /// Default rejoin algorithm for individual channels
        public static let rejoinAfter: SteppedBackoff = { tries in
            guard tries > 0 else  { return 1 }
            guard tries < 4 else { return 10 }
            return [1, 2, 5][tries - 1]
        }
        
        /// Default serializer version
        public static let vsn = "2.0.0"
        
    }
}

extension SocketOptions {
    public static let `default` = SocketOptions()
}
