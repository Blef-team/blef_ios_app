//
//  newGame.swift
//  Blef
//
//  Created by Adrian Golian on 17.04.20.
//  Copyright © 2020 Blef Team.
//

import Foundation

struct NewGame {
    var uuid: UUID?
}

extension NewGame {
    init?(json: JSON) {
        guard let uuidString = json["game_uuid"] as? String, let uuid = UUID(uuidString: uuidString) else {
            return nil
        }
        self.uuid = uuid
    }
}
