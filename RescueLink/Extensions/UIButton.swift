//
//  UIButton.swift
//  RescueLink
//
//  Created by Dario Lencina on 7/4/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import MaterialComponents
import UIKit

typealias UIButtonTargetClosure = (UIButton) -> Void

class ClosureWrapper: NSObject {
    let closure: UIButtonTargetClosure

    init(_ closure: @escaping UIButtonTargetClosure) {
        self.closure = closure
    }
}

extension MDCButton {
    func swapFont(_ name: String) {
        self.setTitleFont(titleLabel?.font.swapFont(name), for: .normal)
    }
}

extension UIButton {
    private struct AssociatedKeys {
        static var targetClosure = "targetClosure"
    }

    private var targetClosure: UIButtonTargetClosure? {
        get {
            guard let closureWrapper = objc_getAssociatedObject(self, &AssociatedKeys.targetClosure)
                    as? ClosureWrapper else {
                return nil
            }
            return closureWrapper.closure
        }
        set(newValue) {
            guard let newValue = newValue else {
                return

            }
            objc_setAssociatedObject(self, &AssociatedKeys.targetClosure,
                    ClosureWrapper(newValue),
                    objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func addTargetClosure(_ closure: @escaping UIButtonTargetClosure) {
        targetClosure = closure
        addTarget(self, action: #selector(UIButton.closureAction), for: .touchUpInside)
    }

    @objc func closureAction() {
        guard let targetClosure = targetClosure else {
            return
        }
        targetClosure(self)
    }

    func setTheme() {
        if let titleLabel = self.titleLabel {
            titleLabel.font = UIFont(name: OxygenBold, size: titleLabel.font.pointSize)
        }
    }
}
