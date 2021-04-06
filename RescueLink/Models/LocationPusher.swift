//
//  LocationPusher.swift
//  Armore
//
//  Created by Dario Talarico on 1/10/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Firebase
import Foundation
import UIKit
import CoreLocation
import RxSwift

let FOREGROUND_REFRESH_INTERVAL_SECS = 30.0
let BACKGROUND_REFRESH_INTERVAL_SECS = 30.0 * 6
let unknownError = NSLocalizedString("Unknown Error", comment: "")
private let lastLocationsKey = "lastLocations"

enum RefreshState {
    case Idle
    case Refreshing
}

func parseConnections(_ connections: ApiResponse<Connections>) -> [Friend]? {
    guard let following = connections.result?.following,
          let followers = connections.result?.followers else {
        return nil
    }
    let people = Set([following.keys.compactMap {
        $0
    },
        followers.keys.compactMap {
            $0
        }]
            .flatMap {
        $0
    }).sorted(by: >)
    return people.compactMap { username in
        switch ((followers[username], following[username])) {
        case (Optional.some(let follower), Optional.some(let personBeingFollowed)):
            return Friend(userDetails: personBeingFollowed.userDetails,
                    batteryState: personBeingFollowed.batteryState,
                    state: personBeingFollowed.state,
                    accessType: follower.accessType,
                    location: personBeingFollowed.location,
                    date: personBeingFollowed.date,
                    timestamp: personBeingFollowed.timestamp,
                    error: personBeingFollowed.error,
                    connectionType: .Both)
        case (nil, Optional.some(let personBeingFollowed)):
            return Friend(userDetails: personBeingFollowed.userDetails,
                    batteryState: personBeingFollowed.batteryState,
                    state: personBeingFollowed.state,
                    accessType: personBeingFollowed.accessType,
                    location: personBeingFollowed.location,
                    date: personBeingFollowed.date,
                    timestamp: personBeingFollowed.timestamp,
                    error: personBeingFollowed.error,
                    connectionType: .Following)
        case (Optional.some(let follower), nil):
            return Friend(userDetails: follower.userDetails,
                    batteryState: follower.batteryState,
                    state: nil,
                    accessType: follower.accessType,
                    error: follower.error,
                    connectionType: .Follower)
        default:
            return nil
        }
    }.sorted { (a, b) -> Bool in
        a.completeName() < b.completeName()
    }
}

typealias ResultCallback = (UIBackgroundFetchResult) -> Void

let useMockLocation = CommandLine.arguments.contains("UITests")

public class LocationPusher: NSObject, CLLocationManagerDelegate {
    let locationPusherModel = LocationPusherModel()
    var lastUpdateForegroundForKeys = Date.init(timeIntervalSince1970: 0)
    private var locationManager: LocationManager =
            useMockLocation ? MockLocationManager() : RealLocationManager()
    private var location: CLLocation?
    static let instance = LocationPusher()
    private weak var delegate: CLLocationManagerDelegate?

    let connections: BehaviorSubject<ApiResponse<Connections>?> = BehaviorSubject(value: nil)
    let refreshState: BehaviorSubject<RefreshState> = BehaviorSubject(value: .Idle)

    private override init() {
        super.init()
        if let locationsData = UserDefaults.standard.data(forKey: lastLocationsKey),
           let deserializedLocation = NSKeyedUnarchiver.unarchiveObject(with: locationsData) as? CLLocation {
            self.location = deserializedLocation
        }
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
        self.locationManager.stopTimer()
    }

    @objc func appMovedToForeground() {
        self.locationManager.delegate = self
        self.locationManager.startTimer()
        self.verifyThatWeStillHavePermissions()
    }

    @objc func backgroundRefreshStatusChanged() {
        self.verifyThatWeStillHavePermissions()
    }

    func startTracking() {
        self.locationManager.startTrackingInTheBackground(self,
                updateFrequencyForeground: FOREGROUND_REFRESH_INTERVAL_SECS,
                updateFrequencyBackground: BACKGROUND_REFRESH_INTERVAL_SECS)
    }

    func startLocationFromNotification(_ result: ResultCallback? = nil) {
        startTracking()
    }

    func stop() {
        self.locationManager.stop()
    }

    @objc func forcePushLocation(_ result: ResultCallback? = nil) {
        if let location = self.location, CurrentUser().isSessionActive() {
            pushLocationToServer(location)
        }
        result?(UIBackgroundFetchResult.newData)
    }

    public func hasAccessToLocationAlwaysHighAccuracyAndBackgroundRefresh() -> Bool {
        CLLocationManager.locationServicesEnabled() &&
                (self.locationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways) &&
                (self.locationManager.accuracyAuthorization() == CLAccuracyAuthorization.fullAccuracy &&
                        UIApplication.shared.backgroundRefreshStatus == UIBackgroundRefreshStatus.available)
    }

    public func verifyThatWeStillHavePermissions() {
        if !hasAccessToLocationAlwaysHighAccuracyAndBackgroundRefresh() && CurrentUser().isSessionActive() {
            if UIApplication.shared.applicationState != .active {
                let content = UNMutableNotificationContent()
                content.title = NSLocalizedString("Attention", tableName: nil,
                        bundle: Bundle.main,
                        value: "",
                        comment: "")
                content.body = NSLocalizedString("oTL-CT-4zv.text",
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
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: BFSessionShouldShowGPSDisabled),
                    object: nil)
        } else {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: BFSessionShouldShowGPSEnabled),
                    object: nil)
            startTracking()
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        storeLastLocation(locations.last)
        if let unwrapped = locations.last, CurrentUser().isSessionActive() {
            pushLocationToServer(unwrapped)
        } else if !CurrentUser().isSessionActive() {
            stop()
        }
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        UIState.instance.updateDeviceSettings()
        verifyThatWeStillHavePermissions()
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        UIState.instance.updateDeviceSettings()
        verifyThatWeStillHavePermissions()
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Crashlytics.crashlytics().log("Error with location nmanager \(error)")
        Crashlytics.crashlytics().record(error: error)
    }

    private func pushLocationToServer(_ location: CLLocation) {
        refreshState.onNext(.Refreshing)
        locationPusherModel.updateLocationsAndGetKeys(
                location: Location(location),
                returnFriends: true) { [weak self] response in
            if let httpError = response.httpCode, httpError == 403 {
                UIState.instance.jwtExpired()
            }
            if let httpError = response.httpCode, response.success == false {

                let error = response.getEngineeringError().or(response.getMessage().or(unknownError))
                UIState.instance.logError(error, code: httpError)
                UIState.instance.showError(response.getMessage().or(unknownError))
            }
            self?.refreshState.onNext(.Idle)
            self?.connections.onNext(response)
        }
    }

    func storeLastLocation(_ location: CLLocation?) {
        guard let safeLocation = location else {
            return
        }
        self.location = location
        let defaults = UserDefaults.standard
        let archivedLocation = NSKeyedArchiver.archivedData(withRootObject: safeLocation)
        defaults.setValue(archivedLocation, forKey: lastLocationsKey)
        defaults.synchronize()
    }
}
