//
//  LocationsPresenter.swift
//   Armore
//
//  Created by Security Union on 06/11/19.
//  Copyright © 2019 Security Union. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift

let DECRYPTION_ERROR = "DECRYPTION_ERROR"
let TELEMETRY_PARSING_ERROR = "TELEMETRY_PARSING_ERROR"

class LocationsPresenter: CurrentUser {

    private let urls: URLs // Data provider
    let req = Request()
    private var activity: CoolActivityIndicator?
    var refreshState: BehaviorSubject<RefreshState> = LocationPusher.instance.refreshState
    var friends: BehaviorSubject<ApiResponse<Connections>?> = LocationPusher.instance.connections
    var selectedUser: Observable<DetailTable?> = UIState.instance.selectedUser
    var seeHistoricalLocation: BehaviorSubject<Friend?> = UIState.instance.seeHistoricalLocation
    var changeAccessType: BehaviorSubject<Friend?> = UIState.instance.changeAccessType
    var friendsTableState: BehaviorSubject<FriendsTableState> = UIState.instance.friendsTableState
    var error: Observable<(String, Int)?> = UIState.instance.error
    var isLowPowerModeEnabled: BehaviorSubject<Bool> = UIState.instance.isLowPowerModeEnabled
    var notification: BehaviorSubject<Notification?> = UIState.instance.notification

    init(urls: URLs) {
        self.urls = urls
    }
    
    func acceptInvitation(_ id: String, completion: @escaping (ApiResponse<AcceptInvitationResponse>) -> Void) {
        let url = urls.acceptInvitation(withId: id)
        let requestParameters = [String: Any]()
        AF.request(url,
                        method: .post,
                        parameters: requestParameters,
                        encoding: URLEncoding.default,
                        headers: addBaseHeaders([]))
                .responseJSON { response in
                    if let data = response.data,
                       let apiResponse =
                        try? JSONDecoder().decode(ApiResponse<AcceptInvitationResponse>.self, from: data) {
                        completion(apiResponse)
                    } else {
                        let res = AcceptInvitationResponse(
                            message: NSLocalizedString("server_parsing_error", comment: ""),
                            engineeringError: NSLocalizedString("server_parsing_error", comment: ""),
                            publicKey: nil, username: nil)
                        completion(ApiResponse<AcceptInvitationResponse>(
                                success: false,
                                httpCode: response.response?.statusCode,
                                result: res
                        ))
                    }
                }
    }
    
    func rejectInvitation(_ id: String, completion: @escaping (ApiResponse<InvitationResponse>) -> Void) {
        let url = urls.rejectInvitation(withId: id)
        let requestParameters = [String: Any]()
        AF.request(url,
                        method: .post,
                        parameters: requestParameters,
                        encoding: URLEncoding.default,
                        headers: addBaseHeaders([]))
                .responseJSON { response in
                    if let data = response.data,
                       let apiResponse = try? JSONDecoder().decode(ApiResponse<InvitationResponse>.self, from: data) {
                        completion(apiResponse)
                    } else {
                        let res = InvitationResponse(
                            message: NSLocalizedString("server_parsing_error", comment: ""),
                            engineeringError: NSLocalizedString("server_parsing_error", comment: ""),
                            link: nil)
                        completion(ApiResponse<InvitationResponse>(
                                success: false,
                                httpCode: response.response?.statusCode,
                                result: res
                        ))
                    }
                }
    }
    
    func getInvitationDetails(
        _ id: String,
        completion: @escaping (ApiResponse<GetInvitationDetailsResponse>) -> Void) {
        let requestParameters = [String: Any]()
        AF.request(urls.getInvitationDetails(id),
                        method: .get,
                        parameters: requestParameters,
                        encoding: URLEncoding.default,
                        headers: addBaseHeaders([]))
                .responseJSON { response in
                    if let data = response.data,
                       let apiResponse = try? JSONDecoder().decode(
                        ApiResponse<GetInvitationDetailsResponse>.self,
                        from: data
                       ) {
                        completion(apiResponse)
                    } else {
                        let res = GetInvitationDetailsResponse(
                            message: NSLocalizedString("server_parsing_error", comment: ""),
                            engineeringError: NSLocalizedString("server_parsing_error", comment: ""),
                            firstName: nil,
                            lastName: nil)
                        completion(ApiResponse<GetInvitationDetailsResponse>(
                                success: false,
                                httpCode: response.response?.statusCode,
                                result: res
                        ))
                    }
                }
    }
    
    func getMe(
        completion: @escaping (ApiResponse<UserDetails>) -> Void
    ) {
        AF.request(
            urls.me(),
            method: .get,
            encoding: URLEncoding.default,
            headers: addBaseHeaders([])
        ).responseJSON { response in
            if let data = response.data,
               let apiResponse = try? JSONDecoder().decode(ApiResponse<UserDetails>.self, from: data) {
                completion(apiResponse)
            } else {
                completion(
                    ApiResponse<UserDetails>(
                        success: false,
                        httpCode: response.response?.statusCode,
                        result: nil
                    )
                )
            }
        }
    }

    func clearError() {
        UIState.instance.clearError()
    }

    func toggleFriendsTableState() {
        UIState.instance.toggleTableState()
    }

    func startTrackingLocation() {
        LocationPusher.instance.startTracking()
    }

    func forcePushingLocation() {
        LocationPusher.instance.forcePushLocation()
    }

    func clearNotification() {
        UIState.instance.clearNotification()
    }

    func setFriendsTableState(_ state: FriendsTableState) {
        UIState.instance.setFriendsTableState(state)
    }

    func setSelectedUser(_ username: String?) {
        UIState.instance.setSelectedUser(username)
    }

    func checkIfStateChanged() {
        CurrentUser().getUserState { (response) in
            if response.success, let userState = response.oneReturned as? UserState {
                // check the user state
                if userState.selfPerceptionState == .Emergency {
                } else if userState.selfPerceptionState == .Normal {
                }
            }
        }
    }

    public func quitEmergencyState(
        completion: @escaping (ApiResponse<SetStateResponse>) -> Void
    ) {
        activity?.startAnimating()
        let body = SetStateRequest(new_state: .Normal)
        AF.request(
            URLs().setState(),
            method: .post,
            parameters: body,
            encoder: JSONParameterEncoder.default,
            headers: addBaseHeaders([])
        ).responseJSON { response in
            if let data = response.data,
               let apiResponse = try? JSONDecoder().decode(ApiResponse<SetStateResponse>.self, from: data) {
                completion(apiResponse)
            } else {
                completion(
                    ApiResponse<SetStateResponse>(
                        success: false,
                        httpCode: response.response?.statusCode,
                        result: nil
                    )
                )
            }
        }
        activity?.stopAnimating()
    }
}
