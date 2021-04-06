//
//  LocationPusherModelTests.swift
//  RescueLink
//
//  Created by Dario Lencina on 7/30/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation

import XCTest
@testable import Armore

class LocationPusherModelTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // swiftlint:disable force_try
    func testInvalidConnectionsResponse() {
        // Given an existing keypair, encrypt and decript fixture data.
        let loginResponse = try! Utils.loadData(fileName: "InvalidConnectionsResponse", type: "json")
        let apiResponse = try! JSONDecoder().decode(ApiResponse<Connections>.self, from: loginResponse)
        XCTAssertEqual(true, apiResponse != nil)
    }
    // swiftlint:enable force_try
}
