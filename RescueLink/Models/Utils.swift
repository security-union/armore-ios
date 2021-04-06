//
//  Utils.swift
//  RescueLink
//
//  Created by Dario Lencina on 11/14/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation
import UIKit

func goToAppSettings() {
    if let bundleId = Bundle.main.bundleIdentifier,
       let url = URL(string: "\(UIApplication.openSettingsURLString)&path=LOCATION/\(bundleId)") {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
