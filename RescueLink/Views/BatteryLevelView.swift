//
//  BatteryLevelView.swift
//  RescueLink
//
//  Created by Dario Lencina on 7/11/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import UIKit

// swiftlint:disable:next cyclomatic_complexity
func imageForBatteryState(batteryState: BatteryState?) -> String? {
    switch (batteryState?.batteryLevel, batteryState?.chargingState) {
    case (.some(let level), .some(let state)) where level > 99 && state != .NotCharging:
        return "battery_charging_full_black_96x96"
    case (.some(let level), .some(let state)) where level >= 90 && state != .NotCharging:
        return "battery_charging_90_black_96x96"
    case (.some(let level), .some(let state)) where level >= 80 && state != .NotCharging:
        return "battery_charging_80_black_96x96"
    case (.some(let level), .some(let state)) where level >= 60 && state != .NotCharging:
        return "battery_charging_60_black_96x96"
    case (.some(let level), .some(let state)) where level >= 50 && state != .NotCharging:
        return "battery_charging_50_black_96x96"
    case (.some(let level), .some(let state)) where level >= 30 && state != .NotCharging:
        return "battery_charging_30_black_96x96"
    case (_, .some(let state)) where state != .NotCharging:
        return "battery_charging_20_black_96x96"
    case (.some(let level), .some(let state)) where level > 99 && state == .NotCharging:
        return "battery_full_black_96x96"
    case (.some(let level), .some(let state)) where level > 90 && state == .NotCharging:
        return "battery_90_black_96x96"
    case (.some(let level), .some(let state)) where level > 80 && state == .NotCharging:
        return "battery_80_black_96x96"
    case (.some(let level), .some(let state)) where level > 60 && state == .NotCharging:
        return "battery_60_black_96x96"
    case (.some(let level), .some(let state)) where level > 50 && state == .NotCharging:
        return "battery_50_black_96x96"
    case (.some(let level), .some(let state)) where level > 30 && state == .NotCharging:
        return "battery_30_black_96x96"
    case (_, .some(let state)) where state == .NotCharging:
        return "battery_20_black_96x96"
    default:
        return nil
    }
}
// swiftlint:disable:previous cyclomatic_complexity

class BatteryLevelView: UIView {

    @IBOutlet weak var stateView: UIImageView!
    @IBOutlet weak var levelLabel: UILabel!
    private var _batteryState: BatteryState?

    var batteryState: BatteryState? {
        get {
            return _batteryState
        }

        set {
            self.isHidden = newValue == nil
            self._batteryState = newValue
            self.levelLabel.text = _batteryState.map {
                String(format: "%.0f %%", $0.batteryLevel)
            }
            self.stateView.image = imageForBatteryState(batteryState: newValue).flatMap {
                UIImage(named: $0)
            }
        }
    }
}
