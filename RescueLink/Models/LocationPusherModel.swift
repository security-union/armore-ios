//
//  LocationPusherModel.swift
//  Armore
//
//  Created by Dario Talarico on 6/2/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation
import Alamofire

class LocationPusherModel {

    private let urls: URLs = URLs()

    // Encrypt the location for the currently logged user and for all the followers.
    private func getEncryptedTelemetry(location: Location, returnFriends: Bool) -> TelemetryRequest {
        var telemetryArray = [TelemetryUpdate]()
        let defaults = UserDefaults.standard

        // loop through the followerUsernames
        defaults.stringArray(forKey: FOLLOWERS_USERNAMES)?.forEach {
            if let encryptedLocation = Crypto.encryptLocation(location: location, with: $0) {
                let base64Encrypted = encryptedLocation.base64EncodedString(options: .lineLength76Characters)
                telemetryArray.append(TelemetryUpdate(recipientUsername: $0, data: base64Encrypted))
            }
        }

        // Encrypt the currently logged user location
        if let encryptedLocation = Crypto.encryptLocationForCurrentUser(location) {
            let base64Encrypted = encryptedLocation.base64EncodedString(options: .lineLength76Characters)
            if let username = CurrentUser().getUserInfo()?.username {
                telemetryArray.append(TelemetryUpdate(recipientUsername: username, data: base64Encrypted))
            }
        }

        let appState: AppState = UIApplication.shared.applicationState == .active ? .Foreground : .Background
        let device = UIDevice.current
        return TelemetryRequest(
                returnFriendLocations: returnFriends,
                telemetry: telemetryArray,
                appState: appState,
                batteryState: device.isBatteryMonitoringEnabled ? BatteryState(
                        batteryLevel: device.batteryLevel * 100,
                        isCharging: isCharging(device.batteryState),
                        chargingState: appleBatteryStateToCharingState(device.batteryState)
                ) : nil
        )
    }

    func updateLocationsAndGetKeys(location: Location,
                                   returnFriends: Bool,
                                   completion: @escaping (ApiResponse<Connections>) -> Void) {
        let telemetryRequest = getEncryptedTelemetry(location: location,
                returnFriends: returnFriends)
        AF.request(urls.telemetry(),
                        method: .post,
                        parameters: telemetryRequest,
                        encoder: JSONParameterEncoder.default,
                        headers: addBaseHeaders([]))
                .responseJSON { response in
                    if let data = response.data,
                       var apiResponse = try? JSONDecoder().decode(ApiResponse<Connections>.self, from: data),
                       var result = apiResponse.result {
                        apiResponse.httpCode = response.response?.statusCode
                        var parsedFollowers = [String: Friend]()
                        result.following?.forEach {
                            var connection = $0.value
                            connection.timestamp = connection.telemetry?.timestamp
                            connection.batteryState = connection.telemetry?.batteryState
                            if let data = connection.telemetry?.data {
                                if let decodedLocation = Crypto.decryptLocation(data) {
                                    connection.location = decodedLocation
                                } else {
                                    connection.error = DECRYPTION_ERROR
                                }
                            } else {
                                connection.error = TELEMETRY_PARSING_ERROR
                            }
                            connection.date = Date.parseDate(connection.timestamp)
                            parsedFollowers[$0.key] = connection
                        }
                        result.following = parsedFollowers
                        var newFriends: [Bool] = []
                        result.followers?.forEach {
                            if let username = $0.value.userDetails?.username, let publicKey = $0.value.publicKey {
                                newFriends.append(Crypto.saveUsersPublicKey(publicKey, for: username))
                            }
                        }
                        result.newFriends = newFriends.contains(true)
                        completion(ApiResponse<Connections>(
                                success: apiResponse.success,
                                httpCode: response.response?.statusCode,
                                result: result))
                    } else {
                        let connections = Connections(
                                message: NSLocalizedString("server_parsing_error", comment: ""),
                                engineeringError: NSLocalizedString("server_parsing_error", comment: ""),
                                following: [:],
                                followers: [:])
                        completion(ApiResponse<Connections>(
                                success: false,
                                httpCode: response.response?.statusCode,
                                result: connections
                        ))
                    }
                }
    }
}
