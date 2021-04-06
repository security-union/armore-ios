//
//  UserDetailsPresenter.swift
//   Armore
//
//  Created by Dario Talarico on 6/11/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation
import RxSwift

class UserDetailsPresenter {
    let selectedUser: Observable<DetailTable?> = UIState.instance.selectedUser
    let friends: BehaviorSubject<ApiResponse<Connections>?> = LocationPusher.instance.connections
    let friendsTableState: Observable<FriendsTableState> = UIState.instance.friendsTableState
    let isUserDetailsLoading: Observable<Bool> = UIState.instance.isUserDetailsLoading

    // If username is nil then the UserDetails are dismissed.
    // To refocus the map, just call this method with the same username.
    func setSelectedUser(_ username: String?) {
        UIState.instance.setSelectedUser(username)
    }

    func toggleFriendsTableState() {
        UIState.instance.toggleTableState()
    }

    func toggleTableState() {
        UIState.instance.toggleTableState()
    }
}
