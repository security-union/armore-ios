//
//  Extensions.swift
//  Armore
//
//  Created by Security Union on 03/11/19.
//  Copyright © 2019 Security Union. All rights reserved.
//

import Foundation
import CommonCrypto
import UIKit
import Alamofire
import MaterialComponents.MaterialButtons
import MaterialComponents.MaterialButtons_Theming
import MaterialComponents.MaterialColorScheme
import MaterialComponents.MaterialButtons_ButtonThemer

let didSaveImage = "didSaveImage"

extension UIView {
    public func addDropShadow() {
        let shadowPath = UIBezierPath(rect: bounds)
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 5.0, height: -5.0)
        layer.shadowOpacity = 0.5
        layer.shadowPath = shadowPath.cgPath
    }
}

extension UIColor {
    public convenience init?(_ hex: String) {
        let scanner = Scanner(string: hex)
        var hexNumber: UInt64 = 0
        if scanner.scanHexInt64(&hexNumber) {
            self.init(red: CGFloat((hexNumber & 0xff000000) >> 24) / 0xFF,
                    green: CGFloat((hexNumber & 0x00ff0000) >> 16) / 0xFF,
                    blue: CGFloat((hexNumber & 0x0000ff00) >> 8) / 0xFF,
                    alpha: CGFloat((hexNumber & 0x000000ff)) / 0xFF)
            return
        } else {
            return nil
        }
    }

    static func systemBlue() -> UIColor {
        UIColor("0x0a84ffff")!
    }

    static func systemPink() -> UIColor {
        UIColor("0x8f1a7cff")!
    }

    static func brandedRed() -> UIColor {
        UIColor("0xef2d3eff")!
    }

    static func brandedWhite() -> UIColor {
        UIColor.lightGray
    }

    static func brandedPink2() -> UIColor {
        UIColor("0xBD9792ff")!
    }

    static func brandedPink3() -> UIColor {
        UIColor("0xBD979240")!
    }

    static func brandedCompleteWhite() -> UIColor {
        UIColor("0xffffffff")!
    }

    static func brandedGray() -> UIColor {
        UIColor("0xeeeeeeff")!
    }

    static func brandedBlack() -> UIColor {
        UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0)
    }

    static func brandedGreen() -> UIColor {
        UIColor("0x508752ff")!
    }

    static func brandedFontRed() -> UIColor {
        UIColor(red: 0.812, green: 0.4, blue: 0.475, alpha: 1.0)
    }

    static func brandButtonWhiteFocus() -> UIColor {
        UIColor(red: 1, green: 1, blue: 1, alpha: 0.93)
    }

    static func brandButtonWhite() -> UIColor {
        UIColor(red: 1, green: 1, blue: 1, alpha: 0.6)
    }

}

extension ISO8601DateFormatter {
    convenience init(_ formatOptions: Options) {
        self.init()
        self.formatOptions = formatOptions
    }
}

extension Formatter {
    static let iso8601withFractionalSeconds = ISO8601DateFormatter([.withInternetDateTime, .withFractionalSeconds])
}

extension Date {
    static func parseDate(_ rawDate: String?) -> Date? {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = DATE_FORMAT
        if let unwrapped = rawDate {
            return dateFormatter.date(from: unwrapped)
        } else {
            return Date()
        }
    }
    
    var iso8601withFractionalSeconds: String { return Formatter.iso8601withFractionalSeconds.string(from: self) }

    func timeAgoDisplay() -> String {

        let calendar = Calendar.current
        let minuteAgo = calendar.date(byAdding: .minute, value: -1, to: Date())!
        let hourAgo = calendar.date(byAdding: .hour, value: -1, to: Date())!
        let dayAgo = calendar.date(byAdding: .day, value: -1, to: Date())!
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

        if minuteAgo < self {
            let diff = Calendar.current.dateComponents([.second], from: self, to: Date()).second ?? 0
            return "\(diff) sec ago"
        } else if hourAgo < self {
            let diff = Calendar.current.dateComponents([.minute], from: self, to: Date()).minute ?? 0
            return "\(diff) min ago"
        } else if dayAgo < self {
            let diff = Calendar.current.dateComponents([.hour], from: self, to: Date()).hour ?? 0
            return "\(diff) hrs ago"
        } else if weekAgo < self {
            let diff = Calendar.current.dateComponents([.day], from: self, to: Date()).day ?? 0
            return "\(diff) days ago"
        }
        let diff = Calendar.current.dateComponents([.weekOfYear], from: self, to: Date()).weekOfYear ?? 0
        return "\(diff) weeks ago"
    }
}

extension String {
    var iso8601withFractionalSeconds: Date? { return Formatter.iso8601withFractionalSeconds.date(from: self) }
    
    func convertToDictionary() -> [String: Any]? {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }

    func sha256() -> NSData? {
        return self.data(using: String.Encoding.utf8).map {
            digest(input: $0 as NSData)
        }
    }

    func sha256Base64() -> String? {
        return self.sha256().map {
            $0.base64EncodedString(options: .lineLength76Characters)
        }
    }

