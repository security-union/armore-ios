//
//  RSA.swift
//   Armore
//
//  Created by Security Union on 21/04/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation
import SwiftKeychainWrapper
import FirebaseCrashlytics

class RSA {

    private let bitStringIdentifier: UInt8 = 0x03
    private let sequenceIdentifier: UInt8 = 0x30
    private let algorithmIdentifierForRSAEncryption: [UInt8] = [0x30, 0x0d, 0x06,
                                                                0x09, 0x2a, 0x86,
                                                                0x48, 0x86, 0xf7,
                                                                0x0d, 0x01, 0x01,
                                                                0x01, 0x05, 0x00]

    private func lengthField(of valueField: [UInt8]) -> [UInt8] {
        var length = valueField.count
        if length < 128 {
            return [UInt8(length)]
        }
        // Number of bytes needed to encode the length
        let lengthBytesCount = Int((log2(Double(length)) / 8) + 1)
        // First byte encodes the number of remaining bytes in this field
        let firstLengthFieldByte = UInt8(128 + lengthBytesCount)
        var lengthField: [UInt8] = []
        for _ in 0..<lengthBytesCount {
            // Take the last 8 bits of length
            let lengthByte = UInt8(length & 0xff)
            // Insert them at the beginning of the array
            lengthField.insert(lengthByte, at: 0)
            // Delete the last 8 bits of length
            length = length >> 8
        }
        // Insert firstLengthFieldByte at the beginning of the array
        lengthField.insert(firstLengthFieldByte, at: 0)
        return lengthField
    }

    func convertToX509EncodedKey(_ rsaPublicKeyData: Data) -> Data {
        var derEncodedKeyBytes = [UInt8](rsaPublicKeyData)
        // Insert ASN.1 BIT STRING bytes at the beginning of the array
        derEncodedKeyBytes.insert(0x00, at: 0)
        derEncodedKeyBytes.insert(contentsOf: lengthField(of: derEncodedKeyBytes), at: 0)
        derEncodedKeyBytes.insert(bitStringIdentifier, at: 0)
        // Insert ASN.1 AlgorithmIdentifier bytes at the beginning of the array
        derEncodedKeyBytes.insert(contentsOf: algorithmIdentifierForRSAEncryption, at: 0)
        // Insert ASN.1 SEQUENCE bytes at the beginning of the array
        derEncodedKeyBytes.insert(contentsOf: lengthField(of: derEncodedKeyBytes), at: 0)
        derEncodedKeyBytes.insert(sequenceIdentifier, at: 0)
        return Data(derEncodedKeyBytes)
    }

    func deleteKeys() -> Bool {
        KeychainWrapper.standard.removeObject(forKey: keychainPrivateKeyPath) &&
        KeychainWrapper.standard.removeObject(forKey: keychainPublicKeyPath)
    }

    private func createKeyPair() -> KeyValuePairs<String, String> {
        var publicKey: SecKey?
        var privateKey: SecKey?
        let publicKeyAttr: [NSObject: NSObject] = [
            kSecAttrIsPermanent: false as NSObject,
            kSecAttrApplicationTag: "com.armore.public".data(using: String.Encoding.utf8)! as NSObject,
            kSecClass: kSecClassKey,
            kSecReturnData: kCFBooleanTrue]
        let privateKeyAttr: [NSObject: NSObject] = [
            kSecAttrIsPermanent: false as NSObject,
            kSecAttrApplicationTag: "com.armore.private".data(using: String.Encoding.utf8)! as NSObject,
            kSecClass: kSecClassKey,
            kSecReturnData: kCFBooleanTrue]

        var keyPairAttr = [NSObject: NSObject]()
        keyPairAttr[kSecAttrKeyType] = kSecAttrKeyTypeRSA
        keyPairAttr[kSecAttrKeySizeInBits] = 4096 as NSObject
        keyPairAttr[kSecPublicKeyAttrs] = publicKeyAttr as NSObject
        keyPairAttr[kSecPrivateKeyAttrs] = privateKeyAttr as NSObject

        let statusCode: OSStatus? = SecKeyGeneratePair(keyPairAttr as CFDictionary, &publicKey, &privateKey)
        var error: Unmanaged<CFError>?

        if statusCode == noErr && publicKey != nil && privateKey != nil {
            
            let publicKey: String? = SecKeyCopyExternalRepresentation(publicKey!, &error).map {
                convertToX509EncodedKey($0 as Data).base64EncodedString(
                        options: [.endLineWithLineFeed, .lineLength76Characters]
                )
            }

            let privateKey: String? = SecKeyCopyExternalRepresentation(privateKey!, &error).map {
                ($0 as Data).base64EncodedString(options: [.endLineWithLineFeed, .lineLength76Characters])
            }
            
            let keyValuePairs: KeyValuePairs = ["public": publicKey!, "private": privateKey!]
            return keyValuePairs

        } else {
            Crashlytics.crashlytics().log("Error generating key pair: \(String(describing: statusCode))")
            if let nserror = error?.takeUnretainedValue() {
                Crashlytics.crashlytics().record(error: nserror)
            }
            return KeyValuePairs()
        }
    }
    
