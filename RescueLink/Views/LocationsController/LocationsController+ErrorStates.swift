//
//  LocationsController+ErrorStates.swift
//  RescueLink
//
//  Created by Dario Lencina on 4/3/21.
//  Copyright © 2021 Security Union. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import MaterialComponents

extension LocationsController {
    
func showGPSErrorIfNeeded() {
    if let appDelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate,
       let window = UIApplication.shared.windows.first, appDelegate.gpsErrorController != nil {
        let errorFrame = CGRect.init(
            x: 0,
            y: noLocationErrorTop,
            width: Int(window.frame.width),
            height: noLocationErrorHeight)
        appDelegate.gpsErrorController!.view.frame = errorFrame
        window.addSubview(appDelegate.gpsErrorController!.view)
        window.bringSubviewToFront(appDelegate.gpsErrorController!.view)
    }
}
    
func showErrorAndRetryIfNeeded(_ error: String, notification: Notification) {
    let send_error = MDCAlertController(
            title: "Error",
            message: error
    )
    send_error.addAction(
        MDCAlertAction(title:
                        NSLocalizedString("Cancel", comment: "")))
    send_error.addAction(
        MDCAlertAction(title:
                        NSLocalizedString("Retry", comment: "")) { _ in
        self.handleUserActivityNotification(notification: notification)
    })
    self.present(send_error, animated: true)
}
    
func showError(title: String, message: String) {
    let alert = UIAlertController(title: title, message: message)
    alert.simpleOkAction { _ in
        self.locationsPresenter.clearError()
    }
    alert.display()
}

}
