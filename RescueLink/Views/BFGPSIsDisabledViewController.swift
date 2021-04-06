//
//  BFGPSIsDisabledViewController.swift
//   Armore
//
//  Created by Dario Talarico on 1/9/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import UIKit

class BFGPSIsDisabledViewController: UIViewController {

    @IBAction func btnOpenSettings(_ sender: Any) {
        goToAppSettings()
    }

    @IBAction func supportUsingEmail() {
        UIApplication.shared.open(URL(string: URLs().emailSupport())!, options: [:], completionHandler: nil)
    }

    @IBAction func supportUsingDiscord() {
        UIApplication.shared.open(URL(string: URLs().discordSupport())!, options: [:], completionHandler: nil)
    }
}
