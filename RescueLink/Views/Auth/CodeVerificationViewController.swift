//
//  CodeVerificationViewController.swift
//  RescueLink
//
//  Created by Dario Lencina on 7/2/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import MaterialComponents

class CodeVerificationViewController: BaseViewController {

    private let presenter = CodeVerificationPresenter()
    var code: String?
    @IBOutlet weak var instructionsTitle: UILabel!
    @IBOutlet weak var instructionsBody: UILabel!
    @IBOutlet weak var verificationCode: MDCTextField!
    @IBOutlet weak var continueBtn: MDCButton!
    @IBOutlet weak var resendCode: UIButton!
    var textFieldController: MDCTextInputControllerFilled!
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTheme()
        setupObservers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = false
        verificationCode.becomeFirstResponder()
        if let code = self.code {
            verificationCode.text = code
            self.code = nil
        }
    }

    @objc func handleUserActivityNotification(notification: Notification) {
        if let object = notification.object {
            switch object {
            case let verification as Verification:
                self.verificationCode.text = verification.code
                self.code = verification.code
                self.verificationCode.setNeedsLayout()
            default:
                break
            }
        }
    }

    func setupTheme() {
        textFieldController = MDCTextInputControllerFilled(textInput: verificationCode)
        textFieldController.applyTheme(withScheme: ArmoreTheme.instance.textFieldTheme)
        textFieldController.borderFillColor = .white
        continueBtn.applyContainedTheme(withScheme: ArmoreTheme.instance.roundedButtonTheme)
        instructionsTitle.textColor = UIColor.brandedWhite()
        instructionsTitle.font = UIFont(name: OxygenBold, size: 24)
        instructionsBody.textColor = UIColor.brandedWhite()
        instructionsBody.font = UIFont(name: OxygenRegular, size: 17)
    }

    func setupObservers() {
        self.presenter.isBusy.subscribe(onNext: { [weak self] isBusy in
            self?.continueBtn.isEnabled = !isBusy
            self?.showProgress(isBusy)
            self?.resendCode.isEnabled = !isBusy
        }).disposed(by: disposeBag)
        self.presenter.notification.subscribe(onNext: { [weak self] notification in
            if let inboundNotification = notification, inboundNotification.name.rawValue == OnVerificationCodeNotif {
                self?.handleUserActivityNotification(notification: inboundNotification)
                self?.presenter.clearNotification()
            }
        }).disposed(by: disposeBag)
        self.presenter.authMethod.subscribe(onNext: { [weak self] authMethod in
            guard let self = self else {
                return
            }
            if let authIdentifier = self.presenter.cachedAuthIdentifier() {
                let format = authMethod == .email ?
                        NSLocalizedString("email_verification", comment: "") :
                        NSLocalizedString("sms_verification", comment: "")
                self.instructionsBody.text = String(format: format, authIdentifier)
            } else {
                self.showMessage(
                        title: "Error",
                        message: NSLocalizedString("verification_error_no_email", comment: ""))
                self.navigationController?.popToRootViewController(animated: true)
            }
        }).disposed(by: disposeBag)

        self.resendCode.rx.tap.bind { [weak self] in
            self?.resendCodehandler()
        }.disposed(by: disposeBag)
    }

    func login() {
        if let authIdentifier = presenter.cachedAuthIdentifier(),
           let authMethod = self.presenter.cachedAuthMethod() {
            self.presenter.login(email: authIdentifier) { [weak self] response2 in
                let format = authMethod == .email ?
                        NSLocalizedString("email_verification", comment: "") :
                        NSLocalizedString("sms_verification", comment: "")
                if response2.success {
                    self?.showMessage(
                            title: NSLocalizedString("verification_code_sent", comment: ""),
                            message: String(format: format, authIdentifier)
                    )
                } else if let error = response2.result?.message, !response2.success {
                    self?.showMessage(title: "Error", message: error)
                }
            }
        }
    }

    func showDeleteDeviceError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message)
        let forceUnregister = NSLocalizedString("force unregister device", comment: "")
        alert.addAction(UIAlertAction(title: forceUnregister, style: .destructive) { _ in
            self.verifyCode(true)
        })
        alert.addAction(UIAlertAction(
                title: NSLocalizedString("Cancel", comment: ""),
                style: .default, handler: nil))
        alert.display()
    }

    func saveUser(user: CodeVerificationResponse) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(user.email, forKey: "email")
        userDefaults.set(user.phoneNumber, forKey: "phone")
        userDefaults.set(user.username, forKey: "username")
        userDefaults.set(user.firstName, forKey: "firstName")
        userDefaults.set(user.lastName, forKey: "lastName")
        userDefaults.set(user.picture, forKey: "pictureURL")
        userDefaults.set(user.userState?.selfPerceptionState.rawValue, forKey: "selfPerceptionState")
        userDefaults.synchronize()
    }
    
    func resendCodehandler() {
        guard let authMethod = self.presenter.cachedAuthMethod() else { return }
        guard let authIdentifier = self.presenter.cachedAuthIdentifier() else { return }
        
        let alert = MDCAlertController(
            title: authMethod == .email ?
                NSLocalizedString("send_new_code_confirmation_email", comment: "") :
                NSLocalizedString("send_new_code_confirmation_phone", comment: ""),
                message: authIdentifier
        )
        alert.addAction(MDCAlertAction(
            title: NSLocalizedString("resend_code", comment: ""), emphasis: .high) { [weak self] _ in
            self?.login()
        })
        alert.addAction(MDCAlertAction(
            title: authMethod == .email ?
                NSLocalizedString("send_new_code_change_email", comment: "") :
                NSLocalizedString("send_new_code_change_phone", comment: ""),
            emphasis: .medium) { _ in
            self.navigationController?.popToRootViewController(animated: true)
        })
        alert.addAction(MDCAlertAction(
            title: NSLocalizedString("Cancel", comment: ""), emphasis: .medium) { _ in
            
        })
        alert.mdc_dialogPresentationController?.dismissOnBackgroundTap = false
        self.present(alert, animated: true)
    }

    @IBAction func verifyCodehandler() {
        verifyCode()
    }

    func verifyCode(_ deletePreviousDevice: Bool = false) {
        let code = verificationCode.text ?? ""
        presenter.verifyCode(code: code, deletePreviousDevice: deletePreviousDevice) { [weak self] response in
            if let errorCode = response.httpCode, errorCode == 403 {
                self?.navigationController?.popToRootViewController(animated: true)
            }
            if let user = response.result, response.success {
                self?.saveUser(user: user)
                self?.gotoLocationsController()
                self?.presenter.verifyPendingInvitations()
            } else if let httpCode = response.httpCode,
                      let message = response.getMessage(), httpCode == 402 {
                self?.showDeleteDeviceError(title: "Error", message: message)
            } else if let message = response.getMessage() {
                self?.showMessage(title: "Error", message: message)
            } else {
                self?.showMessage(
                        title: "Error",
                        message: response.getMessage() ?? NSLocalizedString("server_parsing_error", comment: "")
                )
            }
        }
    }

    func gotoLocationsController() {
        self.performSegue(withIdentifier: goToLocationsControllerSegue, sender: nil)
    }
}
