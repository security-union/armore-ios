//
//  LocationManager.swift
//  Armore
//
//  Created by Dario Talarico on 6/2/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationManager {
    func startForegroundTracking(_ delegate: CLLocationManagerDelegate?,
                                 updateFrequencyForeground: TimeInterval,
                                 updateFrequencyBackground: TimeInterval)
    func startTrackingInTheBackground(_ delegate: CLLocationManagerDelegate?,
                                      updateFrequencyForeground: TimeInterval,
                                      updateFrequencyBackground: TimeInterval)
    func stop()
    func authorizationStatus() -> CLAuthorizationStatus
    func accuracyAuthorization() -> CLAccuracyAuthorization
    func startTimer()
    func stopTimer()
    var delegate: CLLocationManagerDelegate? { get set }
}
