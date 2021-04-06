//
//  Image.swift
//   Armore
//
//  Created by Security Union on 11/12/19.
//  Copyright © 2019 Security Union. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

class ImageProfile {

    func getImageWithId(imageId: String, userToken: String, completion: @escaping (Response) -> Void) {

        let urls = URLs()
        let req = Request()

        let requestParameters = [String: Any]()
        let requestHeaders: HTTPHeaders = [TOKEN_HEADER: userToken]
        req.requestImage(url: urls.imageWithId(imageId: imageId),
                headers: requestHeaders,
                parameters: requestParameters,
                methodType: .get) { (response) in
            if response.success {
                if let imageResponse = response.oneReturned as? UIImage {
                    completion(Response(success: true, oneReturned: imageResponse))
                } else {
                    completion(Response(success: false, errorMessage: "unable to decode image"))
                }
            } else {
                completion(Response(success: false, errorMessage: response.errorMessage))
            }
        }
    }

    func getImageOrDownloadIt(_ user: UserDetails?) -> UIImage? {
        if let picture = user?.picture, let img = getImage(withName: picture) {
            return img
        } else if let picture = user?.picture,
                  let token = CurrentUser().getToken(), picture.count > 0 {
            self.getImageWithId(imageId: picture, userToken: token) { (response) in
                if let imageResponse = response.oneReturned as? UIImage, response.success {
                    imageResponse.saveImage(withName: picture)
                }
            }
        }
        return nil
    }

    func getImage(withName name: String) -> UIImage? {
        return (try? FileManager.default.url(for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false)).flatMap { dir in
            UIImage(contentsOfFile: URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(name).path)
        }
    }

    func saveUserImage(image: UIImage, withName name: String) {
        image.saveImage(withName: name)
    }
}
