//
//  MyDeviceController.swift
//   Armore
//
//  Created by Security Union on 16/11/19.
//  Copyright © 2019 Security Union. All rights reserved.
//

import UIKit
import MaterialComponents.MaterialButtons
import MaterialComponents.MaterialButtons_Theming
import MaterialComponents.MaterialColorScheme
import MaterialComponents.MaterialButtons_ButtonThemer

protocol MyDeviceProtocol: NSObjectProtocol {
    func showMessage(title: String, message: String)
    func accessInfoGotten(usersWithAccess: [User])
    func accessRevoked()
}

class MyDeviceController: BaseViewController, UITableViewDelegate, UITableViewDataSource, MyDeviceProtocol {

    // Needed variables
    var myDevice = Device()

    // Protocol Methods
    private let myDevicePresenter = MyDevicePresenter(urls: URLs())

    func accessInfoGotten(usersWithAccess: [User]) {

        myDevice.guest = usersWithAccess
        tableView.reloadData()

    }

    func accessRevoked() {
        showMessage(title: NSLocalizedString("Access Revoked",
                comment: ""),
                message: NSLocalizedString("The access was successfully revoked.",
                        comment: ""))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        lblMyDeviceName.text = String(format: NSLocalizedString("My Device Name: %@",
                comment: ""), myDevice.name)
        lblMyDeviceId.text = String(format: NSLocalizedString("My Device Id: %@",
                comment: ""), myDevice.deviceId)
        lblMyDeviceOS.text = String(format: NSLocalizedString("My Device OS: %@",
                comment: ""), myDevice.os)
        lblMyDeviceModel.text = String(format: NSLocalizedString("My Device Model:  %@",
                comment: ""), myDevice.model)
        lblMyDeviceVersion.text = String(format: NSLocalizedString("My Device OS Version: %@",
                comment: ""), myDevice.osVersion)
        navigationItem.title = NSLocalizedString("My Device", comment: "")

        btnNewInvitationOutlet.roundedCornersSmall()

        // get the access of my device
        myDevicePresenter.setViewDelegate(myDeviceController: self)

        applyThemes()

        navigationController?.navigationBar.tintColor = .white
    }

    func applyThemes() {
        btnNewInvitationOutlet.beContained()
    }

    override func viewDidAppear(_ animated: Bool) {

    }

    // Views Connections START
    @IBOutlet weak var lblMyDeviceName: UILabel!
    @IBOutlet weak var lblMyDeviceId: UILabel!
    @IBOutlet weak var lblMyDeviceOS: UILabel!
    @IBOutlet weak var lblMyDeviceModel: UILabel!
    @IBOutlet weak var lblMyDeviceVersion: UILabel!
    @IBOutlet weak var btnNewInvitationOutlet: MDCButton!
    @IBOutlet weak var tableView: UITableView!

    // Buttons START
    @IBAction func btnNewInvitation(_ sender: Any) {
        self.performSegue(withIdentifier: "showNewInvitationFromMyDevice", sender: self)
    }

    @IBAction func btnBack(_ sender: Any) {

    }

    // Buttons END

    // table view START
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 117
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myDevice.guest.count > 0 ? myDevice.guest.count : 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if myDevice.guest.count != 0 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? CellPeopleWithAccessToDevice {

                cell.selectionStyle = .none

                let userGuestSelected = myDevice.guest[indexPath.row].username

                cell.lblName.text = ""
                cell.lblEmail.text = ""
                cell.lblUsername.text = userGuestSelected
                cell.btnRevokeAccessOutlet.isEnabled = true
                cell.btnRevokeAccess = { _ in
                    let alert = UIAlertController(
                            title: NSLocalizedString("Revoke Access", comment: ""),
                            message: String(format: NSLocalizedString("revoke_access_prompt",
                                    comment: ""),
                                    userGuestSelected, self.myDevice.deviceId))
                    alert.addAction(UIAlertAction(title: NSLocalizedString("Revoke",
                            comment: ""),
                            style: .destructive, handler: { (_) in
                        // revoke the access

                    }))
                    alert.addAction(UIAlertAction(title: NSLocalizedString("No", comment: ""),
                            style: .default, handler: { (_) in }))
                    alert.display()

                }
                cell.btnRevokeAccessOutlet.beOutlined(type: .error)
                return cell
            }

        } else {
            // no people with access to the device
            if let cell = tableView.dequeueReusableCell(withIdentifier: "cellNoPeople") as? CellNoPeopleWithAccess {
                return cell
            }
        }
        return UITableViewCell()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    }

}

class CellPeopleWithAccessToDevice: UITableViewCell {

    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblUsername: UILabel!
    @IBOutlet weak var lblEmail: UILabel!
    @IBOutlet weak var imageProfileImage: UIImageView!
    @IBOutlet weak var btnRevokeAccessOutlet: MDCButton!

    // btnRevokeAccess Action
    var btnRevokeAccess: ((Any) -> Void)?

    @IBAction func btnRevokeAccessPressed(_ sender: Any) {
        self.btnRevokeAccess?(sender)
    }

}

class CellNoPeopleWithAccess: UITableViewCell {

}
