//
//  EmercencyCounterPresenter.swift
//   Armore
//
//  Created by Security Union on 20/03/20.
//  Copyright © 2021 Security Union. All rights reserved.
//

import Foundation
import Alamofire

struct SetStateRequest: Encodable, Decodable, Equatable {
    var new_state: PerceptionState
}

struct SetStateResponse: WithMessage {
    let message: String // Message contains the state
    let engineeringError: String?

    func getMessage() -> String? {
        message
    }

    func getEngineeringError() -> String? {
        engineeringError
    }
}

class EmergencyCounterPresenter: CurrentUser {
    weak private var emergencyCounterViewDelegate: EmergencyCounterController?
    private var activity: CoolActivityIndicator?

    func setViewDelegate(emergencyCounterController: EmergencyCounterController) {
        self.activity = CoolActivityIndicator(currentController: emergencyCounterController)
        self.emergencyCounterViewDelegate = emergencyCounterController
    }
    
    func completion(_ res: ApiResponse<SetStateResponse>) {
        if res.success {
            // the user is now on emergency state
            self.emergencyCounterViewDelegate?.nowOnEmergencyState()
            let userDefaults = UserDefaults.standard
            userDefaults.set(PerceptionState.Emergency.rawValue, forKey: "selfPerceptionState")
            userDefaults.synchronize()
        } else {
            // error
            self.emergencyCounterViewDelegate?.showError(
                title: "Error setting state",
                message: res.getMessage() ?? NO_CONNECTION
            )
        }
    }

    public func setEmergencyState(state: SetStateRequest) {
        activity?.startAnimating()
        AF.request(
            URLs().setState(),
            method: .post,
            parameters: state,
            encoder: JSONParameterEncoder.default,
            headers: addBaseHeaders([])
        ).responseJSON { res in
            if let data = res.data,
               var apiResponse = try? JSONDecoder().decode(ApiResponse<SetStateResponse>.self, from: data) {
                apiResponse.httpCode = res.response?.statusCode
                self.completion(apiResponse)
            } else {
                self.completion(ApiResponse<SetStateResponse>(
                        success: false,
                        httpCode: res.response?.statusCode,
                        result: SetStateResponse(
                                message: NSLocalizedString("server_parsing_error", comment: ""),
                                engineeringError: NSLocalizedString("server_parsing_error", comment: "")
                        )
                ))
            }
        }
        self.activity?.stopAnimating()
    }
}
