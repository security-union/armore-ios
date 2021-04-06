//
//  Invitation.swift
//   Armore
//
//  Created by Security Union on 10/02/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation
import UIKit

struct InvitationRequest: Encodable, Decodable {
    let expirationDate: String
}

struct InvitationResponse: WithMessage {
    let message: String?
    let engineeringError: String?
    let link: String?

    func getMessage() -> String? {
        message
    }

    func getEngineeringError() -> String? {
        engineeringError
    }
}