    private func digest(input: NSData) -> NSData {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hash)
        return NSData(bytes: hash, length: digestLength)
    }

    func toReadableDate() -> String? {
        return Date.parseDate(self).flatMap { date in
            let cal = Calendar.current
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .medium
            dateFormatter.timeZone = TimeZone.current
            if cal.isDateInToday(date) {
                dateFormatter.dateFormat = "HH:mm"
                return "Today at \(dateFormatter.string(from: date))"
            } else {
                dateFormatter.dateStyle = .medium
                return dateFormatter.string(from: date)
            }
        }
    }

    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }

}

extension UIImageView {

    func roundedBlackImage() {
        self.layer.borderWidth = 1
        self.layer.masksToBounds = false
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.cornerRadius = self.frame.height / 2
        self.clipsToBounds = true
    }

    func roundedWhiteImage() {
        self.layer.borderWidth = 1
        self.layer.masksToBounds = false
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.cornerRadius = self.frame.height / 2
        self.clipsToBounds = true
    }

    func roundedImageWith(color: UIColor, borderWidth: CGFloat) {
        self.layer.borderWidth = borderWidth
        self.layer.masksToBounds = false
        self.layer.borderColor = color.cgColor
        self.layer.cornerRadius = self.frame.height / 2
        self.clipsToBounds = true
    }

    func roundedImage() {
        self.layer.masksToBounds = false
        self.layer.cornerRadius = self.frame.height / 2
        self.clipsToBounds = true
    }
}

extension UIImage {

    func saveImage(withName name: String) {

        guard let data = self.jpegData(compressionQuality: 1) ?? self.pngData() else {
            return
        }
        guard let directory = try? FileManager.default.url(for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false) as NSURL else {
            return
        }
        do {
            try data.write(to: directory.appendingPathComponent("\(name).png")!)
            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: didSaveImage),
                    object: self,
                    userInfo: ["name": name]))
        } catch {
            print(error.localizedDescription)
        }
    }

    func getBase64() -> String {
        let imageData: Data = self.pngData()!
        let dataEncoded = imageData.base64EncodedString(options: .endLineWithLineFeed)
        return dataEncoded

    }

    func scaleUsingPercentage(percent: Float) -> UIImage? {
        let vari = self.size.width * CGFloat(percent)
        let vari2 = self.size.height * CGFloat(percent)
        let size = CGSize(width: vari, height: vari2)
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }

    func resizeImage(_ dimension: CGFloat, opaque: Bool, contentMode: UIView.ContentMode = .scaleAspectFit) -> UIImage {
        var width: CGFloat
        var height: CGFloat
        var newImage: UIImage

        let size = self.size
        let aspectRatio = size.width / size.height

        switch contentMode {
        case .scaleAspectFit:
            if aspectRatio > 1 {                            // Landscape image
                width = dimension
                height = dimension / aspectRatio
            } else {                                        // Portrait image
                height = dimension
                width = dimension * aspectRatio
            }
        default:
            fatalError("UIIMage.resizeToFit(): FATAL: Unimplemented ContentMode")
        }

        if #available(iOS 10.0, *) {
            let renderFormat = UIGraphicsImageRendererFormat.default()
            renderFormat.opaque = opaque
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: renderFormat)
            newImage = renderer.image { (_) in
                self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            }
        } else {
            UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), opaque, 0)
            self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            newImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
        }

        return newImage
    }

}

extension UIButton {

    func roundedCornersSmall() {
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 10
    }

}

extension MDCButton {
    func beContained(type: ButtonTypes = .normal) {
        if type == .error {
            let containerScheme = globalContainerScheme(type: .error)
            self.applyContainedTheme(withScheme: containerScheme)
        } else if type == .standardWhiteFocus {
            let container = MDCContainerScheme()
            container.colorScheme.primaryColor = .black
            self.applyOutlinedTheme(withScheme: container)
        } else if type == .standardWhite {
            let container = MDCContainerScheme()
            container.colorScheme.primaryColor = .black
            self.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.6)
            self.applyOutlinedTheme(withScheme: container)
        } else {
            let containerScheme = globalContainerScheme()
            self.applyContainedTheme(withScheme: containerScheme)
        }
    }

    func beOutlined(type: ButtonTypes = .normal) {
        if type == .error {
            let containerScheme = globalContainerScheme(type: .error)
            self.applyOutlinedTheme(withScheme: containerScheme)
        } else {
            let containerScheme = globalContainerScheme()
            self.applyOutlinedTheme(withScheme: containerScheme)
        }
    }

    func beOutlined(color: UIColor) {
        let container = MDCContainerScheme()
        container.colorScheme.primaryColor = color
        self.applyOutlinedTheme(withScheme: container)
    }
}

extension UIView {

    func roundCorners(corners: UIRectCorner, radius: CGFloat) {

        DispatchQueue.main.async {
            let path = UIBezierPath(roundedRect: self.bounds,
                    byRoundingCorners: corners,
                    cornerRadii: CGSize(width: radius, height: radius))
            let maskLayer = CAShapeLayer()
            maskLayer.frame = self.bounds
            maskLayer.path = path.cgPath
            self.layer.mask = maskLayer
        }
    }
}
