//
//  LoginController.swift
//   Armore
//
//  Created by Security Union on 03/11/19.
//  Copyright © 2019 Security Union. All rights reserved.
//

import UIKit
import MaterialComponents
import RxSwift
import PhoneNumberKit

let goToSignUpControllerSegue = "goToSignUpController"
let goToLocationsControllerSegue = "goToLocationsController"
let goToCodeVerificationControllerSegue = "goToCodeVerificationController"

class LoginController: AuthController, UITextFieldDelegate, CountryCodePickerDelegate {

    @IBOutlet weak var txtUsername: MDCTextField!
    @IBOutlet weak var continueBtn: MDCFloatingButton!
    @IBOutlet weak var phoneNumberPicker: PhoneNumberPicker!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    private var countryCodeSelected: CountryCodePickerViewController.Country?

    var code: String?
    var usernameController: MDCTextInputControllerFilled!
    var authMethod = AuthMethod.sms

    private let loginPresenter = LoginPresenter(urls: URLs())
    private var disposeBag: DisposeBag?

    override func viewDidLoad() {
        super.viewDidLoad()
        txtUsername.sizeToFit()
        txtUsername.delegate = self
        self.segmentedControl.addTarget(self,
                action: #selector(self.onSegmentedControlChanged(event:)),
                for: .valueChanged)
        refreshSegmentedControl()
        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        if loginPresenter.checkSession() {
            gotoLocationsController()
        }
        setupObservers()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        switch authMethod {
        case .email:
            txtUsername.becomeFirstResponder()
        default:
            phoneNumberPicker.phoneNumber.becomeFirstResponder()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        disposeBag = nil
    }

    @objc func onSegmentedControlChanged(event: UIEvent) {
        refreshSegmentedControl()
    }

    func refreshSegmentedControl() {
        loginPresenter.setAuthMethod(self.segmentedControl.selectedSegmentIndex == 0 ? .sms : .email)
    }

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }

    override func showProgress(_ progress: Bool) {
        progressView.isHidden = !progress
        progressView.frame = CGRect(
                x: 0,
                y: UIApplication.shared.statusBarFrame.size.height,
                width: view.bounds.width,
                height: progressViewHeight
        )
    }

    func setupObservers() {
        let localBag = DisposeBag()
        self.loginPresenter.isBusy.subscribe(onNext: { [weak self] isBusy in
            self?.continueBtn.isEnabled = !isBusy
            self?.showProgress(isBusy)
            if isBusy {
                self?.showProgressDialog()
            } else {
                self?.hideProgressDialog()
            }
        }).disposed(by: localBag)
        self.loginPresenter.notification.subscribe(onNext: { [weak self] notification in
            if let inboundNotification = notification, inboundNotification.name.rawValue == OnVerificationCodeNotif {
                self?.handleUserActivityNotification(notification: inboundNotification)
            }
        }).disposed(by: localBag)
        self.loginPresenter.email.subscribe(onNext: { [weak self] email in
            self?.keyGenerationController.setEmailState(email != nil ? .successful : .inProgress)
        }).disposed(by: localBag)
        self.loginPresenter.keyGenerationState.subscribe(onNext: { [weak self] keyGenerationState in
            switch keyGenerationState {
            case .generating:
                self?.keyGenerationController.setPublicKeyState(.inProgress)
            case .generated:
                self?.keyGenerationController.setPublicKeyState(.successful)
            default:
                self?.keyGenerationController.setPublicKeyState(.notStarted)
            }
        }).disposed(by: localBag)
        self.phoneNumberPicker.onCountryNameTapped.subscribe(onNext: { [weak self] event in
            if event == nil {
                return
            }
            guard let self = self else {
                return
            }
            self.pickCountry()
        }).disposed(by: localBag)

        self.phoneNumberPicker.onCountryCodeTapped.subscribe(onNext: { [weak self] event in
            if event == nil {
                return
            }
            guard let self = self else {
                return
            }
            self.pickCountry()
        }).disposed(by: localBag)

        self.loginPresenter.countryCodeSelected.subscribe(onNext: { [weak self] country in
            self?.phoneNumberPicker.countryCode.text = country.prefix
            self?.phoneNumberPicker.countryName.text = country.name
            self?.countryCodeSelected = country
        }).disposed(by: localBag)

        self.loginPresenter.authMethod.subscribe(onNext: { [weak self] method in
            self?.authMethod = method
            self?.txtUsername.isHidden = method == .sms
            self?.phoneNumberPicker.isHidden = method != .sms
        }).disposed(by: localBag)

        disposeBag = localBag
    }

    func pickCountry() {
        let countryCodesController = CountryCodePickerViewController(
                phoneNumberKit: self.loginPresenter.phoneNumberKit)
        countryCodesController.selectedCountryCode = self.countryCodeSelected
        countryCodesController.delegate = self
        self.present(
                UINavigationController(rootViewController: countryCodesController),
                animated: true, completion: nil)
    }

