//
//  ArmoreTheme.swift
//  RescueLink
//
//  Created by Dario Lencina on 7/2/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation
import MaterialComponents

let OxygenBold = "Oxygen-Bold"
let OxygenRegular = "Oxygen-Regular"

class ArmoreTheme {

    public static let instance = ArmoreTheme()

    let textFieldTheme: MDCContainerScheme = {
        let containerScheme = MDCContainerScheme()
        containerScheme.colorScheme.primaryColor = .black
        return containerScheme
    }()

    func labelBoldTheme(_ size: CGFloat = 20) -> MDCContainerScheme {
        let defaultScheme = MDCContainerScheme()
        let typographyScheme = MDCTypographyScheme()
        typographyScheme.button = UIFont(name: OxygenBold, size: size)!
        defaultScheme.typographyScheme = typographyScheme
        return defaultScheme
    }

    func labelTheme(_ size: CGFloat = 18) -> MDCContainerScheme {
        let defaultScheme = MDCContainerScheme()
        let typographyScheme = MDCTypographyScheme()
        typographyScheme.button = UIFont(name: OxygenRegular, size: size)!
        defaultScheme.typographyScheme = typographyScheme
        return defaultScheme
    }

    let roundedButtonTheme: MDCContainerScheme = {
        let defaultScheme = MDCContainerScheme()

        let typographyScheme = MDCTypographyScheme()
        typographyScheme.button = UIFont(name: OxygenBold, size: 18)!
        defaultScheme.typographyScheme = typographyScheme

        let colorScheme = MDCSemanticColorScheme(defaults: .material201804)
        colorScheme.primaryColor = UIColor.systemBlue()
        colorScheme.onPrimaryColor = UIColor.white
        defaultScheme.colorScheme = colorScheme
        return defaultScheme
    }()

    private init() {

    }
}
