//
//  DeviceSettingsService.swift
//  Armore
//
//  Created by Griffin Obeid on 10/30/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation
import Alamofire
import CoreLocation

func getLocationPermissionState() -> LocationPermissionState {
    switch CLLocationManager.authorizationStatus() {
    case .authorizedAlways:
        return LocationPermissionState.ALWAYS
    case .authorizedWhenInUse:
        return LocationPermissionState.USING
    case .restricted:
        return LocationPermissionState.ASK
    case .denied:
        return LocationPermissionState.NEVER
    case .notDetermined:
        return LocationPermissionState.UNKNOWN
    default:
        return LocationPermissionState.UNKNOWN
    }
}

enum LocationPermissionState: String, Decodable, Encodable {
    case ALWAYS
    case USING
    case ASK
    case NEVER
    case UNKNOWN
}

struct DeviceSettingsRequest: Encodable, Decodable, Equatable {
    var locationPermissionState: LocationPermissionState
    var isPowerSaveModeOn: Bool
    var isNotificationsEnabled: Bool
    var isBackgroundRefreshOn: Bool
    var isLocationServicesOn: Bool
    var osVersion: String
    var appVersion: String

    static func buildDeviceSettings() -> DeviceSettingsRequest {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        let bundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
        return DeviceSettingsRequest(
                locationPermissionState: getLocationPermissionState(),
                isPowerSaveModeOn: ProcessInfo.processInfo.isLowPowerModeEnabled,
                isNotificationsEnabled: UIApplication.shared.isRegisteredForRemoteNotifications,
                isBackgroundRefreshOn:
                    UIApplication.shared.backgroundRefreshStatus == UIBackgroundRefreshStatus.available,
                isLocationServicesOn: CLLocationManager.locationServicesEnabled(),
                osVersion: UIDevice.current.systemVersion,
                appVersion: "\(shortVersion ?? "")-\(bundleVersion ?? "")"
        )
    }
}

struct DeviceSettingsResponse: WithMessage {
    let message: String?
    let engineeringError: String?
    let updated: Bool?

    func getMessage() -> String? {
        message
    }

    func getEngineeringError() -> String? {
        engineeringError
    }
}

func deviceSettingsRequest(
        _ deviceSettings: DeviceSettingsRequest,
        completion: @escaping (ApiResponse<DeviceSettingsResponse>) -> Void) {
    AF.request(
            URLs().deviceSettings(),
            method: .post,
            parameters: deviceSettings,
            encoder: JSONParameterEncoder.default,
            headers: addBaseHeaders([])
    ).responseJSON { response in
        if let data = response.data,
           var apiResponse = try? JSONDecoder().decode(ApiResponse<DeviceSettingsResponse>.self, from: data) {
            apiResponse.httpCode = response.response?.statusCode
            completion(apiResponse)
        } else {
            completion(ApiResponse<DeviceSettingsResponse>(
                    success: false,
                    httpCode: response.response?.statusCode,
                    result: DeviceSettingsResponse(
                            message: NSLocalizedString("server_parsing_error", comment: ""),
                            engineeringError: NSLocalizedString("server_parsing_error", comment: ""),
                            updated: nil
                    )
            ))
        }
    }
}
