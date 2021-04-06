//
//  UIState.swift
//   Armore
//
//  Created by Dario Talarico on 6/2/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Firebase
import UIKit
import RxSwift
import Alamofire
import CoreLocation
import PhoneNumberKit

enum FriendsTableState {
    case Collapsed
    case Visible
    case FullScreen
}

let lastSettingsKey = "lastSettingsKey"

/**
 Central location for storing UIState.
 */
class UIState {
    public static let instance = UIState()
    private let urls: URLs = URLs()
    private let req = Request()
    let notification: BehaviorSubject<Notification?> = BehaviorSubject(value: nil)
    let seeHistoricalLocation: BehaviorSubject<Friend?> = BehaviorSubject(value: nil)
    let changeAccessType: BehaviorSubject<Friend?> = BehaviorSubject(value: nil)
    let friendsTableState: BehaviorSubject<FriendsTableState> = BehaviorSubject(value: .Visible)
    let selectedUser: Observable<DetailTable?>
    let isUserDetailsLoading: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    let isPictureLoading: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    let isLowPowerModeEnabled: BehaviorSubject<Bool> =
            BehaviorSubject(value: ProcessInfo.processInfo.isLowPowerModeEnabled)
    var settings: DeviceSettingsRequest?

    let error: BehaviorSubject<(String, Int)?> = BehaviorSubject(value: nil)
    private let pSelectedUser: BehaviorSubject<String?> = BehaviorSubject(value: nil)

