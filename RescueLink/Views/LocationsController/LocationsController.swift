//
//  LocationsController.swift
//   Armore
//
//  Created by Security Union on 06/11/19.
//  Copyright © 2019 Security Union. All rights
// swiftlint:disable file_length

import Firebase
import UIKit
import MapKit
import CoreLocation
import UserNotifications
import MaterialComponents.MaterialButtons
import MaterialComponents.MaterialButtons_Theming
import MaterialComponents.MaterialColorScheme
import MaterialComponents.MaterialTypography
import MaterialComponents.MaterialBottomSheet
import RxSwift

let defaultZoom = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
let regionRadius: CLLocationDistance = 1000
let pinLatAdjust = 0.00005
let collapsedFriendsHeight: CGFloat = 66.0
let annotationIdentifier = "marker"

class LocationsController: BaseViewController,
        MKMapViewDelegate,
        CLLocationManagerDelegate {

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var friendsContainer: UIView!
    @IBOutlet weak var mapHeight: NSLayoutConstraint!
    var friendsBarExpandedMapHeight: CGFloat?
    let locationsPresenter: LocationsPresenter = LocationsPresenter(urls: URLs())
    let disposeBag = DisposeBag()
    var cachedAnnotations = [String: MyAnnotation]()
    private var selectedUser: DetailTable?
    @IBOutlet weak var friendsView: UIView!
    @IBOutlet weak var friendDetails: UIView!
    @IBOutlet weak var locationButton: MDCFloatingButton!
    @IBOutlet weak var sosButton: MDCFloatingButton!
    @IBOutlet weak var friendHeader: UIView!
    @IBOutlet weak var friendHeaderArrow: UIButton!
    @IBOutlet weak var selectedUserUsername: UILabel!
    @IBOutlet weak var e2eEncrypted: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var visibility: UIButton!
    @IBOutlet weak var shareLocation: UIButton!
    @IBOutlet weak var friendsLabel: UILabel!
    @IBOutlet weak var lowPowerModeBanner: UIView!
    
    let segues = [
        "locationsToHistoricalLocation": "locationsToHistoricalLocation",
        "locationsToEmergencyCounter": "locationsToEmergencyCounter",
        "newInvitationFromLocations": "newInvitationFromLocations"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        friendsBarExpandedMapHeight = self.view.frame.height / 2
        mapHeight.constant = friendsBarExpandedMapHeight!
        setupObservers()
        applyTheme()
        setupMap()
        setupHandlers()
        refreshUserState()
        if !FeatureFlags().EMERGENCY {
            sosButton.removeFromSuperview()
        } else {
            let userInfo = locationsPresenter.getUserInfo()
            if userInfo?.state.selfPerceptionState == .Emergency {
                
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        applyTheme()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        registerForPushNotifications()
        showGPSErrorIfNeeded()
        showUserLocation()
        self.locationsPresenter.startTrackingLocation()
    }
    
    func refreshUserState() {
        self.locationsPresenter.getMe { res in
            if res.success {
                guard let user = res.result as UserDetails? else {
                    self.showError(
                        title: "Error",
                        message: res.getMessage() ?? NSLocalizedString("server_parsing_error", comment: "")
                    )
                    return
                }
                saveUserDefaults(user: user)
            } else {
                self.showError(
                    title: "Error",
                    message: res.getMessage() ?? NSLocalizedString("server_parsing_error", comment: "")
                )
            }
        }
    }

    func setupObservers() {
        self.locationsPresenter.friendsTableState.subscribe(onNext: { [weak self] tableState in
            self?.setFriendsTableState(tableState)
        }).disposed(by: disposeBag)

        self.locationsPresenter.selectedUser.subscribe(onNext: { [weak self] possibleUser in
            self?.showSelectedUser(possibleUser)
            self?.selectedUser = possibleUser
        }).disposed(by: disposeBag)

        self.locationsPresenter.friends.subscribe(onNext: { [weak self] newConnections in
            if let following = newConnections?.result?.following {
                self?.putAnnotations(following)
            }
            if let newFriends = newConnections?.result?.newFriends {
                if newFriends {
                    LocationPusher.instance.forcePushLocation()
                }
            }
        }).disposed(by: disposeBag)
        self.locationsPresenter.error.subscribe(onNext: { [weak self] onError in
            if let error = onError {
                self?.showError(title: "Error", message: error.0)
            }
        }).disposed(by: disposeBag)
        self.locationsPresenter.isLowPowerModeEnabled.subscribe(onNext: { [weak self] isLowPowerModeEnabled in
            DispatchQueue.main.async {
                self?.lowPowerModeBanner.isHidden = !isLowPowerModeEnabled
            }
        }).disposed(by: disposeBag)
        self.locationsPresenter.notification.subscribe(onNext: { [weak self] notification in
            if let inboundNotification = notification, inboundNotification.name.rawValue == OnInvitationNotif {
                DispatchQueue.main.async {
                    self?.handleUserActivityNotification(notification: inboundNotification)
                    self?.locationsPresenter.clearNotification()
                }
            }
        }).disposed(by: disposeBag)
    }

    func setupHandlers() {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleTableState))
        friendHeader.addGestureRecognizer(gestureRecognizer)
        let gestureRecognizer2 = UITapGestureRecognizer(target: self, action: #selector(toggleTableState))
        friendHeaderArrow.addGestureRecognizer(gestureRecognizer2)
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(swipeTable))
        swipeUp.direction = .up
        friendHeader.addGestureRecognizer(swipeUp)
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(swipeTable))
        swipeDown.direction = .down
        friendHeader.addGestureRecognizer(swipeDown)
    }

    @objc func toggleTableState() {
        locationsPresenter.toggleFriendsTableState()
    }

    @objc func swipeTable(swipe: UISwipeGestureRecognizer) {
        switch swipe.direction {
        case .up:
            locationsPresenter.setFriendsTableState(.Visible)
        case .down:
            locationsPresenter.setFriendsTableState(.Collapsed)
        default: break
        }
    }

    func applyTheme() {
        let theme = ArmoreTheme.instance
        locationButton.backgroundColor = UIColor.brandedBlack()
        locationButton.setImage(UIImage.init(named: "location_tabbar")?
                .withRenderingMode(.alwaysTemplate), for: .normal)
        locationButton.setImageTintColor(UIColor.white, for: .normal)
        self.backButton?.transform = CGAffineTransform(rotationAngle: degreesToRadians(-90))
        self.selectedUserUsername.textColor = UIColor.lightGray
        self.selectedUserUsername.font = theme.labelBoldTheme(20).typographyScheme.button
        self.friendsLabel.font = theme.labelBoldTheme(20).typographyScheme.button
        self.friendsLabel.text = NSLocalizedString("friends", comment: "")
        e2eEncrypted.font = theme.labelBoldTheme(12).typographyScheme.button
        self.e2eEncrypted.textColor = UIColor.lightGray
        self.e2eEncrypted.backgroundColor = UIColor.black
        friendHeaderArrow.imageView?.contentMode = .scaleAspectFit
        backButton.imageView?.contentMode = .scaleAspectFit
        visibility.imageView?.contentMode = .scaleAspectFit
        shareLocation.imageView?.contentMode = .scaleAspectFit
        if FeatureFlags().EMERGENCY {
            self.styleSosButton(state: self.locationsPresenter.getUserInfo()?.state.selfPerceptionState ?? .Normal)
        }
    }
    
    func styleSosButton(state: PerceptionState) {
        switch state {
        case .Normal:
            let image = UIImage(named: "emer-button")
            self.sosButton.setImage(image, for: [])
        case .Emergency:
            let image = UIImage(named: "emer-button-disable")
            self.sosButton.setImage(image, for: [])
        }
        self.sosButton.setBorderColor(UIColor.red, for: .normal)
        self.sosButton.setBorderWidth(10, for: .normal)
        self.sosButton.contentVerticalAlignment = .center
        self.sosButton.contentHorizontalAlignment = .center
    }

    func setupMap() {
        map.showsCompass = false
        map.showsUserLocation = true
    }

    func showSelectedUser(_ renderMode: DetailTable?) {
        switch renderMode {
        case Optional.some(let user):
            UIView.transition(with: self.friendsContainer,
                    duration: 0.3,
                    options: .transitionCrossDissolve,
                    animations: {
                        self.friendsView.isHidden = true
                        self.friendDetails.isHidden = false
                        self.visibility.isHidden = user.selectedFriend.location?.clLocation() == nil
                        self.backButton.isHidden = false
                        self.friendsLabel.isHidden = true
                        self.selectedUserUsername.isHidden = false
                        self.shareLocation.isHidden = true
                    })
            selectedUserUsername.text = user.selectedFriend.completeName()
            if let username = user.selectedFriend.userDetails?.username {
                self.centerMapOnDevice(username)
            }
        default:
            UIView.transition(with: self.friendsContainer,
                    duration: 0.3,
                    options: .transitionCrossDissolve,
                    animations: {
                        self.friendsView.isHidden = false
                        self.friendDetails.isHidden = true
                        self.visibility.isHidden = true
                        self.backButton.isHidden = true
                        self.friendsLabel.isHidden = false
                        self.selectedUserUsername.isHidden = true
                        self.shareLocation.isHidden = false
                    })
        }
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    func setFriendsTableState(_ tableState: FriendsTableState) {
        guard let height = self.friendsBarExpandedMapHeight else {
            return
        }
        switch tableState {
        case .Collapsed:
            self.mapHeight.constant = self.view.frame.height - collapsedFriendsHeight
            self.friendHeaderArrow?.transform = CGAffineTransform(rotationAngle: degreesToRadians(0))
        default:
            self.mapHeight.constant = height
            self.friendHeaderArrow?.transform = CGAffineTransform(rotationAngle: degreesToRadians(180))
        }
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    func putAnnotations(_ connections: [String: Friend]) {
        // 1. remove annotations that are no longer in connections.
        let annotationsToRemove = cachedAnnotations.keys.filter { username in
            connections[username] == nil
        }

        annotationsToRemove.forEach { username in
            if let annotation = cachedAnnotations.removeValue(forKey: username) {
                map.removeAnnotation(annotation)
            }
        }

        // 2. Add annotations that are not cached.
        let annotationsToAdd = connections.keys.filter { username in
            cachedAnnotations[username] == nil
        }

        annotationsToAdd.forEach { username in
            if let connectionUser = connections[username],
               let coordinate = connectionUser.location?.coordinate() {
                let annotation = MyAnnotation(
                        owner: connectionUser,
                        title: connectionUser.completeName(),
                        subtitle: "",
                        coordinate: coordinate
                )
                cachedAnnotations[username] = annotation
                map.addAnnotation(annotation)
            }
        }

        // 3. Update annotations that are cached and are in the connections
        let annotationsToUpdate = connections.keys.filter { username in
            cachedAnnotations[username] != nil
        }

        annotationsToUpdate.forEach { username in
            if let connectionUser = connections[username],
               let annotation = cachedAnnotations[username],
               let coordinate = connectionUser.location?.coordinate() {
                annotation.owner = connectionUser
                annotation.coordinate = coordinate
                if let view = map.view(for: annotation) as? ImageAnnotationView {
                    setAnnotationViewImageAndBorder(view: view, userAnnotation: annotation)
                }
            }
        }
    }

    func centerMapOnDevice(_ username: String) {
        if let location = self.cachedAnnotations[username]?.coordinate {
            let center = CLLocationCoordinate2D(latitude: location.latitude -
                    pinLatAdjust, longitude: location.longitude)
            let region = MKCoordinateRegion(center: center, span: defaultZoom)
            map.setRegion(region, animated: true)
        }
    }

    func seeHistoricalLocation(user: Friend) {
        self.performSegue(withIdentifier: segues["locationsToHistoricalLocation"]!, sender: self)
    }

    func registerForPushNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (_, _) in

        }
    }

    func setAnnotationViewImageAndBorder(view: ImageAnnotationView, userAnnotation: MyAnnotation) {
        view.setBorderColor(color: colorForStatus(statusForUser(userAnnotation.owner)))
        view.image = ImageProfile().getImageOrDownloadIt(userAnnotation.owner?.userDetails)
                ?? UIImage(named: DEFAULT_PLACEHODER_IMAGE)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let userAnnotation = annotation as? MyAnnotation,
           #available(iOS 11.0, *), !annotation.isKind(of: MKUserLocation.self) {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier)
                    as? ImageAnnotationView ??
                    ImageAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            setAnnotationViewImageAndBorder(view: view, userAnnotation: userAnnotation)
            return view
        } else {
            return nil
        }
    }

    func updateProfilePhoto(username: String, image: UIImage) {
        if let annotation = self.cachedAnnotations[username] {
            annotation.image = image
            if let view = map.view(for: annotation) as? ImageAnnotationView {
                setAnnotationViewImageAndBorder(view: view, userAnnotation: annotation)
            }
        }
    }

    override func didLoadImage(notification: Notification) {
        if let imageName = notification.userInfo?["name"] as? String,
           let image = notification.object as? UIImage {
            updateProfilePhoto(username: imageName, image: image)
        }
    }

    @IBAction func btnCenterOnDevice(_ sender: Any) {
        if CLLocationManager.locationServicesEnabled() {
            showUserLocation()
        }
    }

    @IBAction func btnSos(_ sender: Any) {
        if locationsPresenter.getUserInfo()?.state.selfPerceptionState == .Emergency {
            locationsPresenter.quitEmergencyState { res in
                if res.success {
                    self.showMessage(
                        title: NSLocalizedString("Emergency Mode Off", comment: ""),
                        message: NSLocalizedString("emergency_state_off", comment: "")
                    )
                    let userDefaults = UserDefaults.standard
                    userDefaults.set(res.result?.message, forKey: "selfPerceptionState")
                    userDefaults.synchronize()
                    self.styleSosButton(state: .Normal)
                } else {
                    self.showError(
                        title: NSLocalizedString("Error", comment: ""),
                        message: res.getMessage() ?? NSLocalizedString(NO_CONNECTION, comment: "")
                    )
                }
            }
        } else {
            self.performSegue(withIdentifier: segues["locationsToEmergencyCounter"]!, sender: self)
        }
    }

    @IBAction func shareYourLocation(_ sender: Any) {
        self.performSegue(withIdentifier: segues["newInvitationFromLocations"]!, sender: self)
    }

    @IBAction func popToFriendsTable() {
        locationsPresenter.setSelectedUser(nil)
    }

    @IBAction func centerOnUser(_ sender: Any) {
        if let username = selectedUser?.selectedFriend.userDetails?.username {
            locationsPresenter.setSelectedUser(username)
        }
    }

    func showUserLocation() {
        let coordinates = self.map.userLocation.coordinate
        if abs(coordinates.latitude) > 0 && abs(coordinates.longitude) > 0 {
            self.map.setRegion(MKCoordinateRegion(center: coordinates,
                    span: defaultZoom),
                    animated: false)
        }
    }

}
