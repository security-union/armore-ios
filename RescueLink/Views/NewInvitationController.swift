//
//  NewInvitationController.swift
//   Armore
//
//  Created by Security Union on 16/11/19.
//  Copyright © 2019 Security Union. All rights reserved.
//

import UIKit
import MaterialComponents.MaterialButtons
import RxSwift

class NewInvitationController: BaseViewController {

    private let presenter = InvitationPresenter(urls: URLs())
    @IBOutlet weak var lblMessageInvitation: UILabel!
    @IBOutlet weak var expirationTimeSelection: UILabel!
    @IBOutlet weak var send: MDCFloatingButton!
    @IBOutlet weak var share: MDCFloatingButton!
    @IBOutlet weak var createInvitation: UIView!
    @IBOutlet weak var shareInvitation: UIView!
    @IBOutlet weak var invitation: MDCTextField!
    private var disposeBag: DisposeBag?
    lazy private var activityIndicator: CoolActivityIndicator = {
        CoolActivityIndicator(currentController: self)
    }()

    func invitationSentCorrectly() {
        let alert = UIAlertController(
                title: NSLocalizedString("Invitation Sent", comment: ""),
                message: "\(NSLocalizedString("The invitation was sent correctly", comment: ""))")
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
            self.dismiss(animated: true, completion: nil)
        }))
        alert.display()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("Send Invitation", comment: "")
        lblMessageInvitation.text = NSLocalizedString("new_invitation_prompt", comment: "")
        expirationTimeSelection.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(expirationTimeSelected)))
        applyThemes()
        setupObservers()
    }

    func applyThemes() {
        let containerScheme = MDCContainerScheme()
        containerScheme.colorScheme.primaryColor = UIColor.brandedRed()
        navigationController?.navigationBar.barTintColor = .black
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        lblMessageInvitation.textColor = UIColor.brandedWhite()
        lblMessageInvitation.font = UIFont(name: OxygenRegular, size: 17)
        expirationTimeSelection.addBottomStroke()
        send.applyContainedTheme(withScheme: ArmoreTheme.instance.roundedButtonTheme)
        share.applyContainedTheme(withScheme: ArmoreTheme.instance.roundedButtonTheme)
        let textFieldController = MDCTextInputControllerFilled(textInput: invitation)
        textFieldController.applyTheme(withScheme: ArmoreTheme.instance.textFieldTheme)
        textFieldController.borderFillColor = .white
        invitation.sizeToFit()
    }

    func setupObservers() {
        let localBag = DisposeBag()

        self.presenter.selectedExpirationTime.subscribe(onNext: { [weak self] expirationTime in
            DispatchQueue.main.async {
                self?.expirationTimeSelection.text = NSLocalizedString(expirationTime.rawValue, comment: "")
            }
        }).disposed(by: localBag)
        
        self.presenter.currentisBusy.subscribe(onNext: { [weak self] isBusy in
            DispatchQueue.main.async {
                if isBusy {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                }
            }
        }).disposed(by: localBag)
        
        self.presenter.currentInvitationState.subscribe(onNext: { [weak self] invitationState in
            DispatchQueue.main.async {
                switch invitationState {
                case .createInvitation:
                    self?.createInvitation.isHidden = false
                    self?.shareInvitation.isHidden = true
                case .shareInvitation(let link):
                    self?.invitation.text = String(
                        format: NSLocalizedString("invitation_call_to_action", comment: ""),
                        link)
                    self?.createInvitation.isHidden = true
                    self?.shareInvitation.isHidden = false
                    self?.shareInvitation2()
                }
            }       
        }).disposed(by: localBag)
        self.presenter.currentError.subscribe(onNext: { [weak self] onError in
            if let error = onError {
                DispatchQueue.main.async {
                    self?.showError(title: "Error", message: error)
                }
            }
        }).disposed(by: localBag)

        disposeBag = localBag
    }
    
    @objc func expirationTimeSelected() {
        let actionSheet = UIAlertController(
            title: "",
            message: NSLocalizedString("Select a new expiration time:", comment: ""), preferredStyle: .actionSheet)
        [ExpirationTime.oneDay, ExpirationTime.oneWeek, ExpirationTime.oneMonth].forEach { option in
            actionSheet.addAction(UIAlertAction(
                title: NSLocalizedString(option.rawValue, comment: ""),
                style: .default) {_ in
                self.presenter.setSelectedExpirationTime(option)
            })
        }
        actionSheet.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .destructive))
        actionSheet.show(true)
    }

    @IBAction func btnSendInvitation(_ sender: Any) {
        presenter.createInvitation()
    }

    @IBAction func btnBack(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func showError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        alert.display()
    }
    
    @IBAction func shareInvitation2() {
        let items = [self.invitation.text]
        let ac = UIActivityViewController(activityItems: items as [Any], applicationActivities: nil)
        present(ac, animated: true)
    }
}
