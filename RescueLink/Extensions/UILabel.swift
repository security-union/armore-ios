//
//  UILabel.swift
//  RescueLink
//
//  Created by Dario Lencina on 7/4/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import UIKit

extension UILabel {

    func swapFont(_ name: String) {
        self.font = UIFont(name: name, size: self.font.pointSize)
    }
}
