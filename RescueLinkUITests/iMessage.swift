//
//  iMessage.swift
//  RescueLink
//
//  Created by Dario Lencina on 12/4/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation
import XCTest

enum Message {
    
    static func launch() -> XCUIApplication {
        // Open iMessage App
        let messageApp = XCUIApplication(bundleIdentifier: "com.apple.MobileSMS")
        
        // Launch iMessage app
        messageApp.launch()
        
        // Wait some seconds for launch
        XCTAssertTrue(messageApp.waitForExistence(timeout: 10))
        
        // Continues "Whats new" if present
        let continueButton = messageApp.buttons["Continue"]
        if continueButton.exists {
            continueButton.tap()
        }
        
        // Removes New Messages Sheet on iOS 13
        let cancelButton = messageApp.navigationBars.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()
        }
        
        // Return application handle
        return messageApp
    }
    
    static func open(URLString urlString: String, inMessageApp app: XCUIApplication) {
        XCTContext.runActivity(named: "Open URL \(urlString) in iMessage") { _ in
            // Find Simulator Message
            let kateBell = app.cells.staticTexts["Kate Bell"]
            XCTAssertTrue(kateBell.waitForExistence(timeout: 10))
            kateBell.tap()

            // Tap message field
            app.textFields["iMessage"].tap()
                                                                            
            // Continues "Swipe to Text" Sheet
            let continueButton = app.buttons["Continue"]
            if continueButton.exists {
                continueButton.tap()
            }

            // Enter the URL string
            app.typeText("Open Link:\n")
            app.typeText(urlString)

            // Simulate sending link
            app.buttons["sendButton"].tap()

            // Wait for Main App to finish launching
            sleep(2)

            // The first link on the page
            let messageBubble = app.cells.links["com.apple.messages.URLBalloonProvider"]
            XCTAssertTrue(messageBubble.waitForExistence(timeout: 10))
            messageBubble.tap()
        }
    }
}
