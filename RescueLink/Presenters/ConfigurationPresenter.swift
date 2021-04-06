//
//  ConfigurationPresenter.swift
//   Armore
//
//  Created by Security Union on 13/11/19.
//  Copyright © 2019 Security Union. All rights reserved.
//

import Foundation
import Alamofire

class ConfigurationPresenter: CurrentUser {

    private let urls: URLs // Date provider
    weak private var configurationViewDelegate: ConfigurationController?
    let req = Request()
    let isBusy = UIState.instance.isPictureLoading

    init(urls: URLs) {
        self.urls = urls
    }

    func setViewDelegate(configurationController: ConfigurationController) {
        self.configurationViewDelegate = configurationController
    }

    func logout() {

        // 1. Call delete device service
        guard (CurrentUser().getUserInfo()?.username) != nil else {
            UIState.instance.jwtExpired()
            return
        }
        let deviceId = readDeviceUUIDFromKeychain()
        req.request(url: "\(urls.deleteDevice(device: deviceId))",
                headers: addBaseHeaders([]),
                parameters: nil, methodType: .delete) { (success, response, _) in
            // 2. If successful then logout.
            if success {
                UIState.instance.jwtExpired()
            } else {
                // 3. If 1. fails then show the error.
                let message = response["message"]! as? String ?? ""
                self.configurationViewDelegate?.showMessage(title: "Logout error", message: message)
            }
        }
    }

    func updateImageProfile(_ image: UIImage, completion: @escaping (ApiResponse<UpdateProfileResponse>) -> Void) {
        UIState.instance.updateImageProfile(image, completion: completion)
    }

    func getUsername() -> String? {
        getUserInfo()?.username
    }

}
