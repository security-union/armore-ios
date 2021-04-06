//
//  FriendsTablePresenter.swift
//   Armore
//
//  Created by Dario Talarico on 6/11/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation
import RxSwift

class FriendsTablePresenter {
    var friendsTableState: Observable<FriendsTableState> = UIState.instance.friendsTableState
    var connections: Observable<ApiResponse<Connections>?> = LocationPusher.instance.connections
    var refreshState: Observable<RefreshState> = LocationPusher.instance.refreshState

    func setSelectedUser(_ username: String?) {
        UIState.instance.setSelectedUser(username)
    }

    func forceRefresh() {
        LocationPusher.instance.forcePushLocation()
    }
}
