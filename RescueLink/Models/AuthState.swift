//
//  AuthState.swift
//  RescueLink
//
//  Created by Dario Lencina on 7/2/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire
import Firebase
import SwiftKeychainWrapper
import PhoneNumberKit
import FBSDKCoreKit

let getUsernameFromEmail = #"^([a-z\d._%-]+)"#

let internalError = GenericResponse(
        message: NSLocalizedString("server_parsing_error", comment: ""),
        engineeringError: NSLocalizedString("server_parsing_error", comment: "")
)

public enum KeyGenerationState {
    case idle
    case notGenerated
    case generating
    case generated
}

public enum AuthMethod {
    case sms
    case email
}

class AuthState {

    static let instance = AuthState()
    private let urls: URLs = URLs()
    private let req = Request()
    let isCheckingAuthIdentifier: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    let isDoingLogin: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    let isRegistering: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    let isVerifyingCode: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    let error: BehaviorSubject<(String, Int)?> = BehaviorSubject(value: nil)
    // Can be email or phone number.
    let authIdentifier: BehaviorSubject<String?> = BehaviorSubject(value: nil)
    let keyGenerationState: Observable<KeyGenerationState>
    let countryCodeSelected: Observable<String>
    let authMethod: Observable<AuthMethod>

    private let internalCountryCodeSelected: BehaviorSubject<String> =
            BehaviorSubject(value: UIState.defaultRegionCode())
    private let privKeyGenerationState: BehaviorSubject<KeyGenerationState> = BehaviorSubject(
            value: KeychainWrapper.standard.string(forKey: keychainPublicKeyPath) != nil ? .generated : .idle
    )
    private let privAuthMethod = BehaviorSubject(value: AuthMethod.sms)

    private init() {
        keyGenerationState = privKeyGenerationState.asObserver()
        countryCodeSelected = internalCountryCodeSelected.asObserver()
        authMethod = privAuthMethod.asObserver()
    }

    func setAuthMethod(_ method: AuthMethod) {
        privAuthMethod.onNext(method)
    }

    func setAuthIdentifier(_ email: String) {
        self.authIdentifier.onNext(email)
    }

    func cachedAuthIdentifier() -> String? {
        try? self.authIdentifier.value()
    }
    
    func cachedAuthMethod() -> AuthMethod? {
        try? privAuthMethod.value()
    }

    func setCountryCode(_ code: String) {
        self.internalCountryCodeSelected.onNext(code)
    }

    func register(firstName: String,
                  lastName: String,
                  completion: @escaping (ApiResponse<GenericResponse>) -> Void) {
        self.isRegistering.onNext(true)
        self.privKeyGenerationState.onNext(.generating)
        DispatchQueue.global(qos: .background).async {
            _ = RSA().deleteKeys()
            guard let publicKey = (RSA().readOrCreateKeys().map {
                $0[0].value
            }) else {
                DispatchQueue.main.async {
                    completion(ApiResponse<GenericResponse>(success: false, httpCode: nil, result: internalError))
                    self.privKeyGenerationState.onNext(.notGenerated)
                    self.isRegistering.onNext(false)
                }
                return
            }
            DispatchQueue.main.async {
                self.privKeyGenerationState.onNext(.generated)
                guard let authIdentifier = try? self.authIdentifier.value() else {
                    completion(ApiResponse<GenericResponse>(success: false, httpCode: nil, result: internalError))
                    self.isRegistering.onNext(false)
                    return
                }
                guard let authMethod = (try? self.privAuthMethod.value()) else {
                    completion(ApiResponse<GenericResponse>(success: false, httpCode: nil, result: internalError))
                    self.isRegistering.onNext(false)
                    return
                }
                guard let username = self.createUsername(
                        authIdentifier, firstName: firstName, lastName: lastName) else {
                    completion(ApiResponse<GenericResponse>(success: false, httpCode: nil, result: internalError))
                    self.isRegistering.onNext(false)
                    return
                }
                let registrationRequest = RegistrationRequest(
                        email: authMethod == .email ? authIdentifier : nil,
                        phoneNumber: authMethod == .sms ? authIdentifier : nil,
                        firstName: firstName,
                        lastName: lastName,
                        publicKey: publicKey,
                        username: String(username))
                AF.request(self.urls.register(),
                                method: .post,
                                parameters: registrationRequest,
                                encoder: JSONParameterEncoder.default,
                                headers: addBaseHeaders([]))
                        .responseJSON { [weak self] response in
                            self?.isRegistering.onNext(false)
                            if let data = response.data,
                               let apiResponse = try? JSONDecoder()
                                       .decode(ApiResponse<GenericResponse>.self, from: data) {
                                if apiResponse.success {
                                    AppEvents.logEvent(.completedRegistration, parameters: [
                                        AppEvents.ParameterName.registrationMethod.rawValue: "mobile"
                                    ])
                                }
                                completion(apiResponse)
                            } else {
                                completion(ApiResponse<GenericResponse>(
                                        success: false,
                                        httpCode: response.response?.statusCode,
                                        result: internalError
                                ))
                            }
                        }
            }
        }
    }

    func createUsername(_ data: String, firstName: String, lastName: String) -> String? {
        (try? privAuthMethod.value()).flatMap {
            switch $0 {
            case .email:
                return (data.range(
                        of: getUsernameFromEmail,
                        options: .regularExpression).map {
                    "\(data[$0])@\(UUID.init().uuidString)"
                })
            default:
                let first = firstName.replacingOccurrences(of: " ", with: "")
                let last = lastName.replacingOccurrences(of: " ", with: "")
                return "\(first)\(last)@\(UUID.init().uuidString)"
            }
        }
    }

