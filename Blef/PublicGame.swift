//
//  PublicGame.swift
//  Blef
//
//  Created by Adrian Golian on 06/01/2022.
//  Copyright © 2022 Blef. All rights reserved.
//

import Foundation

struct PublicGame {
    var uuid: UUID
    var room: Int
    var players: [PlayerInfo]?
    var lastModified: Int
}

extension PublicGame {
    init?(json: JSON) {
        guard let room = json["room"] as? Int else {
            return nil
        }
        self.room = room
        
        guard let uuidString = json["game_uuid"] as? String, let uuid = UUID(uuidString: uuidString) else {
            return nil
        }
        self.uuid = uuid
        
        if let playersJson = json["players"] as? [Dictionary<String, Any>] {
            if let players = playersJson.map({ PlayerInfo(json: $0)}) as? [PlayerInfo] {
                self.players = players
            }
        }
        
        guard let lastModified = json["last_modified"] as? Int else {
            return nil
        }
        self.lastModified = lastModified
    }
}
