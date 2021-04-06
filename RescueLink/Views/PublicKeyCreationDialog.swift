//
//  PublicKeyCreationDialog.swift
//  RescueLink
//
//  Created by Dario Lencina on 8/4/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import UIKit
import MaterialComponents
import RxSwift

enum StepState {
    case notStarted
    case inProgress
    case successful
    case error
}

class PublicKeyCreationDialog: UIViewController {
    @IBOutlet weak var emailVerify: MDCActivityIndicator?
    @IBOutlet weak var publicKeyGeneration: MDCActivityIndicator?
    @IBOutlet weak var sendingEmail: MDCActivityIndicator?

    @IBOutlet weak var emailIcon: UIImageView?
    @IBOutlet weak var publicKeyIcon: UIImageView?
    @IBOutlet weak var sendingEmailIcon: UIImageView?

    @IBOutlet weak var sendingEmailLbl: UILabel?
    @IBOutlet weak var pleaseWait: UILabel?
    @IBOutlet weak var generatingKeys: UILabel?
    @IBOutlet weak var verifyingEmail: UILabel?

    let successImage = UIImage.init(named: "check")
    let failureImage = UIImage.init(named: "alert")
    var emailState: StepState = .notStarted
    var publicKeyState: StepState = .notStarted
    var sendingEmailState: StepState = .inProgress
    let authMethod = AuthState.instance.authMethod
    private var disposeBag: DisposeBag?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        self.view.isAccessibilityElement = true
        mdc_dialogPresentationController?.dismissOnBackgroundTap = false
        sendingEmailLbl?.text = NSLocalizedString("auth_sending_email", comment: "")
        pleaseWait?.text = NSLocalizedString("auth_please_wait", comment: "")
        generatingKeys?.text = NSLocalizedString("auth_generating_keys", comment: "")
        setupObservers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hidrateView()
    }

    func setupObservers() {
        let localBag = DisposeBag()
        self.authMethod.subscribe(onNext: { [weak self] method in
            self?.verifyingEmail?.text =
                    method == .sms ? NSLocalizedString("auth_verify_phone", comment: "")
                    : NSLocalizedString("auth_verify_email", comment: "")
        }).disposed(by: localBag)
        disposeBag = localBag
    }

    static func getInstance() -> PublicKeyCreationDialog? {
        let keyGenerationController = PublicKeyCreationDialog(nibName: "PublicKeyCreationDialog", bundle: Bundle.main)
        keyGenerationController.modalPresentationStyle = .custom
        return keyGenerationController
    }

    func hidrateView() {
        setEmailState(emailState)
        setPublicKeyState(publicKeyState)
        setSendingEmailState(sendingEmailState)
    }

    func setEmailState(_ state: StepState) {
        emailState = state
        switch state {
        case .notStarted:
            emailVerify?.startAnimating()
            emailIcon?.image = nil
        case .inProgress:
            emailVerify?.startAnimating()
            emailIcon?.image = nil
        case .successful:
            emailVerify?.stopAnimating()
            emailIcon?.image = successImage
        case .error:
            emailVerify?.stopAnimating()
            emailIcon?.image = failureImage
        }
    }

    func setPublicKeyState(_ state: StepState) {
        publicKeyState = state
        switch state {
        case .notStarted:
            publicKeyGeneration?.startAnimating()
            publicKeyIcon?.image = nil
        case .inProgress:
            publicKeyGeneration?.startAnimating()
            publicKeyIcon?.image = nil
        case .successful:
            publicKeyGeneration?.stopAnimating()
            publicKeyIcon?.image = successImage
        case .error:
            publicKeyGeneration?.stopAnimating()
            publicKeyIcon?.image = failureImage
        }
    }

    func setSendingEmailState(_ state: StepState) {
        publicKeyState = state
        switch state {
        case .notStarted:
            sendingEmail?.startAnimating()
            sendingEmailIcon?.image = nil
        case .inProgress:
            sendingEmail?.startAnimating()
            sendingEmailIcon?.image = nil
        case .successful:
            sendingEmail?.stopAnimating()
            sendingEmailIcon?.image = successImage
        case .error:
            sendingEmail?.stopAnimating()
            sendingEmailIcon?.image = failureImage
        }
    }

    override var preferredContentSize: CGSize {
        get {
            return CGSize(width: 280, height: 222)
        }
        set {
            super.preferredContentSize = newValue
        }
    }
}
