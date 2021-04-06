//
//  NotificationsPresenter.swift
//   Armore
//
//  Created by Dario Talarico on 1/15/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation
import Alamofire

class NotificationsPresenter: CurrentUser {

    private let urls: URLs
    private let req = Request()

    init(urls: URLs) {
        self.urls = urls
    }

    func sendPushNotificationsToken(token: Data) {
        let requestParameters = ["pushToken": self.stringFromDeviceToken(token: token)]
        req.request(url: urls.pushNotificationsRegister(),
                headers: [],
                parameters: requestParameters,
                methodType: .post) { (_, _, _) in
        }
    }

    func stringFromDeviceToken(token: Data) -> String {
        return token.map {
            String(format: "%.2hhx", $0)
        }.joined()
    }
}
