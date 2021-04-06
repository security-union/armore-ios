//
//  UserDefaults.swift
//  RescueLink
//
//  Created by Griffin Obeid on 2/11/21.
//  Copyright © 2021 Security Union. All rights reserved.
//

import Foundation

func saveUserDefaults(user: UserDetails) {
    let userDefaults = UserDefaults.standard
    userDefaults.set(user.email, forKey: "email")
    userDefaults.set(user.phoneNumber, forKey: "phone")
    userDefaults.set(user.username, forKey: "username")
    userDefaults.set(user.firstName, forKey: "firstName")
    userDefaults.set(user.lastName, forKey: "lastName")
    userDefaults.set(user.picture, forKey: "pictureURL")
    userDefaults.set(user.userState?.selfPerceptionState.rawValue, forKey: "selfPerceptionState")
    userDefaults.synchronize()
}
