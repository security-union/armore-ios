//
//  FriendsTableViewController.swift
//   Armore
//
//  Created by Dario Talarico on 6/10/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import CoreLocation
import Firebase
import UIKit
import RxSwift

let friendCell = "friendCell"
let placeholderCell = "placeholderCell"
let placeholderCellFile = "PlaceholderCell"
let placeholderCellHeight = CGFloat(160)
let newInvitationFromLocations = "newInvitationFromLocations"

class FriendsTableViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    let friendsTablePresenter = FriendsTablePresenter()
    var disposeBag: DisposeBag?
    var userList: [Friend]? = [Friend]()
    let refreshControl = UIRefreshControl()
    let geocoder = CLGeocoder()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTheme()
        setupObservers()
    }

    @objc private func refreshFriends(_ sender: Any) {
        self.friendsTablePresenter.forceRefresh()
    }

    func setupTheme() {
        refreshControl.tintColor = UIColor.brandedWhite()
        refreshControl.addTarget(self, action: #selector(refreshFriends(_:)), for: .valueChanged)
        if #available(iOS 10.0, *) {
            self.tableView.refreshControl = refreshControl
        } else {
            self.tableView.addSubview(refreshControl)
        }
        self.tableView.contentOffset = CGPoint(x: 0, y: -refreshControl.frame.size.height)
    }

    func setupObservers() {
        let disposeBag = DisposeBag()
        self.disposeBag = disposeBag
        self.friendsTablePresenter.connections.subscribe(onNext: { [weak self] connections in
            guard let unwrappedConnections = connections else {
                return
            }
            self?.userList = parseConnections(unwrappedConnections)
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)

        self.friendsTablePresenter.refreshState.subscribe(onNext: { [weak self] refreshState in
            switch refreshState {
            case .Refreshing:
                self?.refreshControl.beginRefreshing()
            default:
                self?.refreshControl.endRefreshing()

            }
        }).disposed(by: disposeBag)
    }

    func removeObservers() {
        self.disposeBag = nil
    }

    override func didLoadImage(notification: Notification) {
        if notification.object as? UIImage != nil {
            self.tableView.reloadData()
        }
    }

    @IBAction func shareYourLocation(_ sender: Any) {
        self.performSegue(withIdentifier: newInvitationFromLocations, sender: self)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = self.userList?.count, count > 0 {
            return count
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if userList == nil || userList?.isEmpty ?? true {
            return placeholderCellHeight
        } else {
            return 75
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if userList == nil || userList?.isEmpty ?? true {

        } else if let username = userList?[indexPath.row].userDetails?.username {
            friendsTablePresenter.setSelectedUser(username)
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if userList == nil || userList?.isEmpty ?? true {
            var cell: PlaceholderCell? =
                    tableView.dequeueReusableCell(withIdentifier: placeholderCell) as? PlaceholderCell
            if cell == nil {
                tableView.register(UINib.init(nibName: placeholderCellFile,
                        bundle: Bundle.main),
                        forCellReuseIdentifier: placeholderCell)
                cell = tableView.dequeueReusableCell(withIdentifier: placeholderCell) as? PlaceholderCell
                cell?.backgroundColor = UIColor.brandedBlack()
                cell?.sendInvitationButton.addTargetClosure { [weak self] ctx in
                    self?.shareYourLocation(ctx)
                }
                cell?.sendInvitationButton.swapFont(OxygenBold)
            }
            return cell ?? UITableViewCell()
        } else if let cell = tableView.dequeueReusableCell(withIdentifier: friendCell) as? FriendCell,
                  let user = userList?[indexPath.row] {
            cell.userImage.roundedImage()
            cell.lblName.text = user.completeName()
            cell.lblDescription.text = user.getDescription()
            cell.lblDescription.adjustsFontSizeToFitWidth = true
            cell.lblName.swapFont(OxygenRegular)
            cell.lblDescription.swapFont(OxygenRegular)
            cell.batteryLevel?.batteryState = user.batteryState
            cell.batteryLevel.layer.cornerRadius = 2
            cell.batteryLevel.layer.masksToBounds = true

            let isEmergency = user.state == .Emergency
            cell.imageEmergency.isHidden = !isEmergency
            if let location = user.location {
                geocoder.reverseGeocodeLocation(location.clLocation()) { [weak cellRef = cell]
                (placemark: [CLPlacemark]?, _) in
                    if let date = user.date?.timeAgoDisplay(),
                       let description = placemark?.first?.toFormattedString()?.split(separator: "\n").first,
                       cellRef?.lblName.text == user.completeName() {
                        cellRef?.lblDescription.text = "\(description) (\(date))"
                    }
                }
            }
            if isEmergency {
                cell.lblName.textColor = .brandedFontRed()
                cell.lblDescription.textColor = .brandedFontRed()
            } else {
                cell.lblName.textColor = .brandedWhite()
                cell.lblDescription.textColor = .brandedWhite()
            }
            cell.userImage?.image = user.userDetails.flatMap {
                ImageProfile().getImageOrDownloadIt($0)
            } ?? UIImage(named: DEFAULT_PLACEHODER_IMAGE)
            cell.selectedBackgroundView = UIView()
            cell.selectedBackgroundView?.backgroundColor = UIColor.brandedPink3()
            return cell
        } else {
            return UITableViewCell()
        }
    }
}

class FriendCell: UITableViewCell {
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var imageEmergency: UIImageView!
    @IBOutlet weak var batteryLevel: BatteryLevelView!
}
