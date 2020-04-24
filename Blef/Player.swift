//
//  Player.swift
//  Blef
//
//  Created by Adrian Golian on 24.04.20.
//  Copyright © 2020 Blef. All rights reserved.
//

import Foundation

struct Player {
    var uuid: UUID
    var nickname: String?
}

extension Player {
    init?(json: JSON) {
        guard let uuidString = json["player_uuid"] as? String, let uuid = UUID(uuidString: uuidString) else {
            return nil
        }
        self.uuid = uuid
    }
}
