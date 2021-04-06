/**
 * Copyright IBM Corporation 2018
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Foundation

// MARK: JWTSigner

/**
 A struct that will be used to sign the JWT `Header` and `Claims` and generate a signed JWT.
 
 ### Usage Example: ###
 ```swift
 let privateKey = "<PrivateKey>".data(using: .utf8)!
 let jwtSigner = JWTSigner.rs256(privateKey: privateKey)
 struct MyClaims: Claims {
    var name: String
 }
 let jwt = JWT(claims: MyClaims(name: "Kitura"))
 let signedJWT: String? = try? jwt.sign(using: jwtSigner)
 ```
 */
public struct JWTSigner {
    
    /// The name of the algorithm that will be set in the "alg" header
    let name: String
    
    let signerAlgorithm: SignerAlgorithm

    init(name: String, signerAlgorithm: SignerAlgorithm) {
        self.name = name
        self.signerAlgorithm = signerAlgorithm
    }
    
    func sign(header: String, claims: String) throws -> String {
        return try signerAlgorithm.sign(header: header, claims: claims)
    }
    
    /// Initialize a JWTSigner using the RSA 256 bits algorithm and the provided privateKey.
    public static func rs256(privateKey: Data) -> JWTSigner {
        return JWTSigner(name: "RS256", signerAlgorithm: BlueRSA(key: privateKey, keyType: .privateKey, algorithm: .sha256))
    }
    
    /// Initialize a JWTSigner using the RSA 384 bits algorithm and the provided privateKey.
    public static func rs384(privateKey: Data) -> JWTSigner {
        return JWTSigner(name: "RS384", signerAlgorithm: BlueRSA(key: privateKey, keyType: .privateKey, algorithm: .sha384))
    }
    
    /// Initialize a JWTSigner using the RSA 512 bits algorithm and the provided privateKey.
    public static func rs512(privateKey: Data) -> JWTSigner {
        return JWTSigner(name: "RS512", signerAlgorithm: BlueRSA(key: privateKey, keyType: .privateKey, algorithm: .sha512))
    }
    
    /// Initialize a JWTSigner using the HMAC 256 bits algorithm and the provided privateKey.
    public static func hs256(key: Data) -> JWTSigner {
        return JWTSigner(name: "HS256", signerAlgorithm: BlueHMAC(key: key, algorithm: .sha256))
    }
    
    /// Initialize a JWTSigner using the HMAC 384 bits algorithm and the provided privateKey.
    public static func hs384(key: Data) -> JWTSigner {
        return JWTSigner(name: "HS384", signerAlgorithm: BlueHMAC(key: key, algorithm: .sha384))
    }
    
    /// Initialize a JWTSigner using the HMAC 512 bits algorithm and the provided privateKey.
    public static func hs512(key: Data) -> JWTSigner {
        return JWTSigner(name: "HS512", signerAlgorithm: BlueHMAC(key: key, algorithm: .sha512))
    }
    
    /// Initialize a JWTSigner that will not sign the JWT. This is equivelent to using the "none" alg header.
    public static let none = JWTSigner(name: "none", signerAlgorithm: NoneAlgorithm())
}

