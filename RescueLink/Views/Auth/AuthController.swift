//
//  AuthController.swift
//  RescueLink
//
//  Created by Dario Lencina on 8/6/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation
import UIKit
import MaterialComponents

class AuthController: BaseViewController {
    var keyGenerationController: PublicKeyCreationDialog = PublicKeyCreationDialog.getInstance()!
    let dialogController: MDCDialogTransitionController = MDCDialogTransitionController()
    var isShowingDialog = false

    func showProgressDialog() {
        DispatchQueue.main.async {
            if self.isVisible() && !self.isShowingDialog {
                self.isShowingDialog = true
                self.keyGenerationController.transitioningDelegate = self.dialogController
                self.present(self.keyGenerationController, animated: true)
            }
        }
    }

    func hideProgressDialog(completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            self.isShowingDialog = false
            self.presentedViewController?.dismiss(animated: true) {
                if let handler = completion {
                    handler()
                }
            }
        }
    }
}

extension UIViewController {
    func isVisible() -> Bool {
        return self.isViewLoaded && self.view.window != nil
    }
}
