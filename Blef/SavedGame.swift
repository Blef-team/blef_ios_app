//
//  SavedGame.swift
//  Blef
//
//  Created by Adrian Golian on 28/01/2022.
//  Copyright © 2022 Blef. All rights reserved.
//

import Foundation

let SavedGamesKey = "savedGames"

struct SavedGame {
    var gameUuid: UUID
    var playerUuid: UUID
    var playerNickname: String
    var lastModified: Double
    var status: Status
    var serialised: [String: String] {
        return ["gameUuid": gameUuid.uuidString,
                "playerUuid": playerUuid.uuidString,
                "playerNickname": playerNickname,
                "lastModified": String(lastModified),
                "status": status.rawValue]
    }
}

typealias SavedGamesDict = [String: SavedGame]

extension SavedGame {
    init?(json: JSON) {
        guard let uuidString = json["gameUuid"] as? String, let uuid = UUID(uuidString: uuidString) else {
            return nil
        }
        self.gameUuid = uuid

        guard let uuidString = json["playerUuid"] as? String, let uuid = UUID(uuidString: uuidString) else {
            return nil
        }
        self.playerUuid = uuid

        guard let nickname = json["playerNickname"] as? String else {
            return nil
        }
        self.playerNickname = nickname

        guard let statusString = json["status"] as? String, let status = Status(rawValue: statusString) else {
            return nil
        }
        self.status = status

        if let lastModifiedString = json["lastModified"] as? String, let lastModified = Double(lastModifiedString) {
            self.lastModified = lastModified

        } else {
            if let lastModifiedString = json["lastModified"] as? String, let lastModified = Int(lastModifiedString) {

                self.lastModified = Double(lastModified)
            } else {

                return nil
            }
        }
    }
    
    init?(game: Game, gameUuid: UUID, player: Player) {
        guard let nickname = player.nickname else {
            return nil
        }
        self.gameUuid = gameUuid
        self.playerUuid = player.uuid
        self.playerNickname = nickname
        self.status = game.status
        self.lastModified = game.lastModified
    }
}

