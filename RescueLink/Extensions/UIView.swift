//
//  UIView.swift
//  RescueLink
//
//  Created by Dario Lencina on 11/8/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import UIKit
import PureLayout

func CGHairlineWidth() -> CGFloat {
    2
}

public extension UIView {
    func addBottomStroke() {
        addBottomStroke(color: UIColor.gray, strokeWidth: CGHairlineWidth())
    }

    func addBottomStroke(color: UIColor, strokeWidth: CGFloat) {
        let strokeView = UIView()
        strokeView.backgroundColor = color
        addSubview(strokeView)
        strokeView.autoSetDimension(.height, toSize: strokeWidth)
        strokeView.autoPinEdge(toSuperviewMargin: .leading)
        strokeView.autoPinEdge(toSuperviewMargin: .trailing)
        strokeView.autoPinEdge(toSuperviewEdge: .bottom)
    }

    func constrainCentered(_ subview: UIView) {

        subview.translatesAutoresizingMaskIntoConstraints = false

        let verticalContraint = NSLayoutConstraint(
                item: subview,
                attribute: .centerY,
                relatedBy: .equal,
                toItem: self,
                attribute: .centerY,
                multiplier: 1.0,
                constant: 0)

        let horizontalContraint = NSLayoutConstraint(
                item: subview,
                attribute: .centerX,
                relatedBy: .equal,
                toItem: self,
                attribute: .centerX,
                multiplier: 1.0,
                constant: 0)

        let heightContraint = NSLayoutConstraint(
                item: subview,
                attribute: .height,
                relatedBy: .equal,
                toItem: nil,
                attribute: .notAnAttribute,
                multiplier: 1.0,
                constant: subview.frame.height)

        let widthContraint = NSLayoutConstraint(
                item: subview,
                attribute: .width,
                relatedBy: .equal,
                toItem: nil,
                attribute: .notAnAttribute,
                multiplier: 1.0,
                constant: subview.frame.width)

        addConstraints([
            horizontalContraint,
            verticalContraint,
            heightContraint,
            widthContraint])

    }

    func constrainToEdges(_ subview: UIView) {

        subview.translatesAutoresizingMaskIntoConstraints = false

        let topContraint = NSLayoutConstraint(
                item: subview,
                attribute: .top,
                relatedBy: .equal,
                toItem: self,
                attribute: .top,
                multiplier: 1.0,
                constant: 0)

        let bottomConstraint = NSLayoutConstraint(
                item: subview,
                attribute: .bottom,
                relatedBy: .equal,
                toItem: self,
                attribute: .bottom,
                multiplier: 1.0,
                constant: 0)

        let leadingContraint = NSLayoutConstraint(
                item: subview,
                attribute: .leading,
                relatedBy: .equal,
                toItem: self,
                attribute: .leading,
                multiplier: 1.0,
                constant: 0)

        let trailingContraint = NSLayoutConstraint(
                item: subview,
                attribute: .trailing,
                relatedBy: .equal,
                toItem: self,
                attribute: .trailing,
                multiplier: 1.0,
                constant: 0)

        addConstraints([
            topContraint,
            bottomConstraint,
            leadingContraint,
            trailingContraint])
    }

    class func fromNib<T: UIView>() -> T? {
        Bundle(for: T.self).loadNibNamed(String(describing: T.self), owner: nil, options: nil)?.first as? T
    }

    @discardableResult
    func fromNib<T: UIView>() -> T? {
        guard let contentView = Bundle(for: type(of: self))
                .loadNibNamed(String(
                        describing: type(of: self)),
                        owner: self,
                        options: nil)?.first as? T else {
            return nil
        }

        addSubview(contentView)
        backgroundColor = .clear
        return contentView
    }
}
