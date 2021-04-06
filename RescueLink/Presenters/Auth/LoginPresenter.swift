//
//  LoginPresenter.swift
//   Armore
//
//  Created by Security Union on 03/11/19.
//  Copyright © 2019 Security Union. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift
import SwiftKeychainWrapper
import PhoneNumberKit

let keychainVendorIdPath = "rescuelink.vendor.uuid"
let keychainPublicKeyPath = "rescuelink.vendor.keys.public"
let keychainPrivateKeyPath = "rescuelink.vendor.keys.private"
let unableToGenerateSSLKeys = NSLocalizedString("Unable to generate SSL Keys", comment: "")
let loginError = NSLocalizedString("Login Error", comment: "")
let os = "iOS"

/**
            
 Reads the DeviceUUID from the Keychain if present, else it reads the vendor UUID and saves it to the Keychain
 and returns it.
 
 - Author: Dario A Lencina Talarico
 - returns: string with the UUID.
 
 */
func readDeviceUUIDFromKeychain() -> String {
    if let uuid = KeychainWrapper.standard.string(forKey: keychainVendorIdPath) {
        return uuid
    } else {
        let vendorUUID = UIDevice.current.identifierForVendor!.uuidString
        KeychainWrapper.standard.set(vendorUUID, forKey: keychainVendorIdPath)
        return vendorUUID
    }
}

class LoginPresenter: CurrentUser {

    private let urls: URLs
    private let authState = AuthState.instance

    public let email = AuthState.instance.authIdentifier.asObserver()
    public let isBusy: Observable<Bool>
    public let notification = UIState.instance.notification
    public let keyGenerationState = AuthState.instance.keyGenerationState
    public let countryCodeSelected: Observable<CountryCodePickerViewController.Country>
    public let authMethod: Observable<AuthMethod> = AuthState.instance.authMethod
    public let phoneNumberKit: PhoneNumberKit

    init(urls: URLs) {
        self.urls = urls
        isBusy = Observable
                .combineLatest(AuthState.instance.isDoingLogin, AuthState.instance.isCheckingAuthIdentifier)
                .map({ (a, b) -> Bool in
                    a || b
                })
                .debounce(.milliseconds(1), scheduler: MainScheduler.instance)
        let localPhoneKit = PhoneNumberKit()
        phoneNumberKit = localPhoneKit
        countryCodeSelected = AuthState.instance.countryCodeSelected.map { code in
            CountryCodePickerViewController.Country(for: code, with: localPhoneKit)!
        }
    }

    public func login(email: String, completion: @escaping (ApiResponse<GenericResponse>) -> Void) {
        authState.login(email, completion: completion)
    }

    public func checkSession() -> Bool {
        return getToken() != nil
    }

    public func userExists(
            data: String,
            authMethod: AuthMethod,
            completion: @escaping (ApiResponse<UserExistsResult>) -> Void) {
        authState.userExists(authIdentifier: data, authMethod: authMethod, completion: completion)
    }

    public func setCountryCode(code: String) {
        authState.setCountryCode(code)
    }

    public func setAuthMethod(_ method: AuthMethod) {
        authState.setAuthMethod(method)
    }

}
