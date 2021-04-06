//
//  SentInvitationsPresenter.swift
//  RescueLink
//
//  Created by Jos L Rod on 14/11/19.
//  Copyright © 2019 Jos L Rod. All rights reserved.
//

import Foundation
import Alamofire

class SentInvitationsPreenter: CurrentUser {

    private let urls: URLs // Date provider
    weak private var sentInvitationsViewDelegate: SentInvitationsController?
    let req = Request()

    init(urls: URLs) {
        self.urls = urls
    }

    func setViewDelegate(sentInvitationsController: SentInvitationsController) {
        self.sentInvitationsViewDelegate = sentInvitationsController
        req.setViewDelegate(viewDelegate: sentInvitationsController)
    }

    func getSentInvitations() {
        let requestParameters = [String: Any]()
        let requestHeaders: HTTPHeaders = [TOKEN_HEADER: getToken()]

        req.request(url: urls.invitations(),
                headers: requestHeaders,
                parameters: requestParameters,
                methodType: .get) { (success, response) in

            if success {
                let sent = response["sent"] as? [[String: Any]] ?? [[String: Any]]()
                let invitationList: [Invitation] = sent.map { rawSentInvitation in
                    var invAux = Invitation()

                    invAux.userCreator = invAux.getCreatorInfo(response:
                    rawSentInvitation["creator"] as? [String: Any] ?? [String: Any]())
                    invAux.targetEmail = rawSentInvitation["targetEmail"] as? String ?? ""
                    invAux.status = rawSentInvitation["status"] as? String ?? ""
                    invAux.type = rawSentInvitation["type"] as? String ?? ""
                    invAux.creationTimestamp = rawSentInvitation["creationTimestamp"] as? String ?? ""
                    invAux.updateTimestamp = rawSentInvitation["updateTimestamp"] as? String ?? ""
                    invAux.id = rawSentInvitation["id"] as? String ?? ""

                    // get invitation access from invitation
                    let invitationAccess = rawSentInvitation["invitation"] as? [String: Any] ?? [String: Any]()
                    invAux.invitationAccess.deviceId = invitationAccess["deviceId"] as? String ?? ""

                    if let permanentAccess = invitationAccess["permanentAccess"] as? String {
                        invAux.invitationAccess.permanentAccess = permanentAccess != "0"
                    } else if let permanentAccess = invitationAccess["permanentAccess"] as? Bool {
                        invAux.invitationAccess.permanentAccess = permanentAccess
                    }

                    // get device from invitation access
                    let device = invitationAccess["device"] as? [String: Any] ?? [String: Any]()
                    invAux.invitationAccess.device.deviceId = device["deviceId"] as? String ?? ""
                    invAux.invitationAccess.device.role = device["role"] as? String ?? ""
                    invAux.invitationAccess.device.name = device["name"] as? String ?? ""
                    invAux.invitationAccess.device.os = device["os"] as? String ?? ""
                    invAux.invitationAccess.device.model = device["model"] as? String ?? ""
                    invAux.invitationAccess.device.osVersion = device["osVersion"] as? String ?? ""
                    invAux.sent = true

                    // get the image of the user
                    if let img = self.getImage(withName: invAux.userCreator.username) {
                        invAux.userCreator.profileImage = img
                    } else {
                        self.getImageWithId(imageId: invAux.userCreator.pictureURL,
                                userToken: self.getToken()) { (response) in
                            if response.success {
                                // got image
                                if let image = response.oneReturned as? UIImage {
                                    invAux.userCreator.profileImage = image
                                    self.saveUserImage(image: invAux.userCreator.profileImage,
                                            withName: invAux.userCreator.username)
                                }
                            }
                        }
                    }

                    // add the invitation to the list
                    return invAux
                }

                // send the list to display it
                self.sentInvitationsViewDelegate?.displayInvitations(invitationList: invitationList)
            } else {
                // error on request, show error to user
                let message = response["message"] as? String ?? ""
                self.sentInvitationsViewDelegate?.showMessage(title: "Request Error", message: message)
            }
        }
    }

}
