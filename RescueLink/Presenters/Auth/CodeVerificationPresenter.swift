//
//  CodeVerificationPresenter.swift
//  RescueLink
//
//  Created by Dario Lencina on 7/2/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import SwiftKeychainWrapper
import UIKit
import RxSwift

public class CodeVerificationPresenter {

    private let authState = AuthState.instance
    public let isBusy: Observable<Bool>
    public let keyGenerationState = AuthState.instance.keyGenerationState
    public let notification = UIState.instance.notification
    let authMethod: Observable<AuthMethod> = AuthState.instance.authMethod

    struct DeviceInfo {
        let deviceId: String
        let os: String
        let osVersion: String
        let model: String
        let publicKey: String
    }

    init() {
        self.isBusy = Observable
                .combineLatest(AuthState.instance.isVerifyingCode, keyGenerationState).map({ (a, b) -> Bool in
                    a || b == .generating
                })
    }

    func deviceInfo() -> DeviceInfo? {
        let osVersion = UIDevice.current.systemVersion
        let model = UIDevice.modelName
        let deviceId = readDeviceUUIDFromKeychain()

        return RSA().readOrCreateKeys().map {
            DeviceInfo(
                    deviceId: deviceId,
                    os: os,
                    osVersion: osVersion,
                    model: model,
                    publicKey: $0[0].value)
        }
    }

    func verifyCode(
            code: String, deletePreviousDevice: Bool,
            completion: @escaping (ApiResponse<CodeVerificationResponse>) -> Void) {
        guard let deviceInfo = deviceInfo() else {
            completion(ApiResponse(
                    success: false,
                    httpCode: nil,
                    result: CodeVerificationResponse(
                            message: "unable to generate public key",
                            engineeringError: "unable to generate public key",
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

        AuthState.instance.verifyCode(CodeVerificationRequest(
                publicKey: deviceInfo.publicKey,
                code: code,
                deviceId: deviceInfo.deviceId,
                os: deviceInfo.os,
                osVersion: deviceInfo.osVersion,
                model: deviceInfo.model,
                deletePreviousDevice: deletePreviousDevice
        ), completion: completion)
    }

    func cachedAuthIdentifier() -> String? {
        AuthState.instance.cachedAuthIdentifier()
    }
    
    func cachedAuthMethod() -> AuthMethod? {
        AuthState.instance.cachedAuthMethod()
    }

    func clearNotification() {
        UIState.instance.clearNotification()
    }

    func login(email: String, completion: @escaping (ApiResponse<GenericResponse>) -> Void) {
        authState.login(email, completion: completion)
    }
    
    func verifyPendingInvitations() {
        UIApplication.shared.open(URL(string: URLs().pendingInvitations())!, options: [:], completionHandler: nil)
    }
}
