//
//  Device.swift
//   Armore
//
//  Created by Security Union on 28/02/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation
import UIKit

struct Device {
    var location: Location?
    var guest = [User]()
    var timestamp = ""
    var deviceId = ""
    var osVersion = ""
    var role = ""
    var os = ""
    var model = ""
    var name = ""
    var owner = "" // when it's a guest device
    var ownerImage = UIImage()
    var permanentAccess = false

    init() {

    }

    init(deviceId: String) {
        self.deviceId = deviceId
    }

    init(deviceId: String, owner: String, location: Location) {
        self.deviceId = deviceId
        self.owner = owner
        self.location = location
    }

}

struct DeviceList {
    var mine = [Device]()
    var guest = [Device]()
}
