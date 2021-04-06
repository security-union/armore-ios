//
//  FriendDetailsTablePresenter.swift
//   Armore
//
//  Created by Dario Talarico on 6/14/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import UIKit

public class FriendDetailsTablePresenter {

    func newAccessType(user: Friend, newAccessType: AccessType) {
        UIState.instance.newAccessType(user: user, newAccessType: newAccessType)
    }
    
    func removeFriend(user: Friend) {
        UIState.instance.removeFriend(user: user)
    }
}
