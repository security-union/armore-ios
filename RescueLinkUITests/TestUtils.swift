//
//  Server.swift
//   ArmoreUITests
//
//  Created by Dario Talarico on 1/31/20.
//  Copyright © 2020 Security Union. All rights reserved.
//
// swiftlint:disable force_try

import Foundation

class Utils {
    static func loadFixture(fileName: String, type: String) throws -> [String: Any] {
        let file = Bundle(for: Utils.self).url(forResource: fileName, withExtension: type)!
        let data = try! Data(contentsOf: file, options: .uncachedRead)
        return String(decoding: data, as: UTF8.self).convertToDictionary()!
    }
    
    static func loadData(fileName: String, type: String) throws -> Data {
        let file = Bundle(for: Utils.self).url(forResource: fileName, withExtension: type)!
        return  try! Data(contentsOf: file, options: .uncachedRead)
    }
}
