//
//  PhoneNumberPicker.swift
//  RescueLink
//
//  Created by Dario Lencina on 11/3/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation
import UIKit
import MaterialComponents
import RxSwift
import PhoneNumberKit

class PhoneNumberPicker: UIView {

    @IBOutlet var countryCode: UILabel!
    @IBOutlet var countryName: UILabel!
    @IBOutlet var phoneNumber: MDCTextField!
    let phoneNumberKit = PhoneNumberKit()
    var phoneNumberController: MDCTextInputControllerUnderline!

    let onCountryNameTapped: BehaviorSubject<UIGestureRecognizer?> = BehaviorSubject(value: nil)
    let onCountryCodeTapped: BehaviorSubject<UIGestureRecognizer?> = BehaviorSubject(value: nil)

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        let containerScheme = MDCContainerScheme()
        containerScheme.colorScheme.primaryColor = UIColor.white
        containerScheme.colorScheme.primaryColor = UIColor.white
        containerScheme.colorScheme.primaryColorVariant = UIColor.white
        containerScheme.colorScheme.secondaryColor = UIColor.white
        containerScheme.colorScheme.errorColor = UIColor.white
        containerScheme.colorScheme.surfaceColor = UIColor.white
        containerScheme.colorScheme.backgroundColor = UIColor.white
        containerScheme.colorScheme.onPrimaryColor = UIColor.white
        containerScheme.colorScheme.onSecondaryColor = UIColor.white
        containerScheme.colorScheme.onSurfaceColor = UIColor.white
        containerScheme.colorScheme.onBackgroundColor = UIColor.white
        containerScheme.colorScheme.elevationOverlayColor = UIColor.white
        fromNib()
        countryName.addBottomStroke()
        countryCode.addBottomStroke()
        countryName.contentMode = .bottom
        countryName.contentMode = .bottom
        countryName.isUserInteractionEnabled = true
        countryName.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(countryNameTapped)))
        countryCode.isUserInteractionEnabled = true
        countryCode.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(countryCodeTapped)))
        phoneNumber.textColor = UIColor.white

        phoneNumber.font = UIFont(name: OxygenBold, size: 24)
        countryCode.font = UIFont(name: OxygenBold, size: 24)
        countryName.font = UIFont(name: OxygenBold, size: 24)
        phoneNumber.tintColor = UIColor.white
        phoneNumber.minimumFontSize = 20
        countryCode.textColor = UIColor.white
        countryName.textColor = UIColor.white
        phoneNumber.clearButton.tintColor = UIColor.white
        phoneNumber.sizeToFit()
        countryCode.sizeToFit()
        countryName.sizeToFit()

        phoneNumber.leadingUnderlineLabel.textColor = UIColor.white
        phoneNumberController = MDCTextInputControllerUnderline(textInput: phoneNumber)
        phoneNumberController.applyTheme(withScheme: containerScheme)
    }

    @objc func countryNameTapped(sender: UIGestureRecognizer) {
        onCountryNameTapped.onNext(sender)
        onCountryNameTapped.onNext(nil)
    }

    @objc func countryCodeTapped(sender: UIGestureRecognizer) {
        onCountryCodeTapped.onNext(sender)
        onCountryCodeTapped.onNext(nil)
    }

    func setPhoneNumber(_ wrappedPhoneNumber: PhoneNumber?) {
        guard let newPhoneNumber = wrappedPhoneNumber else {
            return
        }

        countryCode.text = "+\(String(newPhoneNumber.countryCode))"
        countryName.text = newPhoneNumber.regionID.flatMap {
            (Locale.current as NSLocale)
                    .localizedString(forCountryCode: String($0))
        }
        phoneNumber.text = String(newPhoneNumber.nationalNumber)
    }

    func phoneString() -> String? {
        switch (countryCode.text, phoneNumber.text) {
        case (.some(let code), .some(let number)):
            return "\(code)\(number)".trimmingCharacters(in: .whitespaces)
        default:
            return nil
        }
    }
}
