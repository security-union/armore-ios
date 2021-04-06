//
//  SignUpController.swift
//  RescueLink
//
//  Created by Dario Lencina on 7/2/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import UIKit
import MaterialComponents
import RxSwift

class SignUpController: AuthController {
    private let presenter = SignUpPresenter()
    var code: String?
    @IBOutlet weak var instructionsTitle: UILabel!
    @IBOutlet weak var firstName: MDCTextField!
    @IBOutlet weak var lastName: MDCTextField!
    @IBOutlet weak var continueBtn: MDCButton!
    @IBOutlet weak var page: UILabel!
    var firsNameController: MDCTextInputControllerFilled!
    var lastNameController: MDCTextInputControllerFilled!
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = false
        applyTheme()
        setupObservers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        firstName.becomeFirstResponder()
    }

    func applyTheme() {
        firsNameController = MDCTextInputControllerFilled(textInput: firstName)
        lastNameController = MDCTextInputControllerFilled(textInput: lastName)
        firsNameController.applyTheme(withScheme: ArmoreTheme.instance.textFieldTheme)
        lastNameController.applyTheme(withScheme: ArmoreTheme.instance.textFieldTheme)
        firsNameController.borderFillColor = .white
        lastNameController.borderFillColor = .white
        continueBtn.applyContainedTheme(withScheme: ArmoreTheme.instance.roundedButtonTheme)
        page.textColor = UIColor.brandedWhite()
        page.font = UIFont(name: OxygenRegular, size: 17)
    }

    func setupObservers() {
        self.presenter.isBusy.subscribe(onNext: { [weak self] isBusy in
            self?.continueBtn.isEnabled = !isBusy
            self?.showProgress(isBusy)
            if isBusy {
                self?.showProgressDialog()
            } else {
                self?.hideProgressDialog()
            }
        }).disposed(by: disposeBag)
        self.presenter.email.subscribe(onNext: { [weak self] email in
            self?.keyGenerationController.setEmailState(email != nil ? .successful : .inProgress)
        }).disposed(by: disposeBag)
        self.presenter.keyGenerationState.subscribe(onNext: { [weak self] keyGenerationState in
            switch keyGenerationState {
            case .generating:
                self?.keyGenerationController.setPublicKeyState(.inProgress)
            case .generated:
                self?.keyGenerationController.setPublicKeyState(.successful)
            default:
                self?.keyGenerationController.setPublicKeyState(.notStarted)
            }
        }).disposed(by: disposeBag)
    }

    @IBAction func register() {
        presenter.register(
                firstName: firstName.text!,
                lastName: lastName.text!) { [weak self] response in
            if response.success {
                self?.goToCodeVerificationController()
            } else {
                self?.showMessage(
                        title: "Error",
                        message: response.getMessage() ?? NSLocalizedString("server_parsing_error", comment: "")
                )
            }
        }
    }

    func goToCodeVerificationController(_ code: String? = nil) {
        self.performSegue(withIdentifier: goToCodeVerificationControllerSegue, sender: code)
    }

}
