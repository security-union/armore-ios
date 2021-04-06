//
//  iMessage.swift
//  RescueLink
//
//  Created by Dario Lencina on 12/4/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation
import XCTest

enum Safari {
    
    static func launch() -> XCUIApplication {
        // Open iMessage App
        let messageApp = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        // Launch iMessage app
        messageApp.launch()
        
        // Wait some seconds for launch
        XCTAssertTrue(messageApp.waitForExistence(timeout: 10))
        
        // Return application handle
        return messageApp
    }
    
    static func open(URLString urlString: String, safari: XCUIApplication) {
        XCTContext.runActivity(named: "Open URL \(urlString) in Safari") { _ in
            safari.buttons["URL"].tap()
            safari.typeText("\(urlString)\n")
            safari.webViews["WebView"].webViews.webViews.buttons["GO TO APP"].waitForExistence(timeout: 10)
            safari.webViews["WebView"].webViews.webViews.buttons["GO TO APP"].tap()
            safari.buttons.matching(identifier: "Open").firstMatch.tap()
        }
    }
}
