//
//  MyDevicePresenter.swift
//   Armore
//
//  Created by Security Union on 16/11/19.
//  Copyright © 2019 Security Union. All rights reserved.
//

import Foundation
import Alamofire

class MyDevicePresenter: CurrentUser {

    private let urls: URLs // Date provider
    weak private var myDeviceViewDelegate: MyDeviceController?
    let req = Request()
    private var activity: CoolActivityIndicator?

    init(urls: URLs) {
        self.urls = urls
    }

    func setViewDelegate(myDeviceController: MyDeviceController) {
        self.activity = CoolActivityIndicator(currentController: myDeviceController)
        self.myDeviceViewDelegate = myDeviceController
    }
}
