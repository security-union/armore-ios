//
// Created by Dario Talarico on 2/27/20.
// Copyright (c) 2020 Security Union. All rights reserved.
//

import UIKit

public protocol WithMessage: Decodable {
    func getMessage() -> String?
    func getEngineeringError() -> String?
}

public struct ApiResponse<A: WithMessage>: Decodable {
    let success: Bool
    var httpCode: Int?
    let result: A?

    func getMessage() -> String? {
        result?.getMessage()
    }

    func getEngineeringError() -> String? {
        result?.getEngineeringError()
    }

    func getSuccess() -> Bool? {
        success
    }
}

enum AppState: String, CodingKey, Encodable {
    case Foreground
    case Background
}

enum ChargingState: String, CodingKey, Encodable, Decodable {
    case ChargingUsb
    case ChargingAc
    case NotCharging
}

func appleBatteryStateToCharingState(_ batteryState: UIDevice.BatteryState) -> ChargingState {
    switch batteryState {
    case .charging:
        return .ChargingAc
    case .full:
        return .ChargingAc
    default:
        return .NotCharging
    }
}

func isCharging(_ batteryState: UIDevice.BatteryState) -> Bool {
    batteryState == .charging
}

struct BatteryState: Encodable, Decodable {
    let batteryLevel: Float
    let isCharging: Bool
    let chargingState: ChargingState
}

struct TelemetryRequest: Encodable {
    let returnFriendLocations: Bool
    var telemetry: [TelemetryUpdate]
    let appState: AppState
    let batteryState: BatteryState?
}

struct TelemetryUpdate: Encodable {
    let recipientUsername: String
    let data: String
}

struct Connections: WithMessage {
    let message: String?
    let engineeringError: String?
    var following: [String: Friend]?
    var followers: [String: Friend]?
    var newFriends: Bool? = false

    func getMessage() -> String? {
        message
    }

    func getEngineeringError() -> String? {
        engineeringError
    }
}

struct Friend: Decodable {
    var userDetails: UserDetails?
    var batteryState: BatteryState?
    let state: PerceptionState?
    var accessType: AccessType?
    var telemetry: EncryptedTelemetry?
    var location: Location?
    var date: Date?
    var timestamp: String?
    var publicKey: String?
    var error: String?

    var connectionType: ConnectionType? = .Following

    func completeName() -> String {
        "\(userDetails?.firstName ?? "") \(userDetails?.lastName ?? "")"
    }

    func getReadableLastUpdate() -> String {
        switch (date?.timeAgoDisplay(), location, state, accessType) {
        case (_, _, .Normal, .EmergencyOnly):
            return NSLocalizedString("Limited Access", comment: "")
        case (.some(let dateAgo), .some, _, _):
            return "\(dateAgo)"
        default:
            return NSLocalizedString("No location found", comment: "")
        }
    }

    func getDescription() -> String {
        switch (connectionType, accessType) {
        case (.Follower, .EmergencyOnly):
            return NSLocalizedString("Emergency only access to your location", comment: "")
        case (.Follower, _):
            return NSLocalizedString("Can see your location", comment: "")
        default:
            return getReadableLastUpdate()
        }
    }

}

struct GetInvitationDetailsResponse: WithMessage {
    let message: String?
    let engineeringError: String?
    let firstName: String?
    let lastName: String?

    func getMessage() -> String? {
        message
    }

    func getEngineeringError() -> String? {
        engineeringError
    }
}

struct AcceptInvitationResponse: WithMessage {
    let message: String?
    let engineeringError: String?
    let publicKey: String?
    let username: String?

    func getMessage() -> String? {
        message
    }

    func getEngineeringError() -> String? {
        engineeringError
    }
}

enum ConnectionType: String, Decodable {
    case Follower
    case Following
    case Both
}

struct EncryptedTelemetry: Decodable {
    let data: String?
    let timestamp: String?
    let batteryState: BatteryState?
}

struct UserDetails: Decodable, WithMessage {
    let message: String?
    let engineeringError: String?
    let username: String?
    let firstName: String?
    let lastName: String?
    let email: String?
    let phoneNumber: String?
    let picture: String?
    let userState: UserState?

    init(username: String, picture: String) {
        self.username = username
        self.picture = picture
        self.firstName = ""
        self.lastName = ""
        self.email = ""
        self.phoneNumber = ""
        self.userState = UserState()
        self.engineeringError = nil
        self.message = nil
    }
    
