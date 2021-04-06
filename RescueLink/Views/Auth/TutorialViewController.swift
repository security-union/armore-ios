//
//  TutorialViewController.swift
//  RescueLink
//
//  Created by Dario Lencina on 2/25/21.
//  Copyright © 2021 Security Union. All rights reserved.
//

import UIKit
import MaterialComponents
import SwiftyGif

let goToLocationsControllerSegue2 = "goToLocationsController"
let goToLoginControllerSegue = "goToLoginControllerSegue"

let dataSource = [
    ["title": NSLocalizedString("tutorial_part_title_1", comment: ""),
     "instructions": NSLocalizedString("tutorial_part_instructions_1", comment: "")
    ],
    ["title": NSLocalizedString("tutorial_part_title_2", comment: ""),
     "instructions": NSLocalizedString("tutorial_part_instructions_2", comment: "")
    ],
    ["title": NSLocalizedString("tutorial_part_title_3", comment: ""),
     "instructions": NSLocalizedString("tutorial_part_instructions_3", comment: "")
    ]
]

class TutorialViewController: UIViewController,
                              UICollectionViewDataSource,
                              UICollectionViewDelegate,
                              UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var animation: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var continueBtn: MDCFloatingButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        if checkSession() {
            gotoLocationsController()
        }
        collectionView.reloadData()
        pageControl.numberOfPages = dataSource.count
    }
    
    func applyTheme() {
        continueBtn.applyContainedTheme(withScheme: ArmoreTheme.instance.roundedButtonTheme)
        if let gif = try? UIImage(gifName: "bluesea.gif", levelOfIntegrity: .default) {
            animation.setGifImage(gif, loopCount: -1)
            animation.contentMode = .scaleToFill
        }
    }
    
    @IBAction func gotoLoginController() {
        self.performSegue(withIdentifier: goToLoginControllerSegue, sender: nil)
    }
    
    func gotoLocationsController() {
        self.performSegue(withIdentifier: goToLocationsControllerSegue, sender: nil)
    }
    
    public func checkSession() -> Bool {
        CurrentUser().getToken() != nil
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout
                            collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
            CGSize(width: collectionView.frame.size.width, height: collectionView.frame.size.height)
        }
    
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        pageControl.currentPage = indexPath.row
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.register(UINib.init(nibName: tutorialCellFile,
                 bundle: Bundle.main),
                                forCellWithReuseIdentifier: tutorialCellId)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: tutorialCellId,
                                                  for: indexPath) as? TutorialCell
        let instructions = dataSource[indexPath.row]
        cell!.title.text = instructions["title"]
        cell!.instructions.text = instructions["instructions"]
        cell!.instructions.numberOfLines = 0
        cell!.instructions.sizeToFit()
        return cell ?? UICollectionViewCell()
    }
}
    
let tutorialCellId = "tutorialCellId"
let tutorialCellFile = "TutorialInstructions"

class TutorialCell: UICollectionViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var instructions: UILabel!
}
