//
//  Annotations.swift
//  RescueLink
//
//  Created by Dario Lencina on 4/3/21.
//  Copyright © 2021 Security Union. All rights reserved.
//

import Foundation
import MapKit
import UIKit

class MyAnnotation: NSObject, MKAnnotation {
    var owner: Friend?
    var image: UIImage?
    dynamic var title: String?
    dynamic var subtitle: String?
    dynamic var coordinate: CLLocationCoordinate2D

    init(owner: Friend,
         title: String,
         subtitle: String,
         coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.owner = owner
        image = ImageProfile().getImageOrDownloadIt(self.owner?.userDetails)
                ?? UIImage(named: DEFAULT_PLACEHODER_IMAGE)
    }

    init(title: String, subtitle: String, coordinates: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinates
    }
}

class ImageAnnotationView: MKAnnotationView {
    dynamic private var imageView: UIImageView!

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        self.imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        self.addSubview(self.imageView)
        self.imageView.layer.cornerRadius = 5.0
        self.imageView.tintColor = UIColor.brandedBlack()
        self.imageView.layer.masksToBounds = true
    }

    func setBorderColor(color: UIColor) {
        self.imageView.roundedImageWith(color: color, borderWidth: 3)
    }

    override var image: UIImage? {
        get {
            self.imageView.image
        }
        set {
            self.imageView.image = newValue
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
