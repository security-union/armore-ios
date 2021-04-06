//
//  UIFont.swift
//  RescueLink
//
//  Created by Dario Lencina on 7/4/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import UIKit

extension UIFont {

    func swapFont(_ name: String) -> UIFont? {
        UIFont(name: name, size: self.pointSize)
    }
}