    func countryCodePickerViewControllerDidPickCountry(
            _ ctrl: CountryCodePickerViewController, country: CountryCodePickerViewController.Country) {
        ctrl.dismiss(animated: true)
        self.loginPresenter.setCountryCode(code: country.code)
    }

    func signIn() {
        txtUsername.text = ""
        self.performSegue(withIdentifier: goToLocationsControllerSegue, sender: self)
    }

    func applyTheme() {
        usernameController = MDCTextInputControllerFilled(textInput: txtUsername)
        usernameController.applyTheme(withScheme: ArmoreTheme.instance.textFieldTheme)
        usernameController.borderFillColor = .white
        continueBtn.applyContainedTheme(withScheme: ArmoreTheme.instance.roundedButtonTheme)

        segmentedControl.setTitle(NSLocalizedString("RCb-SI-TKZ.segmentTitles[0]", comment: ""), forSegmentAt: 0)
        segmentedControl.setTitle(NSLocalizedString("RCb-SI-TKZ.segmentTitles[1]", comment: ""), forSegmentAt: 1)
        styleSegmentedControl(segmentedControl)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch (segue.destination, sender) {
        case let (passwordResetController as
                  CodeVerificationViewController, code as String):
            passwordResetController.code = code
        default:
            break
        }
    }

    @IBAction func verifyEmailAction(_ sender: Any) {
        verifyUsingAuthMethod()
    }

    func verifyUsingAuthMethod() {
        let (acceptedFields, authenticationData) = self.authMethod == .sms ? validateSms() : validateEmail()

        if acceptedFields {
            loginPresenter.userExists(data: authenticationData, authMethod: self.authMethod) { [weak self] response in
                if let exists = response.result?.exists, exists {
                    self?.loginPresenter.login(email: authenticationData) { [weak self] response2 in
                        if response2.success {
                            self?.hideProgressDialog {
                                self?.goToCodeVerificationController()
                            }
                        } else if let error = response2.result?.message, !response2.success {
                            self?.showMessage(title: "Error", message: error)
                        }
                    }
                } else if let exists = response.result?.exists, !exists, response.success {
                    self?.hideProgressDialog {
                        self?.gotoSignUpController(authenticationData)
                    }
                } else if let error = response.result?.message, !response.success {
                    self?.showMessage(title: "Error", message: error)
                }
            }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        verifyUsingAuthMethod()
        return true
    }

    // method that returns if fields where accepted and the username and password in case are accepted
    func validateEmail() -> (Bool, String) {
        let username = txtUsername.text!

        var allFieldsOk = true

        if username.trimmingCharacters(in: .whitespaces) == "" {
            allFieldsOk = false
        }

        if !allFieldsOk {
            let alert = UIAlertController(
                    title: NSLocalizedString("Missing fields", comment: ""),
                    message: NSLocalizedString("All fields need to be filled to sign in.", comment: "")
            )
            alert.simpleOkAction()
            alert.display()
        }

        return (allFieldsOk, username.trimmingCharacters(in: .whitespaces))
    }

    func validateSms() -> (Bool, String) {
        guard let countryCode = phoneNumberPicker.countryCode.text else {
            return (false, "")
        }
        guard let phoneNumber = phoneNumberPicker.phoneNumber.text else {
            return (false, "")
        }
        let completePhoneNumber = "\(countryCode)\(phoneNumber)"

        var allFieldsOk = true

        if completePhoneNumber.trimmingCharacters(in: .whitespaces) == "" {
            allFieldsOk = false
        }

        if !allFieldsOk {
            let alert = UIAlertController(
                    title: NSLocalizedString("Missing fields", comment: ""),
                    message: NSLocalizedString("All fields need to be filled to sign in.", comment: "")
            )
            alert.simpleOkAction()
            alert.display()
        }

        return (allFieldsOk, completePhoneNumber.trimmingCharacters(in: .whitespaces))
    }

    @IBAction func returnFromSignUpToLoginAndGoToMap(_ segue: UIStoryboardSegue) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.signIn()
        }
    }

    @IBAction func unwindToLoginController(_ unwindSegue: UIStoryboardSegue) {

    }

    @objc func handleUserActivityNotification(notification: Notification) {
        if let object = notification.object {
            switch object {
            case let verification as Verification:
                self.goToCodeVerificationController(verification.code)
            default:
                break
            }
        }
    }

    func gotoSignUpController(_ email: String) {
        self.performSegue(withIdentifier: goToSignUpControllerSegue, sender: email)
    }

    func goToCodeVerificationController(_ code: String? = nil) {
        self.performSegue(withIdentifier: goToCodeVerificationControllerSegue, sender: code)
    }

    func gotoLocationsController() {
        self.performSegue(withIdentifier: goToLocationsControllerSegue, sender: nil)
    }

}
