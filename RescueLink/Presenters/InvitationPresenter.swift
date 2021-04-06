//
//  InvitationPresenter.swift
//   Armore
//
//  Created by Security Union on 14/11/19.
//  Copyright © 2019 Security Union. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift
import PhoneNumberKit
import Contacts
import ContactsUI

enum NewInvitationState {
    case createInvitation
    case shareInvitation(String)
}

enum ExpirationTime: String {
    case oneDay = "1 Day"
    case oneWeek = "1 Week"
    case oneMonth = "1 Month"
}

class InvitationPresenter: CurrentUser {
    private let urls: URLs // Date provider
    private let expirationTime: BehaviorSubject<ExpirationTime> = BehaviorSubject(value: ExpirationTime.oneMonth)
    private let invitationState: BehaviorSubject<NewInvitationState> =
        BehaviorSubject(value: NewInvitationState.createInvitation)
    private let error: BehaviorSubject<String?> = BehaviorSubject(value: nil)
    private let isBusy: BehaviorSubject<Bool> = BehaviorSubject(value: false)

    let req = Request()
    let selectedExpirationTime: Observable<ExpirationTime>
    let currentInvitationState: Observable<NewInvitationState>
    let currentError: Observable<String?>
    let currentisBusy: Observable<Bool>

    init(urls: URLs) {
        self.urls = urls
        self.selectedExpirationTime = expirationTime.asObserver()
        self.currentInvitationState = invitationState.asObserver()
        self.currentError = error.asObservable()
        self.currentisBusy = isBusy.asObservable()
    }

    func setInvitationState(_ invitationState: NewInvitationState) {
        self.invitationState.onNext(invitationState)
    }
    
    func setSelectedExpirationTime(_ expirationTime: ExpirationTime) {
        self.expirationTime.onNext(expirationTime)
    }
    
    func createInvitation() {
        guard let value = try? self.expirationTime.value() else {
            return
        }
        let calendar = Calendar.current
        var secondsToAdd = 0
        switch value {
        case .oneDay:
            secondsToAdd = 60 *  60 * 24
        case .oneMonth:
            secondsToAdd = 60 *  60 * 24 * 30
        case .oneWeek:
            secondsToAdd = 60 *  60 * 24 * 7
        }
        let exp_date = calendar.date(byAdding: .second, value: secondsToAdd, to: Date())!
        let payload = InvitationRequest(expirationDate: exp_date.toStringWithFormat())
        
        isBusy.onNext(true)
        AF.request(urls.createInvitation(),
            method: .post,
            parameters: payload,
            encoder: JSONParameterEncoder.default,
            headers: addBaseHeaders([]))
        .responseJSON { response in
            self.isBusy.onNext(false)
            if let data = response.data,
               let apiResponse = try? JSONDecoder().decode(ApiResponse<InvitationResponse>.self, from: data) {
                if let errorMessage = apiResponse.getMessage(), !apiResponse.success {
                    self.error.onNext(errorMessage)
                } else if let link = apiResponse.result?.link {
                    self.setInvitationState(.shareInvitation(link))
                } else {
                    self.error.onNext(NSLocalizedString("server_parsing_error", comment: ""))
                }
            } else {
                self.error.onNext(NSLocalizedString("server_parsing_error", comment: ""))
            }
        }
    }

}
