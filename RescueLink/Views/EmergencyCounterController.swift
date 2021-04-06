//
//  EmergencyCounterController.swift
//   Armore
//
//  Created by Security Union on 18/03/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import UIKit
import MaterialComponents

protocol EmergencyCounterProtocol {
    func showError(title: String, message: String)
    func nowOnEmergencyState()
}

class EmergencyCounterController: UIViewController, EmergencyCounterProtocol {

    // MARK: Variables
    var timer: Timer?
    var timerAnimation: Timer?
    var timeLeft = 5
    var counterAnimation = 1.0
    private let emergencyCounterPresenter = EmergencyCounterPresenter()

    // MARK: Protocol START

    func showError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
            self.dismiss(animated: true, completion: nil)
        }))
        alert.display()
    }

    func nowOnEmergencyState() {
        let alert = UIAlertController(
                title: NSLocalizedString("Emergency Mode", comment: ""),
                message: NSLocalizedString("emergency_mode_notification",
                        comment: ""),
                preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
            self.dismiss(animated: true, completion: nil)
        }))
        alert.display()
    }

    // MARK: Protocol END

    override func viewWillDisappear(_ animated: Bool) {
        timer?.invalidate()
        timerAnimation?.invalidate()
    }

    override func viewDidAppear(_ animated: Bool) {
        emergencyCounterPresenter.setViewDelegate(emergencyCounterController: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        startTimer()
        applyTheme()
        lblMessage.text = NSLocalizedString("We will notify all your followers that you have an emergency in:",
                comment: "")
        lblSeconds.text = NSLocalizedString("seconds", comment: "")
        btnCancelOutlet.setTitle(NSLocalizedString("Cancel", comment: ""), for: .normal)
        lblCounter.text = "\(timeLeft)"
    }

    func applyTheme() {
        btnCancelOutlet.beContained()
        btnCancelOutlet.backgroundColor = .black
    }

    // MARK: Outlets START

    @IBOutlet weak var lblCounter: UILabel!
    @IBOutlet weak var lblSeconds: UILabel!
    @IBOutlet weak var lblMessage: UILabel!
    @IBOutlet weak var btnCancelOutlet: MDCButton!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var viewActivity: UIView!

    // MARK: Outlets END

    // MARK: Buttons START

    @IBAction func btnCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: Buttons END

    // MARK: Functions START

    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1.0,
                target: self,
                selector: #selector(changeCounter), userInfo: nil, repeats: true)
        timerAnimation = Timer.scheduledTimer(timeInterval: 0.05,
                target: self,
                selector: #selector(animateProgress),
                userInfo: nil, repeats: true)
    }

    @objc func animateProgress() {
        viewActivity.alpha = CGFloat(counterAnimation)
        counterAnimation -= 0.05
        counterAnimation = counterAnimation <= 0 ? 1 : counterAnimation
    }

    @objc func changeCounter() {
        timeLeft -= 1
        lblCounter.text = "\(timeLeft)"
        if timeLeft == 0 {
            // stop timer
            timer?.invalidate()
            timerAnimation?.invalidate()

            emergencyCounterPresenter.setEmergencyState(state: SetStateRequest(new_state: .Emergency))

        }
    }

    // MARK: Functions END

}
