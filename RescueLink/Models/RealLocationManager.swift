//
//  RealLocationPusher.swift
//  Armore
//
//  Created by Dario Talarico on 6/1/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import CoreLocation
import Foundation
import UIKit

class RealLocationManager: NSObject, LocationManager, CLLocationManagerDelegate {
    private let locationManager: CLLocationManager = CLLocationManager()
    weak var delegate: CLLocationManagerDelegate?
    var updateFrequencyForeground: TimeInterval = 30
    var updateFrequencyBackground: TimeInterval = 30
    var lastUpdate = Date.init(timeIntervalSince1970: 0)
    private var lastLocations: [CLLocation]?
    private var locationTimer: Timer?

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func startTimer() {
        locationTimer?.invalidate()
        locationTimer = Timer.scheduledTimer(
                withTimeInterval: TimeInterval(FOREGROUND_REFRESH_INTERVAL_SECS),
                repeats: true,
                block: { [weak self] (_) in
                    if let locations = self?.getLastKnownLocation(),
                       let locationManager = self?.locationManager {
                        self?.locationManager(locationManager, didUpdateLocations: locations)
                    }
                })
        locationTimer?.fire()
    }

    func stopTimer() {
        locationTimer?.invalidate()
    }

    func configureLocationManager(_ delegate: CLLocationManagerDelegate?,
                                  updateFrequencyForeground: TimeInterval,
                                  updateFrequencyBackground: TimeInterval) {
        self.delegate = delegate
        self.updateFrequencyForeground = updateFrequencyForeground
        self.updateFrequencyBackground = updateFrequencyBackground
        UIDevice.current.isBatteryMonitoringEnabled = true
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.activityType = CLActivityType.otherNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    func startForegroundTracking(_ delegate: CLLocationManagerDelegate?,
                                 updateFrequencyForeground: TimeInterval,
                                 updateFrequencyBackground: TimeInterval) {
        if !CurrentUser().isSessionActive() {
            return
        }
        if authorizationStatus() == .authorizedAlways {
            configureLocationManager(delegate,
                    updateFrequencyForeground: updateFrequencyForeground,
                    updateFrequencyBackground: updateFrequencyBackground)
            locationManager.startUpdatingLocation()
        } else {
            locationManager.requestWhenInUseAuthorization()
            locationManager.requestAlwaysAuthorization()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: BFSessionShouldShowGPSDisabled),
                    object: nil)
        }
    }

    func startTrackingInTheBackground(_ delegate: CLLocationManagerDelegate?,
                                      updateFrequencyForeground: TimeInterval,
                                      updateFrequencyBackground: TimeInterval) {
        if !CurrentUser().isSessionActive() {
            return
        }
        if authorizationStatus() == .authorizedAlways {
            configureLocationManager(delegate,
                    updateFrequencyForeground: updateFrequencyForeground,
                    updateFrequencyBackground: updateFrequencyBackground)
            self.startMonitoringSignificantLocationChangesIfAvailable()
        } else {
            locationManager.requestAlwaysAuthorization()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: BFSessionShouldShowGPSDisabled),
                    object: nil)
        }
    }

    func startMonitoringSignificantLocationChangesIfAvailable() {
        if CLLocationManager.significantLocationChangeMonitoringAvailable() {
            locationManager.startMonitoringSignificantLocationChanges()
        } else {
            locationManager.startUpdatingLocation()
        }
    }

    func authorizationStatus() -> CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return locationManager.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }

    func accuracyAuthorization() -> CLAccuracyAuthorization {
        if #available(iOS 14.0, *) {
            return locationManager.accuracyAuthorization
        } else {
            return CLAccuracyAuthorization.fullAccuracy
        }
    }

    func stop() {
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        self.locationTimer?.invalidate()
    }

    func getLastKnownLocation() -> [CLLocation]? {
        if !CurrentUser().isSessionActive() {
            return nil
        }
        if let location = locationManager.location {
            return [location]
        } else {
            return self.lastLocations
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if #available(iOS 14.0, *) {
            self.delegate?.locationManagerDidChangeAuthorization?(manager)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.delegate?.locationManager?(manager, didChangeAuthorization: status)
    }

    public func shouldUpdateLocation() -> Bool {
        let intervalToUse = self.updateFrequencyForeground
        return UIApplication.shared.applicationState != .active ||
                Date().compare(lastUpdate.addingTimeInterval(intervalToUse)) == .orderedDescending
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.lastLocations = locations
        if self.shouldUpdateLocation() {
            lastUpdate = Date()
            self.delegate?.locationManager?(manager, didUpdateLocations: locations)
        }
    }
}
