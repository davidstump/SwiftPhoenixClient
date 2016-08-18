//
//  Phoenix.swift
//  SwiftPhoenixClient
//
//  Created by Nils Lattek on 13.05.16.
//  Copyright © 2016 Nils Lattek. All rights reserved.
//

import XCTest
@testable import SwiftPhoenixClient

class PhoenixChannel: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testOn() {
        let message = Phoenix.Message(subject: "join", body: "test")
        let socket = TestSocket()
        let channel = Phoenix.Channel(topic: "test", message: message, callback: { (_) in }, socket: socket)
        let asyncExpectation = expectationWithDescription("errorEvent")
        let eventMessage = Phoenix.Message(subject: "test_error", body: "something is wrong")
        channel.on("error") { (message) in
            XCTAssertEqual(message.subject, eventMessage.subject)
            XCTAssertEqual((message.body as! String), (eventMessage.body as! String))
            asyncExpectation.fulfill()
        }

        channel.trigger("error", msg: eventMessage)

        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
}
