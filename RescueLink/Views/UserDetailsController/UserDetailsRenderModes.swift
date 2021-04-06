//
//  UserDetailsRenderModes.swift
//   Armore
//
//  Created by Dario Talarico on 6/14/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import Contacts

extension CLPlacemark {
    func toFormattedString() -> String? {
        if let addressElements = self.postalAddress {
            let formattedAddress = CNPostalAddressFormatter.string(from: addressElements, style: .mailingAddress)
            return formattedAddress
        } else {
            return nil
        }
    }
}

let locationShareAllTheTime = "locationShareAllTheTime"
let locationShareOnlyEmergency = "locationShareOnlyEmergency"
let removeFriend = "removeFriend"
let headerCell = "header"
let emergencyFile = "EmergencyModeSettings"
let emergencyReuseId = "emergencyCell"
let emergencyRowHeight = CGFloat(160)
let headerHeight = CGFloat(200)

func configureHeader(_ tableView: UITableView, selectedFriend: Friend) -> UITableViewCell {
    let cell: HeaderTableViewCell? = tableView.dequeueReusableCustomCell(withIdentifier: headerCell)
    cell?.address.textColor = UIColor.brandedWhite()
    cell?.address.text = selectedFriend.getDescription()
    cell?.email.text = selectedFriend.userDetails?.email ?? "--"
    cell?.phone.text = selectedFriend.userDetails?.phoneNumber ?? "--"
    cell?.timestamp.text = selectedFriend.getReadableLastUpdate()
    cell?.batteryLevelView?.batteryState = selectedFriend.batteryState
    cell?.batteryLevelView.layer.cornerRadius = 2
    cell?.batteryLevelView.layer.masksToBounds = true

    if let font = cell?.address.font {
        cell?.address.font = UIFont(name: OxygenRegular, size: font.pointSize)
    }
    if let coordinate = selectedFriend.location?.clLocation() {
        CLGeocoder().reverseGeocodeLocation(coordinate) { [weak cellRef = cell](placemark: [CLPlacemark]?, _) in
            if let addressElements = placemark?.first?.toFormattedString() {
                cellRef?.address.text = addressElements
            }
        }
    }
    return cell ?? UITableViewCell()
}

protocol DetailTable {
    var selectedFriend: Friend { get }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath,
                   vc: UserDetailsController?) -> UITableViewCell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
}

public struct FriendDetailsTable: DetailTable {
    let selectedFriend: Friend
    let presenter = FriendDetailsTablePresenter()

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return headerHeight
        case 1:
            return 65
        default:
            return 50
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath,
                   vc: UserDetailsController?) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            return configureHeader(tableView, selectedFriend: selectedFriend)
        case 1:
            let cell = tableView.dequeueReusableButtonCell(withIdentifier: removeFriend,
                    indexPath: indexPath)
            return cell ?? UITableViewCell()
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 1:
            presenter.removeFriend(user: selectedFriend)
        default:
            break
        }
    }
}

public struct EmergencyFriendDetailsTable: DetailTable {
    let selectedFriend: Friend
    let inEmergency: Bool
    let presenter = FriendDetailsTablePresenter()

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if inEmergency {
            switch indexPath.row {
            case 0:
                return emergencyRowHeight
            case 1:
                return headerHeight
            case 4:
                return 65
            default:
                return 50
            }
        } else {
            switch indexPath.row {
            case 0:
                return headerHeight
            case 3:
                return 65
            case 4:
                return 65
            default:
                return 50
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if inEmergency {
            return 5
        } else {
            return 4
        }
    }

    // swiftlint:disable cyclomatic_complexity
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath,
                   vc: UserDetailsController?) -> UITableViewCell {
        if inEmergency {
            switch indexPath.row {
            case 0:
                var cell: EmergencyCell? =
                        tableView.dequeueReusableCell(withIdentifier: emergencyReuseId) as? EmergencyCell
                if cell == nil {
                    tableView.register(UINib.init(nibName: emergencyFile,
                            bundle: Bundle.main),
                            forCellReuseIdentifier: emergencyReuseId)
                    cell = tableView.dequeueReusableCell(withIdentifier: emergencyReuseId) as? EmergencyCell
                }
                cell?.selectionStyle = .none
                cell?.delegate = vc
                cell?.backgroundColor = UIColor.brandedBlack()
                let emergencyCellText =
                    NSLocalizedString("Attention! Blank has enabled emergency mode.", comment: "")
                let friendName = selectedFriend.userDetails?.firstName ??
                    NSLocalizedString("Your friend", comment: "")
                cell?.emergencyLabel.text = String(format: emergencyCellText, friendName)
                
                return cell ?? UITableViewCell()
            case 1:
                return configureHeader(tableView, selectedFriend: selectedFriend)
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: locationShareAllTheTime)!
                cell.textLabel?.text = NSLocalizedString("Share your location all the time", comment: "")
                cell.accessoryType = selectedFriend.accessType == .Permanent ? .checkmark : .none
                return cell
            case 3:
                let cell = tableView.dequeueReusableCell(withIdentifier: locationShareOnlyEmergency)!
                cell.textLabel?.text = NSLocalizedString("Share only while emergency mode is on", comment: "")
                cell.accessoryType = selectedFriend.accessType == .EmergencyOnly ? .checkmark : .none
                return cell
            case 4:
                let cell = tableView.dequeueReusableButtonCell(withIdentifier: removeFriend,
                        indexPath: indexPath)
                return cell ?? UITableViewCell()
            default:
                return UITableViewCell()
            }
        } else {
            switch indexPath.row {
            case 0:
                return configureHeader(tableView, selectedFriend: selectedFriend)
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: locationShareAllTheTime)!
                cell.accessoryType = selectedFriend.accessType == .Permanent ? .checkmark : .none
                return cell
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: locationShareOnlyEmergency)!
                cell.accessoryType = selectedFriend.accessType == .EmergencyOnly ? .checkmark : .none
                return cell
            case 3:
                let cell = tableView.dequeueReusableButtonCell(withIdentifier: removeFriend,
                        indexPath: indexPath)
                return cell ?? UITableViewCell()
            default:
                return UITableViewCell()
            }
        }
    }
    // swiftlint:enable cyclomatic_complexity

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if inEmergency {
            switch indexPath.row {
            case 2:
                presenter.newAccessType(user: selectedFriend, newAccessType: .Permanent)
            case 3:
                presenter.newAccessType(user: selectedFriend, newAccessType: .EmergencyOnly)
            case 4:
                presenter.removeFriend(user: selectedFriend)
            default:
                break
            }
        } else {
            switch indexPath.row {
            case 1:
                presenter.newAccessType(user: selectedFriend, newAccessType: .Permanent)
            case 2:
                presenter.newAccessType(user: selectedFriend, newAccessType: .EmergencyOnly)
            case 3:
                presenter.removeFriend(user: selectedFriend)
            default:
                break
            }
        }
    }
}

class HeaderTableViewCell: UITableViewCell {
    @IBOutlet weak var address: UITextView!
    @IBOutlet weak var email: UITextView!
    @IBOutlet weak var phone: UITextView!
    @IBOutlet weak var timestamp: UITextView!
    @IBOutlet weak var batteryLevelView: BatteryLevelView!
}

protocol EmergencyCellDelegate: class {
    func historicalLocationSegue()
}

class EmergencyCell: UITableViewCell {
    @IBOutlet weak var emergencyLabel: UILabel!
    
    weak var delegate: EmergencyCellDelegate?
    
    @IBAction func onTouchHistoricalLocation(_ sender: Any) {
        delegate?.historicalLocationSegue()
    }
}
