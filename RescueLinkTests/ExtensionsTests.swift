//
//  ExtensionsTests.swift
//   ArmoreTests
//
//  Created by Dario Talarico on 1/29/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import XCTest
@testable import Armore

class ExtensionsTests: XCTestCase {

    func testDataFormatterWorks() {
        let date = "2020-01-29T17:50:03.279Z"
        XCTAssertEqual(Date(timeIntervalSince1970: 1580320203.279), Date.parseDate(date))
    }
}
