//
//   ArmoreCrypto.swift
//  Armore
//
//  Created by Security Union on 24/04/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation
import SwiftKeychainWrapper
import Alamofire

struct Crypto {

    private static func usernameKey(_ username: String) -> String {
        return "\(username)Key"
    }

    public static func encryptLocation(location: Location, with recipientUsername: String) -> NSData? {
        let defaults = UserDefaults.standard
        if let publicKey = defaults.string(forKey: usernameKey(recipientUsername)),
           let json = try? JSONEncoder().encode(location),
           let jsonString = String(data: json, encoding: .utf8) {
            return RSA().encrypt(with: publicKey, message: jsonString)
        }
        return nil
    }

    public static func encryptLocationForCurrentUser(_ location: Location) -> NSData? {
        if let publicKey = KeychainWrapper.standard.string(forKey: keychainPublicKeyPath),
           let json = try? JSONEncoder().encode(location),
           let jsonString = String(data: json, encoding: .utf8) {
            return RSA().encrypt(with: publicKey, message: jsonString)
        }
        return nil
    }

    public static func decryptLocation(_ data: String) -> Location? {
        if let keys = RSA().readOrCreateKeys(),
           let dataToDecrypt = Data(base64Encoded: data, options: .ignoreUnknownCharacters),
           let decryptedData = RSA().decrypt(with: keys[1].value, message: dataToDecrypt as CFData) {
            let location = try? JSONDecoder().decode(Location.self, from: decryptedData)
            return location
        }
        return nil
    }

    static func saveUsersPublicKey(_ publicKey: String, for username: String) -> Bool {
        let defaults = UserDefaults.standard
        let existingKey = defaults.string(forKey: usernameKey(username))
        let newFriends = existingKey == nil
        defaults.set(publicKey, forKey: usernameKey(username))
        var followersUsernames: [String] = []
        // check is the user is on the followers usernames to send location
        if let arrayFollowers = defaults.stringArray(forKey: FOLLOWERS_USERNAMES) {
            followersUsernames = arrayFollowers
            if !followersUsernames.contains(username) {
                followersUsernames.append(username)
            }
        } else {
            // create and save array
            followersUsernames.append(username)
        }
        defaults.set(followersUsernames, forKey: FOLLOWERS_USERNAMES)
        return newFriends
    }
}
