//
//  SceneDelegate.swift
//   Armore
//
//  Created by Security Union on 03/11/19.
//  Copyright © 2019 Security Union. All rights reserved.
//

import UIKit
import FBSDKCoreKit

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        if let notification = UserActivityParser.notificationFromUrl(url: userActivity.webpageURL) {
            UIState.instance.setNotification(notification)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else {
            return
        }

        ApplicationDelegate.shared.application(
                UIApplication.shared,
                open: url,
                sourceApplication: nil,
                annotation: [UIApplication.OpenURLOptionsKey.annotation]
        )

        URLContexts.forEach { body in
            if let notification = UserActivityParser.notificationFromUrl(url: body.url) {
                UIState.instance.setNotification(notification)
            }
        }
    }
}
