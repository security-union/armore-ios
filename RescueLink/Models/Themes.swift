//
//  Themes.swift
//   Armore
//
//  Created by Security Union on 06/02/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation
import MaterialComponents.MaterialButtons
import MaterialComponents.MaterialButtons_Theming
import MaterialComponents.MaterialColorScheme

enum ButtonTypes {
    case normal
    case error
    case standardWhiteFocus
    case standardWhite
}

func globalContainerScheme(type: ButtonTypes = .normal) -> MDCContainerScheming {
    let containerScheme = MDCContainerScheme()
    switch type {
    case .normal:
        containerScheme.colorScheme.primaryColor = .systemBlue
    case .error:
        containerScheme.colorScheme.primaryColor = .red
    default:
        //
        break
    }
    return containerScheme
}

func styleSegmentedControl(_ segmentedControl: UISegmentedControl) {
    if #available(iOS 13.0, *) {
        segmentedControl.selectedSegmentTintColor = UIColor.systemBlue()
        segmentedControl.setTitleTextAttributes(
                [NSAttributedString.Key.foregroundColor: UIColor.white], for: .selected)
    }
}
