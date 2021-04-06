//
//  Request.swift
//  Armore
//
//  Created by Security Union on 03/11/19.
//  Copyright © 2019 Security Union. All rights reserved.
//

import Foundation
import Alamofire
import UIKit

let NO_CONNECTION = NSLocalizedString("No connection to server", comment: "")
let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")

public func addBaseHeaders(_ headers: HTTPHeaders) -> HTTPHeaders {
    var headersCopy = HTTPHeaders(headers.dictionary)
    headersCopy.add(name: "platform", value: "iOS \(UIDevice.current.systemVersion )")
    headersCopy.add(name: "build", value: "\(version ?? "")-\(buildNumber ?? "")")
    headersCopy.add(name: "model", value: UIDevice.modelName)
    headersCopy.add(name: "accept-language", value: Locale.current.languageCode ?? "en")
    if let token = CurrentUser().getToken() {
        headersCopy.add(name: TOKEN_HEADER, value: token)
    }
    return headersCopy
}

public class Request {

    var view = UIViewController()

    public func setViewDelegate(viewDelegate: UIViewController) {
        self.view = viewDelegate
    }

    public func request(url: String,
                        headers: HTTPHeaders,
                        parameters: Parameters?,
                        methodType: HTTPMethod,
                        encoding: ParameterEncoding = URLEncoding.default,
                        completion: @escaping (Bool, [String: Any], Int?) -> Void) {
        AF.request(url,
                method: methodType,
                parameters: parameters,
                encoding: encoding,
                headers: addBaseHeaders(headers)).responseJSON { response in
            var values: [String: Any]?
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                values = utf8Text.convertToDictionary()
            }
            let success = values?["success"] as? Bool ?? false
            switch response.result { // switch checks with the validate fields on the sent request
            case .success:
                // Check if the result has something
                if let hasResult = values?["result"] as? [String: Any] {
                    completion(success, hasResult, response.response?.statusCode)
                } else {
                    completion(success, [:], response.response?.statusCode)
                }

            case .failure:
                // jwt expired, send the user to sign in again
                if let statusCode = response.response?.statusCode, statusCode == 403 {
                    UIState.instance.jwtExpired()
                    completion(success, ["message": ERROR_403], response.response?.statusCode)
                } else if let valuesResult = values?["result"] as? [String: Any] {
                    completion(success, valuesResult, response.response?.statusCode)
                } else {
                    completion(success, ["message": NO_CONNECTION], nil)
                }
            }
        }
    }

    public func requestChangeResponse(url: String,
                                      headers: HTTPHeaders,
                                      parameters: [String: Any],
                                      methodType: HTTPMethod,
                                      encoding: ParameterEncoding = URLEncoding(boolEncoding: .literal),
                                      completion: @escaping (Response) -> Void) {
        AF.request(url,
                method: methodType,
                parameters: parameters,
                encoding: encoding,
                headers: addBaseHeaders(headers)).responseJSON { response in
            var values: [String: Any]?
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                values = utf8Text.convertToDictionary()
            }

            let statusCode = response.response?.statusCode ?? 0

            switch response.result { // switch checks with the validate fields on the sent request
            case .success:
                // Check if the result has something
                if let hasResult = values?["result"] as? [String: Any] {
                    completion(Response(success: true, response: hasResult))
                } else if let hasResult = values?["result"] as? [[String: Any]] {
                    completion(Response(success: true, responseArray: hasResult))
                } else {
                    completion(Response(success: true, response: [:]))
                }

            case .failure:
                // jwt expired, send the user to sign in again
                if statusCode == 403 {
                    print("The JWT token expired, send the user to sign in again.")
                    UIState.instance.jwtExpired()
                    completion(Response(success: false, errorMessage: ERROR_403, responseCode: statusCode))
                } else if let message = values?["result"] as? [String: Any] {
                    completion(Response(success: false,
                            errorMessage: message["message"] as? String ?? "Unknown Error",
                            responseCode: statusCode))
                } else {
                    completion(Response(success: false, errorMessage: NO_CONNECTION, responseCode: statusCode))
                }
            }
        }
    }

    public func requestImage(url: String,
                             headers: HTTPHeaders,
                             parameters: [String: Any],
                             methodType: HTTPMethod,
                             completion: @escaping (Response) -> Void) {
        // changed on encoding, from .httpBody to .default
        AF.request(url,
                method: methodType,
                parameters: parameters,
                encoding: URLEncoding.default,
                headers: addBaseHeaders(headers)).responseJSON { response in
            var values: [String: Any]?
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                values = utf8Text.convertToDictionary()
            }

            // check the response
            if response.response?.statusCode == 200 {
                if let data = response.data, let image = UIImage(data: data) {
                    // the image file was downloaded successfully
                    completion(Response(success: true, oneReturned: image))
                } else {
                    completion(Response(success: false,
                            errorMessage: NSLocalizedString("Unable to parse image",
                                    comment: "")))
                }
            } else {
                if let message = values?["result"] as? [String: Any] {
                    completion(Response(success: false, errorMessage: message["message"] as? String ?? "Unknown Error"))
                } else {
                    completion(Response(success: false, errorMessage: NO_CONNECTION))
                }
            }
        }
    }

}
