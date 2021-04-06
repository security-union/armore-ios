//
//  UserDetailsSheetController.swift
//   Armore
//
//  Created by Dario Lencina Talarico on 03/06/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import UIKit
import MaterialComponents.MaterialButtons
import RxSwift

class UserDetailsController: UIViewController, UITableViewDelegate, UITableViewDataSource, EmergencyCellDelegate {

    weak var fullName: UILabel?
    weak var email: UILabel?
    weak var address: UILabel?
    weak var friendHeaderArrow: UIView?
    @IBOutlet weak var emergencyLabel: UILabel!
    weak var header: UIView?
    @IBOutlet weak var tableView: UITableView!
    let disposeBag: DisposeBag = DisposeBag()
    let userDetailsPresenter = UserDetailsPresenter()
    private var selectedUser: DetailTable?
    var splash: CoolActivityIndicator?

    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme()
        setupObservers()
        setupHandlers()
        splash = CoolActivityIndicator(currentController: self)
    }

    func applyTheme() {
        tableView.backgroundView?.backgroundColor = UIColor.brandedGray()
    }

    func setupObservers() {
        userDetailsPresenter.selectedUser.subscribe(onNext: { [weak self] posibleUser in
            self?.selectedUser = posibleUser
            self?.refreshName(posibleUser)
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)
        userDetailsPresenter.friendsTableState.subscribe(onNext: { [weak self] tableState in
            switch tableState {
            case .Collapsed:
                self?.friendHeaderArrow?.transform = CGAffineTransform(rotationAngle: degreesToRadians(0))
            default:
                self?.friendHeaderArrow?.transform = CGAffineTransform(rotationAngle: degreesToRadians(180))
            }
            UIView.animate(withDuration: 0.3) {
                self?.view.layoutIfNeeded()
            }
        }).disposed(by: disposeBag)

        userDetailsPresenter.isUserDetailsLoading
                .subscribe(onNext: { [weak self] isLoading in
                    if isLoading {
                        self?.splash?.startAnimating()
                    } else {
                        self?.splash?.stopAnimating()
                    }

                }).disposed(by: disposeBag)
    }

    func setupHandlers() {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleTableState))
        header?.addGestureRecognizer(gestureRecognizer)
    }

    @IBAction func shareYourLocation(_ sender: Any) {
        performSegue(withIdentifier: newInvitationFromLocations,
                sender: selectedUser?.selectedFriend.userDetails)
    }

    @IBAction func close(_ sender: Any) {
        userDetailsPresenter.setSelectedUser(nil)
    }

    @IBAction func toggleTableState(_ sender: Any) {
        userDetailsPresenter.toggleTableState()
    }

    func refreshName(_ possibleUser: DetailTable?) {
        fullName?.text = possibleUser?.selectedFriend.completeName()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        selectedUser?.tableView(tableView, numberOfRowsInSection: section) ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        selectedUser?.tableView(tableView, cellForRowAt: indexPath, vc: self) ?? UITableViewCell()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        selectedUser?.tableView(tableView, heightForRowAt: indexPath) ?? 44
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedUser?.tableView(tableView, didSelectRowAt: indexPath)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is HistoricalLocationController {
            let vc = segue.destination as? HistoricalLocationController
            vc?.user = selectedUser?.selectedFriend
        }
    }
    
    func historicalLocationSegue() {
        performSegue(withIdentifier: "showHistoricalLocation", sender: self)
    }
}

class CellViewChangeType: UITableViewCell {
    @IBOutlet weak var lblAccessType: UILabel!
}
