//
//  Response.swift
//   Armore
//
//  Created by Security Union on 10/02/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation

public class Response {

    var response: [String: Any] = [:]
    var responseArray: [[String: Any]] = [[:]]
    var responseCode: Int = 200
    var errorMessage: String = ""
    var message: String = ""
    var success: Bool
    var oneReturned: Any = (Any).self
    var dataString: String = ""

    init(success: Bool, response: [String: Any], message: String, errorMessage: String, oneReturned: Any) {
        self.success = success
        self.response = response
        self.message = message
        self.errorMessage = errorMessage
        self.oneReturned = oneReturned
    }

    init(success: Bool, response: [String: Any]) {
        self.success = success
        self.response = response
    }

    init(success: Bool, responseArray: [[String: Any]]) {
        self.success = success
        self.responseArray = responseArray
    }

    init(success: Bool, errorMessage: String) {
        self.success = success
        self.errorMessage = errorMessage
    }

    init(success: Bool, errorMessage: String, responseCode: Int) {
        self.success = success
        self.errorMessage = errorMessage
        self.responseCode = responseCode
    }

    init(success: Bool, oneReturned: Any) {
        self.success = success
        self.oneReturned = oneReturned
    }

    init(success: Bool, dataString: String) {
        self.success = success
        self.dataString = dataString
    }

}
