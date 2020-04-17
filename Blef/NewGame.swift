//
//  newGame.swift
//  Blef
//
//  Created by Adrian Golian on 17.04.20.
//  Copyright © 2020 Blef Team.
//

import Foundation

struct NewGame {
    var game_uuid: String
}

extension NewGame {
    init?(json: JSON) {
        guard let game_uuid = json["game_uuid"] as? String else {
            return nil
        }
        self.game_uuid = game_uuid
    }
}
