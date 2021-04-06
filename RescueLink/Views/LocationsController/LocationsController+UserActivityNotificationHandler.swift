//
//  LocationsControllerAndUserActivity.swift
//  RescueLink
//
//  Created by Dario Lencina on 4/3/21.
//  Copyright © 2021 Security Union. All rights reserved.
//

import Foundation
import UIKit
import MaterialComponents

extension LocationsController {
    func handleUserActivityNotification(notification: Notification) {
        if let object = notification.object {
            switch object {
            case let invitation as InvitationIntent:
                self.locationsPresenter.getInvitationDetails(invitation.invitationId) { invitationDetails in
                    if let error = invitationDetails.getMessage(), !invitationDetails.success {
                        self.showErrorAndRetryIfNeeded(error, notification: notification)
                        return
                    }
                    let firstName = invitationDetails.result?.firstName ?? ""
                    let alert = MDCAlertController(
                        title: String(format: NSLocalizedString("accept_invitation_title", comment: ""), firstName),
                            message: String(format: NSLocalizedString("accept_invitation", comment: ""), firstName)
                    )
                    alert.addAction(MDCAlertAction(
                        title: NSLocalizedString("Reject", comment: ""), emphasis: .high) { _ in
                        self.locationsPresenter.rejectInvitation(invitation.invitationId) {[weak self] response in
                            if let error = response.getMessage(), !response.success {
                                self?.showErrorAndRetryIfNeeded(error, notification: notification)
                            }
                        }
                    })
                    alert.addAction(MDCAlertAction(
                        title: NSLocalizedString("Accept", comment: ""), emphasis: .medium) { _ in
                        self.locationsPresenter.acceptInvitation(invitation.invitationId) {[weak self] response in
                            if let error = response.getMessage(), !response.success {
                                self?.showErrorAndRetryIfNeeded(error, notification: notification)
                            } else {
                                if let publicKey = response.result?.publicKey {
                                    if let username = response.result?.username {
                                        _ = Crypto.saveUsersPublicKey(publicKey, for: username)
                                    }
                                }
                                LocationPusher.instance.forcePushLocation()
                            }
                        }
                    })
                    alert.mdc_dialogPresentationController?.dismissOnBackgroundTap = false
                    self.present(alert, animated: true)
                }
            default:
                break
            }
        }
    }
}
