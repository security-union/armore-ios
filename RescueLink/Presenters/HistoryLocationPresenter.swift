//
//  HistoryLocationPresenter.swift
//   Armore
//
//  Created by Security Union on 24/03/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation
import Alamofire

class HistoryLocationPresenter: CurrentUser {

    weak private var historyLocationDelegate: HistoricalLocationController?
    let req = Request()
    private var activity: CoolActivityIndicator?

    func setViewDelegate(historyLocationDelegate: HistoricalLocationController) {
        self.activity = CoolActivityIndicator(currentController: historyLocationDelegate)
        self.historyLocationDelegate = historyLocationDelegate
        req.setViewDelegate(viewDelegate: historyLocationDelegate)
    }

    func getHistoricalLocation(startTime: String, endTime: String, username: String) {
        let requestParameters: [String: Any] = ["start_time": startTime, "end_time": endTime]
        activity?.startAnimating()
        AF.request(URLs().locationHistory(
            username: username),
            parameters: requestParameters,
            headers: addBaseHeaders([])).responseJSON { response in
                self.activity?.stopAnimating()
                if response.data != nil {
                    if let dict = String(decoding: response.data!, as: UTF8.self).convertToDictionary() {
                        let parsedResponse = HistoricalLocationResponse(result: dict)
                        self.decryptHistoricalResponse(response: parsedResponse)
                        return
                    } else {
                        self.noHistoricalData()
                    }
                } else {
                    self.noHistoricalData()
                }
            }
    }
    
    func noHistoricalData() {
        self.historyLocationDelegate?.showErrorAndDismiss(
                title: NSLocalizedString("Historical location data error", comment: ""),
                message: String(format: NSLocalizedString("history_location_no_data",
                        comment: ""),
                    self.historyLocationDelegate?.user?.completeName() ?? ""))
    }
    
    func decryptHistoricalResponse(response: HistoricalLocationResponse) {
        var decryptedLocations = HistoricalLocation(locations: [])
        response.data.forEach { loc in
            if let decodedLocation = Crypto.decryptLocation(loc.data) {
                decryptedLocations.locations
                    .append(LocationsForHistory(
                                location: decodedLocation,
                                deviceId: loc.deviceId,
                                timestamp: loc.timestamp)
                    )
            }
        }

        if decryptedLocations.locations.count == 0 {
                // wasn't possible to decrypt locations
                self.historyLocationDelegate?.showErrorAndDismiss(
                        title: NSLocalizedString("Historical location data error",
                                comment: ""),
                        message: String(format: NSLocalizedString("history_location_no_data_2",
                                comment: ""),
                                self.historyLocationDelegate?.user?.completeName() ?? ""))
        } else {
            self.historyLocationDelegate?.gotHistoryData(historyLocations: decryptedLocations)
        }
    }
}
