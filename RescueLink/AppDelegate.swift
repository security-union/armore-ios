//
//  AppDelegate.swift
//   Armore
//
//  Created by Security Union on 03/11/19.
//  Copyright © 2019 Security Union. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift
import CoreLocation
import UserNotifications
import Firebase
import FirebaseAnalytics
import FBSDKCoreKit

let BFSessionShouldShowGPSDisabled = "BFSessionShouldShowGPSDisabled"
let BFSessionShouldShowGPSEnabled = "BFSessionShouldShowGPSEnabled"
let noLocationErrorHeight = 220
let noLocationErrorTop = 86

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var gpsErrorController: UIViewController?
    let notificationsProvider = NotificationsPresenter(urls: URLs())

    func addNotifications() {
        NotificationCenter.default.addObserver(self,
                selector: #selector(self.showGPSDisabledError),
                name: NSNotification.Name(rawValue: BFSessionShouldShowGPSDisabled),
                object: nil)
        NotificationCenter.default.addObserver(self,
                selector: #selector(self.dismissGPSDisabledError),
                name: NSNotification.Name(rawValue: BFSessionShouldShowGPSEnabled),
                object: nil)
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        IQKeyboardManager.shared.enable = true
        addNotifications()
        LocationPusher.instance.startTracking()
        LocationPusher.instance.forcePushLocation()
        UIApplication.shared.setMinimumBackgroundFetchInterval(BACKGROUND_REFRESH_INTERVAL_SECS)
        UNUserNotificationCenter.current().delegate = self
        FirebaseApp.configure()
        UIState.instance.updateDeviceSettings()
        if let url = launchOptions?[.url] as? URL {
            if let notification = UserActivityParser.notificationFromUrl(url: url) {
                UIState.instance.setNotification(notification)
            }
        }
        AppLinkUtility.fetchDeferredAppLink { (url, _) in
            if let url = url {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        Settings.setAdvertiserTrackingEnabled(false)
        return ApplicationDelegate.shared.application(
                application,
                didFinishLaunchingWithOptions: launchOptions
        ) || true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        LocationPusher.instance.startTracking()
    }

    func application(_ application: UIApplication,
                     performFetchWithCompletionHandler
                     completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if CurrentUser().isSessionActive() {
            LocationPusher.instance.verifyThatWeStillHavePermissions()
            UIState.instance.updateDeviceSettings()
            LocationPusher.instance.forcePushLocation(completionHandler)
        }
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError
                     error: Error) {
        print(error)
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        notificationsProvider.sendPushNotificationsToken(token: deviceToken)
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if CurrentUser().isSessionActive() {
            LocationPusher.instance.forcePushLocation(completionHandler)
            LocationPusher.instance.verifyThatWeStillHavePermissions()
        }
    }

    func application(
            _ application: UIApplication,
            continue userActivity: NSUserActivity,
            restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if let notification = UserActivityParser.notificationFromUrl(url: userActivity.webpageURL) {
            UIState.instance.setNotification(notification)
            return true
        } else {
            return true
        }
    }

    // MARK: UISceneSession Lifecycle

    @available(iOS 13.0, *)
    func application(_ application: UIApplication,
                     configurationForConnecting
                     connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return (ApplicationDelegate.shared.application(
                app,
                open: url,
                sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )) || true
    }

    @objc func dismissGPSDisabledError(notification: Notification) {
        if self.gpsErrorController != nil {
            self.gpsErrorController?.view.removeFromSuperview()
            self.gpsErrorController = nil
        }
    }

    @objc func showGPSDisabledError(notification: Notification) {
        if self.gpsErrorController != nil {
            return
        }

        self.gpsErrorController = BFGPSIsDisabledViewController(nibName: "GPSIsDisabledViewController",
                bundle: Bundle.main)

        if let window = UIApplication.shared.windows.first {
            let errorFrame = CGRect.init(
                x: 0,
                y: noLocationErrorTop,
                width: Int(window.frame.width),
                height: noLocationErrorHeight)
            self.gpsErrorController!.view.frame = errorFrame
            window.addSubview(self.gpsErrorController!.view)
            window.bringSubviewToFront(self.gpsErrorController!.view)
        }
    }

}

// Conform to UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            willPresent notification: UNNotification,
            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(.alert)
    }

}
