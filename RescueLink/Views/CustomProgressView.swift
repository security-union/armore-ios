//
//  MDCProgressView.swift
//  RescueLink
//
//  Created by Dario Lencina on 7/5/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import MaterialComponents

let duration: TimeInterval = 0.6

public class CustomProgressView: MDCProgressView {

    func indeterminate() {
        if self.trackTintColor == UIColor.brandedGray() {
            self.progressTintColor = UIColor.brandedGray()
            self.trackTintColor = UIColor.brandedPink2()
        } else {
            self.trackTintColor = UIColor.brandedGray()
            self.progressTintColor = UIColor.brandedPink2()
        }

        self.setProgress(0, animated: false, completion: nil)
        UIView.animate(withDuration: duration, animations: { [weak self] in
            self?.setProgress(1, animated: false, completion: nil)
        }, completion: { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(800)) {
                self?.indeterminate()
            }
        })
    }
}
