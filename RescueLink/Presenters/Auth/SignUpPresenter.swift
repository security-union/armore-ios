//
//  SignUpPresenter.swift
//  RescueLink
//
//  Created by Dario Lencina on 7/2/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation
import RxSwift

class SignUpPresenter {

    public let isBusy: Observable<Bool>
    public let email = AuthState.instance.authIdentifier
    public let keyGenerationState = AuthState.instance.keyGenerationState

    init() {
        isBusy = AuthState.instance.isRegistering
                .debounce(.milliseconds(1), scheduler: MainScheduler.instance)
    }

    func register(
            firstName: String,
            lastName: String,
            completion: @escaping (ApiResponse<GenericResponse>) -> Void
    ) {
        AuthState.instance.register(
                firstName: firstName,
                lastName: lastName) { response in
            completion(response)
        }
    }

}
