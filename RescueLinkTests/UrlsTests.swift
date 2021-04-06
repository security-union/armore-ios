//
//  UrlsTests.swift
//  ArmoreTests
//
//  Created by Dario Lencina on 8/25/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation

import XCTest
@testable import Armore

class URLTests: XCTestCase {

    let urls = URLs()
    
    func testDelete() {
        XCTAssertEqual("http://localhost:20000/me/connections/followers/dario",
                       urls.removeFriend(username: "dario"))
    }
    
    func testDeleteWithAccent() {
        XCTAssertEqual("http://localhost:20000/me/connections/followers/Jos%C3%A9%20Luis",
                       urls.removeFriend(username: "José Luis"))
    }
    
    func testVerifyUser() {
        XCTAssertEqual("http://localhost:20000/user/exists/email/edsfgsdfgsdfgh@me.com",
       urls.userExists(email: "edsfgsdfgsdfgh@me.com", authMethod: .email))
    }
    
    func testCodeVerification() {
        XCTAssertEqual("http://localhost:20000/user/verify/123",
        urls.codeVerification(email: "123"))
    }
}