    private init() {
        if let settingsData = UserDefaults.standard.data(forKey: lastSettingsKey),
           let storedSettings = try? JSONDecoder().decode(DeviceSettingsRequest.self, from: settingsData) {
            settings = storedSettings
        }
        selectedUser = Observable
                .combineLatest(LocationPusher.instance.connections, pSelectedUser)
                .map { (friends, username) in
                    friends.flatMap { cachedFriends in
                                parseConnections(cachedFriends)?.first(where: { user in
                                    user.userDetails?.username == username
                                })
                            }
                            .map { selectedFriend in
                                if FeatureFlags().EMERGENCY {
                                    return EmergencyFriendDetailsTable(
                                        selectedFriend: selectedFriend,
                                        inEmergency: selectedFriend.state == .Emergency
                                    )
                                } else {
                                    return FriendDetailsTable(selectedFriend: selectedFriend)
                                }
                            }
                }

        NotificationCenter.default.addObserver(
                self,
                selector: #selector(onPowerStateDidChange),
                name: NSNotification.Name.NSProcessInfoPowerStateDidChange,
                object: nil
        )
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                selector: #selector(appMovedToForeground),
                name: UIApplication.willEnterForegroundNotification, object: nil)
        notificationCenter.addObserver(self,
                selector: #selector(appMovedToBackground),
                name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self,
                selector: #selector(backgroundRefreshStatusChanged),
                name: UIApplication.backgroundRefreshStatusDidChangeNotification,
                object: nil)
    }

    @objc func appMovedToBackground() {
        updateDeviceSettings()
    }

    @objc func appMovedToForeground() {
        updateDeviceSettings()
    }

    @objc func backgroundRefreshStatusChanged() {
        updateDeviceSettings()
    }

    public func jwtExpired() {
        // show alert to the user saying that the session expired
        CurrentUser().logoutUser()
        let alert = UIAlertController(
                title: NSLocalizedString("Session Expired", comment: ""),
                message: NSLocalizedString("The session has expired, you need to sign in again.", comment: ""),
                preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
            let windowRef = self.window()
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: type(of: self)))
            windowRef?.rootViewController = storyboard.instantiateInitialViewController()
        }))
        alert.show(true, completion: nil)
    }

    public func showError(_ error: String, code: Int = 0) {
        self.error.onNext((error, code))
    }

    public func logError(_ error: String, code: Int = 0) {
        Crashlytics.crashlytics().record(error: NSError(domain: error, code: code, userInfo: nil))
    }

    func window() -> UIWindow? {
        let alertWindow: UIWindow?
        if #available(iOS 13.0, *) {
            alertWindow = UIApplication.shared.connectedScenes.filter {
                $0.activationState == .foregroundActive
            }
                    .map {
                $0 as? UIWindowScene
            }
                    .first??.windows.filter {
                ($0.rootViewController as? UINavigationController != nil)
            }.first
        } else {
            alertWindow = (UIApplication.shared.delegate as? AppDelegate)?.window
        }
        return alertWindow
    }

    public func setSelectedUser(_ username: String?) {
        pSelectedUser.onNext(username)
    }

    public func seeHistoricalLocation(_ user: Friend?) {
        seeHistoricalLocation.onNext(user)
    }

    public func changeAccessType(_ user: Friend?) {
        changeAccessType.onNext(user)
    }

    public func setFriendsTableState(_ state: FriendsTableState) {
        friendsTableState.onNext(state)
    }

    public func setNotification(_ notification: Notification) {
        self.notification.onNext(notification)
    }

    public func clearNotification() {
        notification.onNext(nil)
    }

    public func toggleTableState() {
        switch try? friendsTableState.value() {
        case Optional.some(.Collapsed):
            friendsTableState.onNext(.Visible)
        default:
            friendsTableState.onNext(.Collapsed)
        }
    }

    public func clearError() {
        error.onNext(nil)
    }

    public func resetState() {
        setSelectedUser(nil)
        seeHistoricalLocation(nil)
        changeAccessType(nil)
        setFriendsTableState(.Visible)
        isUserDetailsLoading.onNext(false)
        clearError()
    }

    public func newAccessType(user: Friend, newAccessType: AccessType) {
        if user.accessType != newAccessType {
            let alert = UIAlertController(
                    title: NSLocalizedString("Attention", comment: ""),
                    message: String(
                            format: NSLocalizedString("cofirm_change_access",
                                    comment: ""),
                            user.completeName()),
                    preferredStyle: .alert)
            alert.addAction(UIAlertAction(
                    title: NSLocalizedString("Confirm", comment: ""),
                    style: .default,
                    handler: { [weak self] _ in
                        self?._newAccessType(user: user, newAccessType: newAccessType)
                    }))
            alert.addAction(UIAlertAction(
                    title: NSLocalizedString("Cancel", comment: ""),
                    style: .cancel,
                    handler: nil)
            )
            alert.show(true, completion: nil)
        }
    }

    func removeFriend(user: Friend) {
        let alert = UIAlertController(
                title: NSLocalizedString("Attention", comment: ""),
                message: String(format: NSLocalizedString("confirm_unfollow", comment: ""), user.completeName()),
                preferredStyle: .alert)
        alert.addAction(UIAlertAction(
                title: NSLocalizedString("Confirm", comment: ""),
                style: .default,
                handler: { [weak self] _ in
                    self?._removeFriend(user: user)
                }))
        alert.addAction(UIAlertAction(
                title: NSLocalizedString("Cancel", comment: ""),
                style: .cancel,
                handler: nil)
        )
        alert.show(true, completion: nil)
    }

    private func _newAccessType(user: Friend, newAccessType: AccessType) {
        let requestParameters: [String: Any] = [:]
        isUserDetailsLoading.onNext(true)
        req.requestChangeResponse(url: URLs().meNewAccessType(newAccessType: newAccessType,
                username: (user.userDetails?.username)!),
                headers: [],
                parameters: requestParameters,
                methodType: .post) { [weak self] (response) in
            self?.isUserDetailsLoading.onNext(false)
            if response.success {
                LocationPusher.instance.forcePushLocation()
            } else {
                self?.error.onNext((response.errorMessage, response.responseCode))
            }
        }
    }

    private func _removeFriend(user: Friend) {
        let requestParameters: [String: Any] = [:]
        isUserDetailsLoading.onNext(true)
        req.requestChangeResponse(url: urls.removeFriend(username: user.userDetails?.username ?? ""),
                headers: [],
                parameters: requestParameters,
                methodType: .delete) { [weak self] (response) in
            self?.isUserDetailsLoading.onNext(false)
            if response.success {
                LocationPusher.instance.forcePushLocation()
            } else {
                self?.error.onNext((response.errorMessage, response.responseCode))
            }
        }
    }

    struct ProfilePatchRequest: Encodable {
        let picture: String
    }

    func updateImageProfile(_ image: UIImage,
                            completion: @escaping (ApiResponse<UpdateProfileResponse>) -> Void) {
        isPictureLoading.onNext(true)
        let patchRequest = ProfilePatchRequest(picture: image.getBase64())
        AF.request(urls.me(),
                        method: .patch,
                        parameters: patchRequest,
                        encoder: JSONParameterEncoder.default,
                        headers: addBaseHeaders([]))
                .responseJSON { [weak self] response in
                    self?.isPictureLoading.onNext(false)
                    if let data = response.data,
                       let apiResponse = try? JSONDecoder()
                               .decode(ApiResponse<UpdateProfileResponse>.self, from: data) {
                        completion(apiResponse)
                    } else {
                        completion(ApiResponse<UpdateProfileResponse>(
                                success: false,
                                httpCode: response.response?.statusCode,
                                result: UpdateProfileResponse(
                                        message: NSLocalizedString("server_parsing_error", comment: ""),
                                        engineeringError: NSLocalizedString("server_parsing_error", comment: ""),
                                        username: nil,
                                        email: nil,
                                        phoneNumber: nil,
                                        firstName: nil,
                                        lastName: nil,
                                        picture: nil,
                                        userState: nil)
                        ))
                    }
                }
    }

    @objc func onPowerStateDidChange(notification: Notification) {
        let localIsLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        if localIsLowPowerModeEnabled {
            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("Attention", tableName: nil,
                    bundle: Bundle.main,
                    value: "",
                    comment: "")
            content.body = NSLocalizedString("low_battery_mode",
                    tableName: nil,
                    bundle: Bundle.main,
                    value: "",
                    comment: "")
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let localNotification = UNNotificationRequest(identifier: BFSessionShouldShowGPSDisabled,
                    content: content,
                    trigger: trigger)
            let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.add(localNotification, withCompletionHandler: nil)
        }
        isLowPowerModeEnabled.onNext(ProcessInfo.processInfo.isLowPowerModeEnabled)
        updateDeviceSettings()
    }

    func storeSettings(_ newSettings: DeviceSettingsRequest) {
        settings = newSettings
        let defaults = UserDefaults.standard
        let archivedData = try? JSONEncoder().encode(newSettings)
        defaults.setValue(archivedData, forKey: lastSettingsKey)
        defaults.synchronize()
    }

    func updateDeviceSettings() {
        if !CurrentUser().isSessionActive() {
            return
        }
        // Calling from main queue to access settings safely
        DispatchQueue.main.async {
            let settings = DeviceSettingsRequest.buildDeviceSettings()
            if self.settings != nil && settings == self.settings {
                return
            }

            DispatchQueue.global(qos: .background).async {
                deviceSettingsRequest(settings) { response in
                    if let httpError = response.httpCode {
                        if response.success {
                            self.storeSettings(settings)
                        } else {
                            let error = response.getEngineeringError().or(response.getMessage().or(unknownError))
                            UIState.instance.logError(error, code: httpError)
                        }
                    }
                }
            }
        }
    }

    static func defaultRegionCode() -> String {
        Locale.current.regionCode.map {
            $0.uppercased()
        }.or(PhoneNumberKit.defaultRegionCode())
    }
}
