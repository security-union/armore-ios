//
//  UIAlertController.swift
//  RescueLink
//
//  Created by Dario Talarico on 6/18/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import UIKit
import MaterialComponents

extension UIAlertController {

    convenience init(title: String, message: String) {
        self.init(title: title, message: message, preferredStyle: .alert)
    }

    private struct AssociatedKeys {
        static var window = "window"
    }

    private var alertWindow: UIWindow? {
        guard let window = objc_getAssociatedObject(self, &AssociatedKeys.window)
                as? UIWindow else {
            var alertWindow: UIWindow?
            if #available(iOS 13.0, *) {
                let windowScene = UIApplication.shared.connectedScenes.filter {
                    $0.activationState == .foregroundActive
                }
                        .first
                if let windowScene = windowScene as? UIWindowScene {
                    alertWindow = UIWindow(windowScene: windowScene)
                }
            } else {
                alertWindow = UIWindow(frame: UIScreen.main.bounds)
            }
            alertWindow?.rootViewController = UIViewController()
            alertWindow?.windowLevel = UIWindow.Level.alert + 1
            alertWindow?.makeKeyAndVisible()
            objc_setAssociatedObject(self, &AssociatedKeys.window,
                    alertWindow,
                    objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return alertWindow
        }
        return window
    }

    public func show(_ animated: Bool, completion: (() -> Void)? = nil) {
        self.alertWindow?.isHidden = false
        alertWindow?.windowLevel = UIWindow.Level.alert + 1
        alertWindow?.makeKeyAndVisible()
        self.alertWindow?.rootViewController?.present(self, animated: animated)
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.alertWindow?.isHidden = true
    }

    // function to add 'OK' action to alert
    public func simpleOkAction(handler: ((UIAlertAction) -> Void)? = nil) {
        self.addAction(UIAlertAction(title: "Ok", style: .default, handler: handler))
    }

    public func display() {
        show(true)
    }
}

extension MDCAlertController {

    private struct AssociatedKeys {
        static var window = "window"
    }

    private var alertWindow: UIWindow? {
        guard let window = objc_getAssociatedObject(self, &AssociatedKeys.window)
                as? UIWindow else {
            var alertWindow: UIWindow?
            if #available(iOS 13.0, *) {
                let windowScene = UIApplication.shared.connectedScenes.filter {
                    $0.activationState == .foregroundActive
                }
                        .first
                if let windowScene = windowScene as? UIWindowScene {
                    alertWindow = UIWindow(windowScene: windowScene)
                }
            } else {
                alertWindow = UIWindow(frame: UIScreen.main.bounds)
            }
            alertWindow?.rootViewController = UIViewController()
            alertWindow?.windowLevel = UIWindow.Level.alert + 1
            alertWindow?.makeKeyAndVisible()
            objc_setAssociatedObject(self, &AssociatedKeys.window,
                    alertWindow,
                    objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return alertWindow
        }
        return window
    }

    public func show(_ animated: Bool, completion: (() -> Void)? = nil) {
        self.alertWindow?.isHidden = false
        alertWindow?.windowLevel = UIWindow.Level.alert + 1
        alertWindow?.makeKeyAndVisible()
        self.alertWindow?.rootViewController?.present(self, animated: animated)
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.alertWindow?.isHidden = true
    }

    // function to add 'OK' action to alert
    public func simpleOkAction(handler: ((MDCAlertAction) -> Void)? = nil) {
        self.addAction(MDCAlertAction(title: "Ok", handler: handler))
    }

    public func display() {
        show(true)
    }
}
