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

class LocationTests: XCTestCase {

    var server: HttpServer?

    override func setUp() {
        continueAfterFailure = false
        CurrentUser().logoutUser()
        server = HttpServer()
    }

    override func tearDown() {
        server?.stop()
    }

    func testSendAndGetLocations() {
        let locationsResponse = try! Utils.loadFixture(fileName: "LocationsResponse", type: "json")
        let loginResponse = try! Utils.loadFixture(fileName: "LoginResponse", type: "json")
        let profileImage = try! Utils.loadData(fileName: "predator", type: "png")

        server?["/login"] = { _ in
            return HttpResponse.ok(.json(loginResponse))
        }

        server?["/location"] = { _ in
            return HttpResponse.ok(.json(locationsResponse))
        }

        server?["image/3aa1b809-1b6c-4aa9-a7d9-796f7284e22e"] = { _ in
            return HttpResponse.ok(.data(profileImage))
        }

        try! server?.start(20000, forceIPv4: true, priority: .userInitiated)

        let app = XCUIApplication()
        app.launchArguments = ["UITests"]
        app.launch()

        let username = app.textFields["username"]
        let passwordSecureTextField = app.secureTextFields["password"]

        username.tap()
        username.typeText("saddsdf")

        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("saddsdf")

        app.buttons["Sign in"].tap()

        let showPeople = app.buttons["Show People"]
        showPeople.waitForExistence(timeout: 10)
        showPeople.tap()
        app.collectionViews.containing(.cell, identifier: "zurcaleriam").element.waitForExistence(timeout: 10)
        app.collectionViews.containing(.cell, identifier: "zurcaleriam").element.tap()
    }
    
    func testSendInvitationFromLocations() {
        let locationsResponse = try! Utils.loadFixture(fileName: "LocationsResponse", type: "json")
        let loginResponse = try! Utils.loadFixture(fileName: "LoginResponse", type: "json")
        let profileImage = try! Utils.loadData(fileName: "predator", type: "png")
        let userDefaults = UserDefaults.standard

        server?["/login"] = { _ in
            return HttpResponse.ok(.json(loginResponse))
        }

        server?["/location"] = { _ in
            return HttpResponse.ok(.json(locationsResponse))
        }

        server?["image/3aa1b809-1b6c-4aa9-a7d9-796f7284e22e"] = { _ in
            return HttpResponse.ok(.data(profileImage))
        }

        try! server?.start(20000, forceIPv4: true, priority: .userInitiated)

        let app = XCUIApplication()
        app.launchArguments = ["UITests"]
        app.launch()

        let username = app.textFields["username"]
        let passwordSecureTextField = app.secureTextFields["password"]

        username.tap()
        username.typeText("saddsdf")

        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("saddsdf")

        app.buttons["Sign in"].tap()
        
        let exp = expectation(description: "Test after 5 seconds")
        let result = XCTWaiter.wait(for: [exp], timeout: 20.0)
        
        let userAnnotation = app.otherElements["My Location"]
        userAnnotation.waitForExistence(timeout: 10)
        userAnnotation.tap()
        
        print("App description: \(app.debugDescription)")
        
        let buttonInvitationRequest = app.buttons["Send Invitation"]
        buttonInvitationRequest.waitForExistence(timeout: 10)
        buttonInvitationRequest.tap()
        
        let alert = app.alerts["alertAskToSendInvitation"]
        alert.buttons["Yes, invite"]
        
    }
    
}
