//
//   ArmoreUITests.swift
//   ArmoreUITests
//
//  Created by Dario Talarico on 1/2/20.
//  Copyright © 2020 Security Union. All rights reserved.
//
// swiftlint:disable force_try

import XCTest
import Swifter

class LoginTests: XCTestCase {

    var server: HttpServer?

    override func setUp() {
        continueAfterFailure = false
        CurrentUser().logoutUser()
        server = HttpServer()
    }

    override func tearDown() {
        server?.stop()
    }

    func testLoginSuccess() {
        // 1. Setup Server
        let userExists = try! Utils.loadFixture(fileName: "UserExists", type: "json")
        server?["/user/exists/phone/+12342434232"] = { _ in
            HttpResponse.ok(.json(userExists))
        }
        
        server?["/login"] = { _ in
            HttpResponse.ok(.json(userExists))
        }
        
        server?["/user/verify/+12342434232"] = { _ in
            HttpResponse.ok(.json(userExists))
        }

        try! server?.start(20000, forceIPv4: true, priority: .userInitiated)

        // 2. Launch App
        let app = XCUIApplication()
        app.launchArguments = ["UITests"]
        app.launch()

        // 3. Type phone number and send it.
        let username = app.textFields["Phone Number"]
        let codeVerification = app.textFields["Verification code"]
        username.tap()
        username.typeText("2342434232")
        app.buttons["CONTINUE"].tap()

        // 4. Enter verification code
        codeVerification.waitForExistence(timeout: 30)
        codeVerification.tap()
        codeVerification.typeText("123")
        app.buttons["CONTINUE"].tap()
        
        // 5. Wait for the map to become visible
        app.staticTexts["Friends"].waitForExistence(timeout: 10)
        app.staticTexts["Friends"].tap()
    }

    func testLoginInvalidCredentials() {
        // 1. Setup server
        server?["/user/exists/phone/+12342434232"] = { _ in
            HttpResponse.ok(.json(["success": false, "result": ["message": "Life is hard"]]))
        }

        try! server?.start(20000, forceIPv4: true, priority: .userInitiated)

        // 2. Launch App
        let app = XCUIApplication()
        app.launchArguments = ["UITests"]
        app.launch()

        // 3. Type email and wait for error
        let username = app.textFields["Phone Number"]
        let lifeIsHardQuery = app.staticTexts.matching(identifier: "Life is hard")
        username.tap()
        username.typeText("2342434232")
        app.buttons["CONTINUE"].tap()
        lifeIsHardQuery.firstMatch.waitForExistence(timeout: 3)
        lifeIsHardQuery.firstMatch.tap()
        app.buttons.matching(identifier: "Ok").firstMatch.tap()
    }
}