    func createAndStoreKeyPair()  -> KeyValuePairs<String, String>? {
        let keys = createKeyPair()
        if keys.count > 0 {
            let publicKey = keys[0].value
            let privateKey = keys[1].value
            KeychainWrapper.standard.set(publicKey, forKey: keychainPublicKeyPath, withAccessibility: .always)
            KeychainWrapper.standard.set(privateKey, forKey: keychainPrivateKeyPath, withAccessibility: .always)
            return ["public": publicKey, "private": privateKey]
        } else {
            print("Error generating keys")
            return nil
        }
    }

    func readOrCreateKeys() -> KeyValuePairs<String, String>? {
        if let publicKey = KeychainWrapper.standard.string(forKey: keychainPublicKeyPath),
           let privateKey = KeychainWrapper.standard.string(forKey: keychainPrivateKeyPath) {
            return ["public": publicKey, "private": privateKey]
        } else {
            return createAndStoreKeyPair()
        }
    }

    func getPrivateKey() -> String? {
        KeychainWrapper.standard.string(forKey: keychainPrivateKeyPath)
    }

    func encrypt(with publicKey: String, message: String) -> CFData? {
        var error: Unmanaged<CFError>?
        if let decodedKey = decodeSecKeyFromBase64(encodedKey: publicKey),
           let data = message.data(using: .utf8) as CFData? {
            return SecKeyCreateEncryptedData(decodedKey, .rsaEncryptionPKCS1,
                    data,
                    &error)
        } else {
            return nil
        }

    }

    func decrypt(with privateKey: String, message: CFData) -> Data? {
        var error: Unmanaged<CFError>?
        if let privSecKey = decodeSecKeyFromBase64(encodedKey: privateKey, isPrivate: true) {
            let decrypted = SecKeyCreateDecryptedData(privSecKey, .rsaEncryptionPKCS1, message, &error)
            if let decryptedFinal = decrypted {
                return decryptedFinal as NSData as Data
            }
        }
        return nil
    }

    // Extract secKey from encoded string - defaults to extracting public keys
    private func decodeSecKeyFromBase64(encodedKey: String, isPrivate: Bool = false) -> SecKey? {
        var keyClass = kSecAttrKeyClassPublic
        if isPrivate {
            keyClass = kSecAttrKeyClassPrivate
        }
        let attributes: [String: Any] =
                [
                    kSecAttrKeyClass as String: keyClass,
                    kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                    kSecAttrKeySizeInBits as String: 4096
                ]

        guard let secKeyData = Data.init(base64Encoded: encodedKey, options: .ignoreUnknownCharacters) else {
            print("Error: invalid encodedKey, cannot extract data")
            return nil
        }
        guard let secKey = SecKeyCreateWithData(secKeyData as CFData, attributes as CFDictionary, nil) else {
            print("Error: Problem in SecKeyCreateWithData()")
            return nil
        }

        return secKey
    }

}
