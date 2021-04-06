//
//  ReceivedInvitationsPresenter.swift
//  RescueLink
//
//  Created by Jos L Rod on 14/11/19.
//  Copyright © 2019 Jos L Rod. All rights reserved.
//

import Foundation
import Alamofire

class ReceivedInvitationsPresenter: CurrentUser {

    private let urls: URLs // Date provider
    weak private var receivedInvitationsViewDelegate: ReceivedInvitationsController?
    let req = Request()

    init(urls: URLs) {
        self.urls = urls
    }

    func setViewDelegate(receivedInvitationsController: ReceivedInvitationsController) {
        self.receivedInvitationsViewDelegate = receivedInvitationsController
        req.setViewDelegate(viewDelegate: receivedInvitationsController)
    }

    func getReceivedInvitations() {
        let requestParameters = [String: Any]()
        let requestHeaders: HTTPHeaders = [TOKEN_HEADER: getToken()]

        req.request(url: urls.invitations(),
                headers: requestHeaders,
                parameters: requestParameters,
                methodType: .get) { (success, response) in
            if success {
                let received = response["received"] as? [[String: Any]] ?? [[String: Any]]()

                let invitationList: [Invitation] = received.map { rawInvitation in
                    var invAux = Invitation()
                    invAux.userCreator = invAux.getCreatorInfo(response: rawInvitation)
                    invAux.targetEmail = rawInvitation["targetEmail"] as? String ?? ""
                    invAux.status = rawInvitation["status"] as? String ?? ""
                    invAux.type = rawInvitation["type"] as? String ?? ""
                    invAux.creationTimestamp = rawInvitation["creationTimestamp"] as? String ?? ""
                    invAux.updateTimestamp = rawInvitation["updateTimestamp"] as? String ?? ""
                    invAux.id = rawInvitation["id"] as? String ?? ""

                    // get invitation access from invitation
                    let invitationAccess = rawInvitation["invitation"] as? [String: Any] ?? [String: Any]()
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
                    invAux.sent = false

                    // get the image of the user
                    if let img = self.getImage(withName: invAux.userCreator.username) {
                        // image exists
                        invAux.userCreator.profileImage = img
                    } else {
                        // download image
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
                    return invAux
                }

                self.receivedInvitationsViewDelegate!.displayInvitations(invitationList: invitationList)
            } else {
                print("Error while getting received invitations")

                if response["statusCode"] != nil {
                    print("Authentication error, return to login")
                    let navigationController =
                            self.receivedInvitationsViewDelegate?.presentingViewController as? UINavigationController

                    self.receivedInvitationsViewDelegate!.dismiss(animated: true) {
                        _ = navigationController?.popToRootViewController(animated: true)
                    }
                }
            }
        }
    }

}
