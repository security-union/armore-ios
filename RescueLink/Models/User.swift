//
//  User.swift
//  Armore
//
//  Created by Security Union on 03/11/19.
//  Copyright © 2019 Security Union. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import Alamofire
import SwiftJWT

enum UserStatus {
    case Online
    case Offline
    case Limited
    case Unknown
}

func statusForUser(_ user: Friend?) -> UserStatus {
    if let userAccess = user?.accessType {
        if userAccess == .EmergencyOnly {
            return .Limited
        }
    }
    if let date = user?.date {
        switch date.timeIntervalSinceNow {
        case let t where t > -60 * 10:
            return .Online
        default:
            return .Offline
        }
    } else {
        return .Unknown
    }
}

func colorForStatus(_ status: UserStatus) -> UIColor {
    switch status {
    case .Online:
        return UIColor.brandedGreen()
    case .Limited:
        return UIColor.black
    default:
        return UIColor.brandedRed()
    }
}

struct Location: Codable {
    let lat: Double
    let lon: Double

    init(lat: Double, lon: Double) {
        self.lat = lat
        self.lon = lon
    }

    init(_ location: CLLocation) {
        self.lat = location.coordinate.latitude
        self.lon = location.coordinate.longitude
    }

    init(_ coordinates: CLLocationCoordinate2D) {
        self.lat = coordinates.latitude
        self.lon = coordinates.longitude
    }

    func coordinate() -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: self.lat, longitude: self.lon)
    }

    func clLocation() -> CLLocation {
        CLLocation(latitude: self.lat, longitude: self.lon)
    }

}

enum PerceptionState: String, Decodable, Encodable {
    case Normal
    case Emergency
}

enum AccessType: String, Decodable {
    case EmergencyOnly
    case Permanent
}

struct FollowersPerception: Decodable, Encodable {
    var perception: PerceptionState = .Normal
    var username: String

    init() {
        username = ""
    }

    init(perception: PerceptionState, username: String) {
        self.perception = perception
        self.username = username
    }
}

struct UserState: Decodable, Encodable {
    var selfPerceptionState: PerceptionState = .Normal
    var followersPerception: [FollowersPerception] = []

    func castStringToPerceptionState(str: String) -> PerceptionState {
        switch str {
        case "Normal":
            return .Normal
        case "Emergency":
            return .Emergency
        default:
            return .Normal
        }
    }
}

let profileImageFileName = "profileImage"

let dashes = "--"

struct User {

    var username = ""
    var state: UserState = UserState(selfPerceptionState: .Normal, followersPerception: [])
    var email = dashes
    var phone = dashes
    var firstName = ""
    var lastName = ""
    var pictureURL = "" // picture url
    var profileImage = UIImage()
    var name = ""
    var token = ""
    var devices = [Device]()

    static func equal(usr: User, usr2: User) -> Bool {
        usr.username == usr2.username &&
                usr.email == usr2.email &&
                usr.firstName == usr2.firstName &&
                usr.lastName == usr2.lastName &&
                usr.pictureURL == usr2.pictureURL &&
                usr.phone == usr2.phone
    }

    func completeName() -> String {
        return "\(self.firstName) \(self.lastName)"
    }

}

struct MyClaims2: Claims {
    let exp: Int
    let username: String
    let deviceId: String
}
