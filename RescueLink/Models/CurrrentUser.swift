//
//  CurrrentUser.swift
//  RescueLink
//
//  Created by Dario Lencina on 7/2/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Firebase
import Foundation
import Alamofire
import SwiftJWT

let pictureURL = "pictureURL"

class CurrentUser: ImageProfile {

    func getToken() -> String? {
        guard let privateKeyString = RSA().getPrivateKey() else {
            return nil
        }
        guard let privateKeyDate = privateKeyString.data(using: .ascii) else {
            return nil
        }
        let jwtSigner = JWTSigner.rs512(privateKey: privateKeyDate)

        guard let userInfo = self.getUserInfo() else {
            return nil
        }

        let deviceId = readDeviceUUIDFromKeychain()

        let claims = MyClaims2(
                exp: Int(Date().addingTimeInterval(60 * 60 * 24).timeIntervalSince1970),
                username: userInfo.username,
                deviceId: deviceId)
        var myJWT = JWT(claims: claims)
        return try? myJWT.sign(using: jwtSigner)
    }

    func getUserInfo() -> User? {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            // Code only executes when tests are running
            let user = User(username: "Test",
                    email: "TestEmail",
                    firstName: "Test first name",
                    lastName: "Test last name",
                    pictureURL: "test picture url")
            return user
        } else {
            let userDefaults = UserDefaults.standard
            guard let username = userDefaults.string(forKey: "username") else {
                return nil
            }
            guard let selfPerceptionState = userDefaults.string(forKey: "selfPerceptionState") else {
                return nil
            }
            let user = User(
                username: username,
                state: UserState(
                    selfPerceptionState: UserState().castStringToPerceptionState(str: selfPerceptionState ),
                    followersPerception: []
                ),
                email: userDefaults.string(forKey: "email") ?? "",
                phone: userDefaults.string(forKey: "phone") ?? "",
                firstName: userDefaults.string(forKey: "firstName") ?? "",
                lastName: userDefaults.string(forKey: "lastName") ?? "",
                pictureURL: userDefaults.string(forKey: pictureURL) ?? ""
            )
            return user
        }
    }

    func saveUserImageName(_ picture: String) {
        if isSessionActive() {
            let userDefaults = UserDefaults.standard
            userDefaults.set(picture, forKey: pictureURL)
            userDefaults.synchronize()
        }
    }

    func getUserState(completion: @escaping (Response) -> Void) {
        let parameters: [String: Any] = [:]
        let req = Request()
        req.requestChangeResponse(url: URLs().me(),
                headers: [],
                parameters: parameters,
                methodType: .get) { (response) in
            if response.success {
                if let uSFromResponse = response.response["userState"] as? [String: Any] {
                    var userState = UserState()
                    userState.selfPerceptionState = userState.castStringToPerceptionState(
                            str: (uSFromResponse["selfPerceptionState"] as? String) ?? "")
                    UserDefaults.standard.set(userState.selfPerceptionState.rawValue, forKey: "selfPerceptionState")
                    if let followersPerceptionResponse = uSFromResponse["followersPerception"] as? [[String: Any]] {
                        followersPerceptionResponse.forEach {
                            let perception = userState
                                    .castStringToPerceptionState(str: ($0["perception"] as? String) ?? "")
                            userState.followersPerception.append(
                                    FollowersPerception(perception: perception,
                                            username: ($0["username"] as? String) ?? ""))
                        }
                    }
                    completion(Response(success: true, oneReturned: userState))
                } else {
                    completion(Response(success: false, oneReturned: UserState()))
                }
            }
        }
    }

    func logoutUser() {
        _ = RSA().deleteKeys()
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        UIState.instance.resetState()
        LocationPusher.instance.stop()
    }

    func isSessionActive() -> Bool {
        if let username = CurrentUser().getUserInfo()?.username {
            Crashlytics.crashlytics().setUserID(username)
        }
        return getToken() != nil
    }
}
