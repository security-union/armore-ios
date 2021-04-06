//
//  BaseViewController.swift
//   Armore
//
//  Created by Dario Talarico on 2/6/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import UIKit

let progressViewHeight = CGFloat(4)

class BaseViewController: UIViewController {

    let progressView = CustomProgressView()

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self,
                selector: #selector(didLoadImage),
                name: Notification.Name.init(didSaveImage),
                object: nil)
        addProgressBar()
    }

    func addProgressBar() {
        progressView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: progressViewHeight)
        view.addSubview(progressView)
        progressView.isHidden = true
        progressView.indeterminate()
    }

    func showProgress(_ progress: Bool) {
        progressView.isHidden = !progress
        progressView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: progressViewHeight)
    }

    var topbarHeight: CGFloat {
        if #available(iOS 13.0, *) {
            return (view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0) +
                    (self.navigationController?.navigationBar.frame.height ?? 0.0)
        } else {
            return self.navigationController?.navigationBar.frame.height ?? 0.0
        }
    }

    @objc func didLoadImage(notification: Notification) {

    }

    func showMessage(title: String, message: String) {
        // login error
        let alert = UIAlertController(title: title, message: message)
        // in this case, token contains the error message
        alert.simpleOkAction()
        alert.display()
    }
}

class BaseTableViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self,
                selector: #selector(didLoadImage),
                name: Notification.Name.init(didSaveImage),
                object: nil)
    }

    @objc func didLoadImage(notification: Notification) {

    }
}
