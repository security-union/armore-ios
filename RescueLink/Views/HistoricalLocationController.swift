//
//  HistoricalLocationController.swift
//   Armore
//
//  Created by Security Union on 24/03/20.
//  Copyright © 2021 Security Union. All rights reserved.
//

import UIKit
import MapKit

protocol HistoricalLocationProtocol {
    func gotHistoryData(historyLocations: HistoricalLocation)
    func showErrorAndDismiss(title: String, message: String)
}

class HistoricalLocationController: UIViewController, HistoricalLocationProtocol, MKMapViewDelegate,
                                    CLLocationManagerDelegate {
    var user: Friend?
    var historyLocation: HistoricalLocation?
    var historicalLocationPresenter = HistoryLocationPresenter()
    var daysSelected = 0

    func gotHistoryData(historyLocations: HistoricalLocation) {
        self.historyLocation = historyLocations

        let locationsToShow = getOnlyLocationsCoordinate(histLocations: historyLocations)
        let polyline = MKPolyline(coordinates: locationsToShow, count: locationsToShow.count)

        map.removeOverlays(map.overlays)
        map.addOverlay(polyline)

        sliderOutlet.minimumValue = 0
        sliderOutlet.maximumValue = Float(locationsToShow.count - 1)
        sliderOutlet.setValue(Float(locationsToShow.count / 3), animated: true)

        if let firstLocation = historyLocation?.locations.first {
            sliderOutlet.isHidden = false

            let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: firstLocation.location.lat,
                    longitude: firstLocation.location.lon),
                    span: defaultZoom)
            map.setRegion(region, animated: true)

            if let userToShow = user {
                let annotation = MyAnnotation(owner: userToShow,
                        title: userToShow.userDetails?.firstName ?? "",
                        subtitle: NSLocalizedString("History Location", comment: ""),
                        coordinate: locationsToShow.first ?? region.center)
                map.removeAnnotations(map.annotations)
                map.addAnnotation(annotation)

                displayLocationAndLabel()
            }

        } else {
            // no locations on these time
            sliderOutlet.isHidden = true
            headerLabel.text = NSLocalizedString("No locations on selected time", comment: "")
        }

    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !annotation.isKind(of: MKUserLocation.self) else {
            return nil
        }
        let identifier = "marker"
        if #available(iOS 11.0, *) {
            var view: ImageAnnotationView? =
                    mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                            as? ImageAnnotationView
            if view == nil {
                view = ImageAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }

            if let annotation = annotation as? MyAnnotation {
                view?.setBorderColor(color: UIColor.brandedGray())
                view?.image = ImageProfile().getImageOrDownloadIt(annotation.owner?
                        .userDetails) ?? UIImage(named: DEFAULT_PLACEHODER_IMAGE)
            }

            return view
        } else {
            return nil
        }
    }

    func showErrorAndDismiss(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
            self.dismiss(animated: true, completion: nil)
        }))
        alert.display()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        historicalLocationPresenter.setViewDelegate(historyLocationDelegate: self)
        self.map.delegate = self
        
        // Configure Navigation Bar
        self.navigationController?.navigationBar.barTintColor = .darkGray
        self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        self.title = NSLocalizedString("Historical location", comment: "")
        if let completeName = user?.completeName() {
            self.title = String(format: NSLocalizedString("Historical location of %@",
                    comment: ""), completeName)
        }
        
        headerLabel.text = NSLocalizedString("Loading historical location", comment: "")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        var startDate = Date()
        startDate = startDate.daysBefore(numberOfDays: 7)
        startDate.addTimeInterval(TimeInterval.init(3600))
        getHistoricalLocationBetween(startTime: startDate, endTime: Date())
    }

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var sliderOutlet: UISlider!

    func getOnlyLocationsCoordinate(histLocations: HistoricalLocation) -> [CLLocationCoordinate2D] {
        return histLocations.locations.compactMap { loc in
            CLLocationCoordinate2D(latitude: loc.location.lat, longitude: loc.location.lon)
        }
    }

    func getReadableDate(timestamp: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DATE_FORMAT
        if let date = dateFormatter.date(from: timestamp) {
            dateFormatter.timeStyle = .short
            let timeString = dateFormatter.string(from: date)
            dateFormatter.timeStyle = .none
            dateFormatter.dateStyle = .medium
            let dateString = dateFormatter.string(from: date)
            return "\(dateString) \(timeString)"
        }
        return ""
    }

    func updateAnnotationLocation(coordinates: CLLocationCoordinate2D) {
        if let annotation = self.map.annotations.first as? MyAnnotation {
            annotation.coordinate = coordinates
        }
    }

    func centerMapOn(coordinates: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: coordinates, span: defaultZoom)
        map.setRegion(region, animated: true)
    }

    func displayLocationAndLabel() {
        if let historyValue = historyLocation?.locations[Int(sliderOutlet.value)] {
            headerLabel.text = getReadableDate(timestamp: historyValue.timestamp)
            let coordinates = CLLocationCoordinate2D(latitude: historyValue.location.lat,
                                                     longitude: historyValue.location.lon)
            updateAnnotationLocation(coordinates: coordinates)
            centerMapOn(coordinates: coordinates)
        }
    }

    func getHistoricalLocationBetween(startTime: Date, endTime: Date?) {
        if let username = user?.userDetails?.username {
            let start = startTime.iso8601withFractionalSeconds
            let end = endTime?.iso8601withFractionalSeconds ?? Date().iso8601withFractionalSeconds
            historicalLocationPresenter.getHistoricalLocation(startTime: start, endTime: end, username: username)
        } else {
            showErrorAndDismiss(title: "Failure", message: "Could not find a username")
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let polylineRender = MKPolylineRenderer(overlay: overlay)
            polylineRender.strokeColor = UIColor.red.withAlphaComponent(0.6)
            polylineRender.lineWidth = 5
            return polylineRender
        }
        return MKOverlayRenderer()
    }

    @IBAction func sliderAction(_ sender: Any) {
        displayLocationAndLabel()
    }
}
