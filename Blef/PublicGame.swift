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
    var players: [String]?
    var isPublic: Bool?
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
        
        if let players = json["players"] as? [String] {
            self.players = players
        }
        
        if let isPublicString = json["public"] as? String {
            self.isPublic = isPublicString == "true"
        }
        
        guard let lastModified = json["last_modified"] as? Int else {
            return nil
        }
        self.lastModified = lastModified
    }
}
