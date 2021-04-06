//
//  ConfigurationController.swift
//   Armore
//
//  Created by Security Union on 13/11/19.
//  Copyright © 2019 Security Union. All rights reserved.
//

import UIKit
import MaterialComponents
import RxSwift

protocol ConfigurationProtocol {
    func showMessage(title: String, message: String)
}

class ConfigurationController: BaseViewController,
        UIImagePickerControllerDelegate, ConfigurationProtocol, UINavigationControllerDelegate {

    let actions: [Int: String] = [Int: String]()
    @IBOutlet weak var userImage: MDCFloatingButton!
    @IBOutlet weak var lblUsername: UILabel!
    @IBOutlet weak var lblEmail: UILabel!
    @IBOutlet weak var btnLogoutOutlet: MDCButton!
    @IBOutlet weak var lblFollowingNumber: UILabel!
    @IBOutlet weak var lblFollowersNumber: UILabel!
    @IBOutlet weak var btnPrivacyPolicyOutlet: MDCButton!
    @IBOutlet weak var btnTermsOfService: MDCButton!
    @IBOutlet weak var imageLoadingSlash: MDCActivityIndicator!

    @IBOutlet weak var discordSupport: MDCButton!
    @IBOutlet weak var emailSupport: MDCButton!
    private let configurationPresenter = ConfigurationPresenter(urls: URLs())
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configurationPresenter.setViewDelegate(configurationController: self)
        applyTheme()
        guard let userInfo = configurationPresenter.getUserInfo() else {
            return
        }
        lblUsername.text = "\(userInfo.firstName) \(userInfo.lastName)"
        userImage.imageView?.roundedWhiteImage()
        if let userInfo = CurrentUser().getUserInfo(),
           let image = ImageProfile()
                   .getImageOrDownloadIt(
                           UserDetails(username: userInfo.username, picture: userInfo.pictureURL)
                   ) {
            userImage.setImage(image, for: .normal)
        }
        lblEmail.text = userInfo.phone == "" ? userInfo.email : userInfo.phone
        self.imageLoadingSlash.setIndicatorMode(.indeterminate, animated: true)
        setupObserver()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    func setupObserver() {
        self.configurationPresenter.isBusy.subscribe(onNext: { [weak self] isBusy in
            self?.showProgress(isBusy)
            if isBusy {
                self?.imageLoadingSlash.startAnimating()
                self?.imageLoadingSlash.isHidden = false
            } else {
                self?.imageLoadingSlash.stopAnimating()
                self?.imageLoadingSlash.isHidden = true
            }
        }).disposed(by: disposeBag)
    }

    func applyTheme() {
        btnLogoutOutlet.beOutlined(color: .white)
        btnLogoutOutlet.setBorderColor(.white, for: .normal)

        btnPrivacyPolicyOutlet.beContained()
        btnPrivacyPolicyOutlet.backgroundColor = .black
        btnTermsOfService.beContained()
        btnTermsOfService.backgroundColor = .black

        emailSupport.beContained()
        emailSupport.backgroundColor = .black

        discordSupport.beContained()
        discordSupport.backgroundColor = .black
        discordSupport.swapFont(OxygenBold)
        emailSupport.swapFont(OxygenBold)
        lblUsername.swapFont(OxygenBold)
        lblEmail.swapFont(OxygenBold)
        btnPrivacyPolicyOutlet.swapFont(OxygenBold)
        btnTermsOfService.swapFont(OxygenBold)
        btnLogoutOutlet.swapFont(OxygenBold)
        navigationController?.navigationBar.barTintColor = .black
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.barStyle = .black
    }

    override func didLoadImage(notification: Notification) {
        if notification.object as? UIImage != nil {
            if let userInfo = CurrentUser().getUserInfo(),
               let image = ImageProfile()
                       .getImageOrDownloadIt(
                               UserDetails(username: userInfo.username, picture: userInfo.pictureURL)
                       ) {
                self.userImage.setImage(image, for: .normal)
            }
        }
    }

    @IBAction func btnLogout(_ sender: Any) {
        let alert = UIAlertController(
                title: NSLocalizedString("Remove account?", comment: ""),
                message: NSLocalizedString("Do you want to remove your account?", comment: ""))
        alert.addAction(UIAlertAction(title: NSLocalizedString("No", comment: ""),
                style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""),
                style: .default, handler: { (_) in
            let logoutConfirmationAlert = UIAlertController(
                    title: NSLocalizedString("logout_confirmation_title",
                            comment: ""),
                    message: NSLocalizedString("logout_confirmation", comment: ""))
            logoutConfirmationAlert.addAction(
                    UIAlertAction(title: NSLocalizedString("I'm Sure", comment: ""),
                            style: .destructive, handler: { (_) in
                        self.configurationPresenter.logout()
                    }))
            logoutConfirmationAlert.addAction(
                    UIAlertAction(title: NSLocalizedString("Cancel", comment: ""),
                            style: .cancel, handler: { (_) in
                    }))
            logoutConfirmationAlert.display()
        }))
        alert.display()
    }

    @IBAction func btnTermsOfService(_ sender: Any) {
        UIApplication.shared.open(URL(string: URLs().termsOfService)!, options: [:], completionHandler: nil)
    }

    @IBAction func btnPrivacyPolicy(_ sender: Any) {
        UIApplication.shared.open(URL(string: URLs().privacyPolicy)!, options: [:], completionHandler: nil)
    }

    @objc func actionBack() {
        self.performSegue(withIdentifier: "returnFromConfigurationToLocations", sender: self)
    }

    @IBAction func returnFromInvitationsToConfiguration(_ segue: UIStoryboardSegue) {
    }

    @IBAction func supportUsingEmail() {
        UIApplication.shared.open(URL(string: URLs().emailSupport())!, options: [:], completionHandler: nil)
    }

    @IBAction func supportUsingDiscord() {
        UIApplication.shared.open(URL(string: URLs().discordSupport())!, options: [:], completionHandler: nil)
    }

    @IBAction func swapUserImage() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo
                               info: [UIImagePickerController.InfoKey: Any]) {

        guard let image = info[.editedImage] as? UIImage else {
            return
        }

        dismiss(animated: true)

        userImage?.imageView?.roundedWhiteImage()

        let imageSize = image.getBase64().count
        let maxImageSize = 5000000
        var scaledImage = image
        if imageSize > maxImageSize {
            scaledImage = image.scaleUsingPercentage(percent: Float(maxImageSize) / Float(imageSize)) ?? image
        }
        userImage.setImage(scaledImage, for: .normal)
        configurationPresenter.updateImageProfile(scaledImage) { response in
            if let userDetails = response.result?.toUserDetails(),
               let newPicture = userDetails.picture, response.success {
                CurrentUser().saveUserImageName(newPicture)
                _ = ImageProfile().getImageOrDownloadIt(userDetails)
            } else if let message = response.getMessage(), !response.success {
                self.showMessage(title: "Error", message: message)
            }
        }
    }

}

class CellConfiguration: UITableViewCell {
    @IBOutlet weak var lblTitle: UILabel!
}
