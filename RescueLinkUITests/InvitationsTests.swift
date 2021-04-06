//
//  InvitationsTests.swift
//   ArmoreUITests
//
//  Created by Dario Talarico on 2/3/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation

//
//  LocationTests.swift
//   ArmoreUITests
//
//  Created by Dario Talarico on 1/31/20.
//  Copyright © 2020 Security Union. All rights reserved.
//
// swiftlint:disable force_try

import XCTest
import Swifter

class InvitationsTests: XCTestCase {

    var server: HttpServer?

    override func setUp() {
        continueAfterFailure = false
        CurrentUser().logoutUser()
        server = HttpServer()
    }

    override func tearDown() {
        server?.stop()
    }
    
    func testCreateInvitation() {
        let userExists = try! Utils.loadFixture(fileName: "UserExists", type: "json")
        let invitationResponse = try! Utils.loadFixture(fileName: "CreateInvitationResponse", type: "json")

        server?["/user/exists/phone/+12342434232"] = { _ in
            HttpResponse.ok(.json(userExists))
        }
        
        server?["/login"] = { _ in
            HttpResponse.ok(.json(userExists))
        }
        
        server?["/user/verify/+12342434232"] = { _ in
            HttpResponse.ok(.json(userExists))
        }
        
        server?["/invitations/edfsdfsdf/accept"] = { _ in
            HttpResponse.ok(.json(userExists))
        }
        
        server?["/invitations"] = { _ in
            HttpResponse.ok(.json(invitationResponse))
        }
        
        try! server?.start(20000, forceIPv4: true, priority: .userInitiated)
        
        let app = XCUIApplication()
        app.launchArguments = ["UITests"]
        app.launch()

        let username = app.textFields["Phone Number"]
        let codeVerification = app.textFields["Verification code"]

        username.tap()
        username.typeText("2342434232")

        app.buttons["CONTINUE"].tap()

        codeVerification.waitForExistence(timeout: 30)
        codeVerification.tap()
        codeVerification.typeText("123")
        app.buttons["CONTINUE"].tap()
        app.staticTexts["Friends"].waitForExistence(timeout: 10)
        app.staticTexts["Friends"].tap()
        app.buttons["person add"].tap()
        let elementsQuery = app.sheets.scrollViews.otherElements
        app.buttons["30 Days"].tap()
        elementsQuery.buttons["30 Days"].tap()
        app.buttons["INVITE"].tap()
        app.buttons["Copy"].tap()
        app.buttons["Done"].tap()
        app.staticTexts["Friends"].tap()
    }

    func testAcceptInvitation() {
        let userExists = try! Utils.loadFixture(fileName: "UserExists", type: "json")
        let invitationDetails = try! Utils.loadFixture(fileName: "GetInvitationDetails", type: "json")

        server?["/user/exists/phone/+12342434232"] = { _ in
            HttpResponse.ok(.json(userExists))
        }
        
        server?["/login"] = { _ in
            HttpResponse.ok(.json(userExists))
        }
        
        server?["/user/verify/+12342434232"] = { _ in
            HttpResponse.ok(.json(userExists))
        }
        
        server?["/invitations/edfsdfsdf/accept"] = { _ in
            HttpResponse.ok(.json(userExists))
        }
        
        server?["/invitations/edfsdfsdf"] = { _ in
            HttpResponse.ok(.json(invitationDetails))
        }

        try! server?.start(20000, forceIPv4: true, priority: .userInitiated)

        let app = XCUIApplication()
        app.launchArguments = ["UITests"]
        app.launch()

        let username = app.textFields["Phone Number"]
        let codeVerification = app.textFields["Verification code"]

        username.tap()
        username.typeText("2342434232")

        app.buttons["CONTINUE"].tap()

        codeVerification.waitForExistence(timeout: 30)
        codeVerification.tap()
        codeVerification.typeText("123")
        app.buttons["CONTINUE"].tap()
        
        app.staticTexts["Friends"].waitForExistence(timeout: 10)
        app.staticTexts["Friends"].tap()
        
        let message = Safari.launch()
        
        Safari.open(URLString: "https://armore.dev/invitations/edfsdfsdf", safari: message)
        
        app.buttons["Accept"].waitForExistence(timeout: 10)
        app.buttons["Accept"].tap()
        app.staticTexts["Friends"].waitForExistence(timeout: 10)
        app.staticTexts["Friends"].tap()
    }
    
    func testRejectInvitation() {
        let userExists = try! Utils.loadFixture(fileName: "UserExists", type: "json")
        let invitationDetails = try! Utils.loadFixture(fileName: "GetInvitationDetails", type: "json")

        server?["/user/exists/phone/+12342434232"] = { _ in
            HttpResponse.ok(.json(userExists))
        }
        
        server?["/login"] = { _ in
            HttpResponse.ok(.json(userExists))
        }
        
        server?["/user/verify/+12342434232"] = { _ in
            HttpResponse.ok(.json(userExists))
        }
        
        server?["/invitations/edfsdfsdf/reject"] = { _ in
            HttpResponse.ok(.json(userExists))
        }
        
        server?["/invitations/edfsdfsdf"] = { _ in
            HttpResponse.ok(.json(invitationDetails))
        }

        try! server?.start(20000, forceIPv4: true, priority: .userInitiated)

        let app = XCUIApplication()
        app.launchArguments = ["UITests"]
        app.launch()

        let username = app.textFields["Phone Number"]
        let codeVerification = app.textFields["Verification code"]

        username.tap()
        username.typeText("2342434232")

        app.buttons["CONTINUE"].tap()

        codeVerification.waitForExistence(timeout: 30)
        codeVerification.tap()
        codeVerification.typeText("123")
        app.buttons["CONTINUE"].tap()
        
        app.staticTexts["Friends"].waitForExistence(timeout: 10)
        app.staticTexts["Friends"].tap()
        
        let message = Safari.launch()
        
        Safari.open(URLString: "https://armore.dev/invitations/edfsdfsdf", safari: message)
        
        app.buttons["Reject"].waitForExistence(timeout: 10)
        app.buttons["Reject"].tap()
        app.staticTexts["Friends"].waitForExistence(timeout: 10)
        app.staticTexts["Friends"].tap()
    }
}