    func login(_ authIdentifier: String,
               completion: @escaping (ApiResponse<GenericResponse>) -> Void) {
        isDoingLogin.onNext(true)
        privKeyGenerationState.onNext(.generating)
        DispatchQueue.global(qos: .background).async {
            _ = RSA().deleteKeys()
            guard let publicKey = (RSA().readOrCreateKeys().map {
                $0[0].value
            }) else {
                DispatchQueue.main.async {
                    completion(ApiResponse(
                            success: false,
                            httpCode: nil,
                            result: GenericResponse(message: "unable to generate public key",
                                    engineeringError: "unable to generate public key")
                    ))
                    self.privKeyGenerationState.onNext(.notGenerated)
                    self.isDoingLogin.onNext(false)
                }
                return
            }
            DispatchQueue.main.async {
                self.privKeyGenerationState.onNext(.generated)
                guard let authMethod = (try? self.privAuthMethod.value()) else {
                    completion(ApiResponse<GenericResponse>(success: false, httpCode: nil, result: internalError))
                    self.isRegistering.onNext(false)
                    return
                }
                let loginRequest = LoginRequest(
                        email: authMethod == .email ? authIdentifier : nil,
                        phoneNumber: authMethod == .sms ? authIdentifier : nil,
                        publicKey: publicKey
                )
                AF.request(self.urls.login(),
                                method: .post,
                                parameters: loginRequest,
                                encoder: JSONParameterEncoder.default,
                                headers: addBaseHeaders([]))
                        .responseJSON { [weak self] response in
                            self?.isDoingLogin.onNext(false)
                            if let data = response.data,
                               let apiResponse = try? JSONDecoder()
                                       .decode(ApiResponse<GenericResponse>.self, from: data) {
                                completion(apiResponse)
                            } else {
                                completion(ApiResponse<GenericResponse>(
                                        success: false,
                                        httpCode: response.response?.statusCode,
                                        result: GenericResponse(
                                                message: NSLocalizedString("server_parsing_error", comment: ""),
                                                engineeringError: NSLocalizedString("server_parsing_error", comment: "")
                                        )
                                ))
                            }
                        }
            }
        }
    }

    func verifyCode(_ codeVerification: CodeVerificationRequest,
                    completion: @escaping (ApiResponse<CodeVerificationResponse>) -> Void) {
        guard let emailOrPhoneNumber = try? self.authIdentifier.value() else {
            completion(ApiResponse(success: false,
                    httpCode: 403,
                    result: CodeVerificationResponse(
                            message: NSLocalizedString("verification_error_no_email", comment: ""),
                            engineeringError: NSLocalizedString("verification_error_no_email", comment: ""),
                            username: nil,
                            email: nil,
                            phoneNumber: nil,
                            firstName: nil,
                            lastName: nil,
                            picture: nil,
                            userState: nil
                    )
            ))
            return
        }
        isVerifyingCode.onNext(true)
        AF.request(urls.codeVerification(email: emailOrPhoneNumber),
                        method: .post,
                        parameters: codeVerification,
                        encoder: JSONParameterEncoder.default,
                        headers: addBaseHeaders([]))
                .responseJSON { [weak self] response in
                    self?.isVerifyingCode.onNext(false)
                    if let data = response.data,
                       var apiResponse = try? JSONDecoder()
                               .decode(ApiResponse<CodeVerificationResponse>.self, from: data) {
                        apiResponse.httpCode = response.response?.statusCode
                        completion(apiResponse)
                    } else {
                        completion(ApiResponse<CodeVerificationResponse>(
                                success: false,
                                httpCode: response.response?.statusCode,
                                result: CodeVerificationResponse(
                                        message: NSLocalizedString("server_parsing_error", comment: ""),
                                        engineeringError: NSLocalizedString("server_parsing_error", comment: ""),
                                        username: nil,
                                        email: nil,
                                        phoneNumber: nil,
                                        firstName: nil,
                                        lastName: nil,
                                        picture: nil,
                                        userState: nil
                                )
                        ))
                    }
                }
    }

    func userExists(
            authIdentifier: String,
            authMethod: AuthMethod,
            completion: @escaping (ApiResponse<UserExistsResult>) -> Void) {
        self.setAuthIdentifier(authIdentifier)
        isCheckingAuthIdentifier.onNext(true)
        let url = urls.userExists(email: authIdentifier, authMethod: authMethod)
        AF.request(url, method: .get, parameters: [:], headers: addBaseHeaders([]))
                .responseJSON { [weak self] response in
                    self?.isCheckingAuthIdentifier.onNext(false)
                    if let data = response.data,
                       let apiResponse = try? JSONDecoder().decode(ApiResponse<UserExistsResult>.self, from: data) {
                        completion(apiResponse)
                    } else {
                        completion(ApiResponse<UserExistsResult>(
                                success: false,
                                httpCode: response.response?.statusCode,
                                result: UserExistsResult(
                                        exists: nil,
                                        message: NSLocalizedString("server_parsing_error", comment: ""),
                                        engineeringError: NSLocalizedString("server_parsing_error", comment: "")
                                )
                        ))
                    }
                }
    }
}
