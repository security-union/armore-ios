//
//  URLs.swift
//  Armore
//
//  Created by Security Union on 03/11/19.
//  Copyright © 2019 Security Union. All rights reserved.
//

import Foundation

enum Environment {
    case LocalDevelopment
    case Production
    case Staging
    case UITests
}

// let environment: Environment = CommandLine.arguments.contains("UITests") ? .UITests : .Staging
let environment: Environment = CommandLine.arguments.contains("UITests") ? .UITests : .Production

var URLInstance = URLs()

protocol BackendEnvironment {
    var AuthServer: String { get }
    var HttpGateway: String { get }
    var HttpGatewayV1: String { get }
    var EmergencyV1: String { get }
    var InvitationsV1: String { get }
    var NotificationsServer: String { get }
    var Website: String { get }
}

struct ProductionEnvironment: BackendEnvironment {
    let AuthServer: String = "https://auth.armore.dev"
    let HttpGateway: String = "https://api.armore.dev"
    let HttpGatewayV1: String = "https://api.armore.dev/v1"
    let EmergencyV1: String = "https://api.armore.dev/v1/emergency"
    let InvitationsV1: String = "https://api.armore.dev/v1/invitations"
    let NotificationsServer: String = "https://notifications.armore.dev"
    let Website: String = "https://armore.dev"
}

struct StagingEnvironment: BackendEnvironment {
    let AuthServer: String = "https://auth.staging.armore.dev"
    let HttpGateway: String = "https://api.staging.armore.dev"
    let HttpGatewayV1: String = "https://api.staging.armore.dev/v1"
    let EmergencyV1: String = "https://api.staging.armore.dev/v1/emergency"
    let InvitationsV1: String = "https://api.staging.armore.dev/v1/invitations"
    let NotificationsServer: String = "https://notifications.staging.armore.dev"
    let Website: String = "https://staging.armore.dev"
}

struct DevelopmentEnvironment: BackendEnvironment {
    let AuthServer: String = "http://localhost:10000"
    let HttpGateway: String = "http://localhost:8081"
    let HttpGatewayV1: String = "http://localhost:10001/v1"
    let EmergencyV1: String = "https://localhost:10003/v1/emergency"
    let InvitationsV1: String = "http://localhost:10002/v1/invitations"
    let NotificationsServer: String = "http://localhost:9999"
    let Website: String = "http://localhost:3000"

}

struct UITestEnvironment: BackendEnvironment {
    let AuthServer: String = "http://localhost:20000"
    let HttpGateway: String = "http://localhost:20000"
    let HttpGatewayV1: String = "http://localhost:20000/v1"
    let EmergencyV1: String = "http://localhost:20000/v1/emergency"
    let InvitationsV1: String = "http://localhost:20000/v1/invitations"
    let NotificationsServer: String = "http://localhost:20000"
    let Website: String = "http://localhost:20000"
}

struct URLs {

    let env: BackendEnvironment
    let termsOfService = "https://armore.dev/tos"
    let privacyPolicy = "https://armore.dev/privacy-policy"

    init() {
        switch environment {
        case .LocalDevelopment:
            env = DevelopmentEnvironment()
        case .UITests:
            env = UITestEnvironment()
        case .Staging:
            env = StagingEnvironment()
        default:
            env = ProductionEnvironment()
        }
    }

    func login() -> String {
        "\(env.AuthServer)/login"
    }

    func passwordReset() -> String {
        "\(env.AuthServer)/reset"
    }

    func devices() -> String {
        "\(env.HttpGateway)/devices"
    }

    func deleteDevice(device: String) -> String {
        "\(env.AuthServer)/me/devices/\(device)"
    }

    func setState() -> String {
        "\(env.EmergencyV1)/state"
    }
    
    func invitations() -> String {
        "\(env.InvitationsV1)"
    }

    func pushNotificationsRegister() -> String {
        "\(env.NotificationsServer)/register"
    }

    func register() -> String {
        "\(env.AuthServer)/register"
    }

    func telemetry() -> String {
        "\(env.HttpGatewayV1)/telemetry"
    }

    func me() -> String {
        "\(env.AuthServer)/me"
    }

    func image() -> String {
        "\(env.HttpGateway)/image"
    }

    func connections() -> String {
        "\(env.HttpGateway)/me/connections"
    }

    func meNewAccessType(newAccessType: AccessType, username: String) -> String {
        env.HttpGateway +
                ("/me/connections/followers/\(username)/accessType/\(newAccessType.rawValue)"
                        .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")
    }

    func meAccessOfFollower(followerUsername: String) -> String {
        env.HttpGateway +
                ("/me/connections/followers/\(followerUsername)"
                        .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")
    }

    func locationHistory(username: String) -> String {
        env.EmergencyV1 +
                ("/\(username)/telemetry"
                        .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")
    }

    func followerKeys() -> String {
        "\(env.HttpGatewayV1)/followers/keys"
    }
    
    func getInvitationDetails(_ withId: String) -> String {
        invitations() + ("/\(withId)"
                            .addingPercentEncoding(
                                withAllowedCharacters: .urlPathAllowed) ?? "") + "/creator"
    }

    public func acceptInvitation(withId: String) -> String {
        invitations() + ("/\(withId)/accept"
                            .addingPercentEncoding(
                                withAllowedCharacters: .urlPathAllowed) ?? "")
    }

    public func rejectInvitation(withId: String) -> String {
        invitations() + ("/\(withId)/reject"
                            .addingPercentEncoding(
                                withAllowedCharacters: .urlPathAllowed) ?? "")
    }

    public func cancelInvitation(withId: String) -> String {
        invitations() + ("/\(withId)/cancel"
                            .addingPercentEncoding(
                                withAllowedCharacters: .urlPathAllowed) ?? "")
    }
    
    public func createInvitation() -> String {
        invitations()
    }

    public func removeFriend(username: String) -> String {
        invitations() + ("/remove/\(username)"
                .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")
    }

    public func imageWithId(imageId: String) -> String {
        image() + "/\(imageId)"
    }

    public func userExists(email: String, authMethod: AuthMethod) -> String {
        let emailOrPhone = authMethod == .sms ? "phone" : "email"
        return env.AuthServer + ("/user/exists/\(emailOrPhone)/\(email)"
                .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")
    }

    public func codeVerification(email: String) -> String {
        env.AuthServer + ("/user/verify/\(email)"
                .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")
    }

    public func deviceSettings() -> String {
        env.HttpGatewayV1 + "/device/settings"
    }

    public func emailSupport() -> String {
        "mailto:support@armore.dev"
    }

    public func discordSupport() -> String {
        NSLocalizedString("support_discord_url", comment: "")
    }
    
    public func pendingInvitations() -> String {
        env.Website + ("/pending-invitations")
    }

}