    func getMessage() -> String? {
        message
    }
    
    func getEngineeringError() -> String? {
        engineeringError
    }
}

struct ConnectionTelemetry: Decodable {
    let timestamp: String?
    let location: Location?
    let date: Date?

    private enum CodingKeys: String, CodingKey {
        case timestamp
        case location
    }

    init(from decoder: Decoder) throws {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = DATE_FORMAT
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try container.decode(String.self, forKey: .timestamp)
        location = try container.decode(Location.self, forKey: .location)
        date = dateFormatter.date(from: self.timestamp ?? "")
    }
}

struct EncryptedHistoricalLocationPoint: Codable {
    var data: String
    var timestamp: String
    var deviceId: String
    
    init(data: String, timestamp: String, deviceId: String) {
        self.data = data
        self.timestamp = timestamp
        self.deviceId = deviceId
    }
}

struct HistoricalLocationResponse: WithMessage {
    var data: [EncryptedHistoricalLocationPoint]
    var message: String?
    var engineeringError: String?
    
    func getMessage() -> String? {
        message
    }
    
    func getEngineeringError() -> String? {
        engineeringError
    }

    // Takes a response JSON and parses to HistoricalLocationResponse
    init(result: [String: Any]) {
        self.data = []
        self.engineeringError = result["engineeringError"] as? String? ?? nil
        self.message = result["message"] as? String? ?? nil
        if let responseData: [[String: Any]] = result["result"] as? [[String: Any]] {
            responseData.forEach({ d in
                if let data: String = d["data"] as? String {
                    if let timestamp = d["timestamp"] as? String {
                        if let deviceId = d["device_id"] as? String {
                            let point = EncryptedHistoricalLocationPoint(
                                data: data,
                                timestamp: timestamp,
                                deviceId: deviceId
                            )
                            self.data.append(point)
                        }
                    }
                }
            })
        }
    }
    
    init(from decoder: Decoder) throws {
        fatalError("init(from decoder: Decoder) has not been implemented")
    }
}

struct HistoricalLocation {
    var locations: [LocationsForHistory]
    
    init(locations: [LocationsForHistory]) {
        self.locations = locations
    }
}

struct LocationsForHistory {
    var location: Location
    var deviceId: String
    var timestamp: String

    init(location: Location, deviceId: String, timestamp: String) {
        self.location = location
        self.deviceId = deviceId
        self.timestamp = timestamp
    }
}

struct LocationForHistory: Codable {
    var lat: Double = 0.0
    var lon: Double = 0.0

    init() {

    }

    init(lat: Double, lon: Double) {
        self.lat = lat
        self.lon = lon
    }
}

struct UserExistsResult: WithMessage {
    let exists: Bool?
    let message: String?
    let engineeringError: String?

    func getMessage() -> String? {
        message
    }

    func getEngineeringError() -> String? {
        engineeringError
    }
}

struct CodeVerificationRequest: Encodable {
    let publicKey: String
    let code: String
    let deviceId: String
    let os: String
    let osVersion: String
    let model: String
    let deletePreviousDevice: Bool
}

struct CodeVerificationResponse: WithMessage {
    let message: String?
    let engineeringError: String?
    let username: String?
    let email: String?
    let phoneNumber: String?
    let firstName: String?
    let lastName: String?
    let picture: String?
    let userState: UserState?

    func getMessage() -> String? {
        message
    }

    func getEngineeringError() -> String? {
        engineeringError
    }

    func toUserDetails() -> UserDetails? {
        if let username = self.username,
           let picture = self.picture {
            return UserDetails(username: username, picture: picture)
        } else {
            return nil
        }
    }

}

typealias UpdateProfileResponse = CodeVerificationResponse

struct RegistrationRequest: Encodable {
    let email: String?
    let phoneNumber: String?
    let firstName: String
    let lastName: String
    let publicKey: String
    let username: String
}

struct LoginRequest: Encodable {
    let email: String?
    let phoneNumber: String?
    let publicKey: String
}

struct GenericResponse: WithMessage {
    let message: String?
    let engineeringError: String?

    func getMessage() -> String? {
        message
    }

    func getEngineeringError() -> String? {
        message
    }
}
