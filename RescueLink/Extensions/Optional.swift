//
//  Optional.swift
//  RescueLink
//
//  Created by Dario Lencina on 7/17/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation

extension Optional {
    func or(_ defaultValue: Wrapped) -> Wrapped {
        switch self {
        case .none:
            return defaultValue
        case .some(let value):
            return value
        }
    }
}
