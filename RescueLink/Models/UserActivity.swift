//
//  UserActivity.swift
//   Armore
//
//  Created by Dario Talarico on 1/29/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation

let OnVerificationCodeNotif = "Verification"
let OnInvitationNotif = "Invitation"

let notifications = [
    OnVerificationCodeNotif
]

protocol UserActivity {
    func notificationName() -> NSNotification.Name
}

struct Verification: UserActivity {
    func notificationName() -> NSNotification.Name {
        NSNotification.Name(rawValue: OnVerificationCodeNotif)
    }

    let code: String
}

struct InvitationIntent: UserActivity {
    func notificationName() -> NSNotification.Name {
        NSNotification.Name(rawValue: OnInvitationNotif)
    }

    let invitationId: String
}

class UserActivityParser {
    static func parseUrl(url: URL?) -> UserActivity? {
        url.flatMap { urlToParse in
            switch urlToParse {
            case _ where urlToParse.pathComponents.filter {
                $0.contains("verify")
            }.count > 0:
                return Verification(code: urlToParse.lastPathComponent)
            case _ where urlToParse.absoluteString.contains("invitations") && urlToParse.lastPathComponent.count > 3:
                return InvitationIntent(invitationId: urlToParse.lastPathComponent)
            default:
                return nil
            }
        }
    }

    static func notificationFromUrl(url: URL?) -> Notification? {
        parseUrl(url: url).flatMap {
            Notification(name: $0.notificationName(), object: $0, userInfo: nil)
        }
    }
}
