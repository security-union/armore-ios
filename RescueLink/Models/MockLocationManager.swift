//
//  MockLocationTracker.swift
//  Armore
//
//  Created by Dario Talarico on 6/1/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation
import CoreLocation

let irapuato = CLLocation(latitude: 20.681032, longitude: -101.350692)
let leon = CLLocation(latitude: 21.132873, longitude: -101.668208)

public class MockLocationManager: LocationManager {

    var internalTimer: Timer?
    weak var delegate: CLLocationManagerDelegate?

    func startTimer() {

    }

    func stopTimer() {

    }

    func startForegroundTracking(_ delegate: CLLocationManagerDelegate?,
                                 updateFrequencyForeground: TimeInterval,
                                 updateFrequencyBackground: TimeInterval) {
        self.delegate = delegate
        if let timer = internalTimer {
            timer.invalidate()
        }
        internalTimer = Timer.scheduledTimer(withTimeInterval: updateFrequencyForeground,
                repeats: true,
                block: { _ in
                    self.delegate?.locationManager?(CLLocationManager(), didUpdateLocations: [leon])
                })
    }

    func startTrackingInTheBackground(
            _ delegate: CLLocationManagerDelegate?,
            updateFrequencyForeground: TimeInterval,
            updateFrequencyBackground: TimeInterval) {
        startForegroundTracking(delegate,
                updateFrequencyForeground: updateFrequencyForeground,
                updateFrequencyBackground: updateFrequencyBackground)
    }

    func stop() {
        internalTimer?.invalidate()
    }

    func authorizationStatus() -> CLAuthorizationStatus {
        CLAuthorizationStatus.authorizedAlways
    }

    func accuracyAuthorization() -> CLAccuracyAuthorization {
        CLAccuracyAuthorization.fullAccuracy
    }
}
