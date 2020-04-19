//
//  Game.swift
//  Blef
//
//  Created by Adrian Golian on 18.04.20.
//  Copyright © 2020 Blef. All rights reserved.
//

import Foundation

struct Game {
    var adminNickname: String?
    var isPublic: Bool
    var status: Status
    var roundNumber: Int
    var maxCards: Int
    var players: [Player]
    var hands: [NamedHand]
    var currentPlayerNickname: String?
    var history: [HistoryItem]
}

extension Game {
    init?(json: JSON) {
        if let adminNickname = json["admin_nickname"] as? String {
            self.adminNickname = adminNickname
        }
        
        guard let isPublic = json["public"] as? Int else {
            return nil
        }
        self.isPublic = isPublic != 0
        
        guard let statusString = json["status"] as? String, let status = Status(rawValue: statusString) else {
            return nil
        }
        self.status = status
        
        guard let roundNumber = json["round_number"] as? Int else {
            return nil
        }
        self.roundNumber = roundNumber
        
        guard let maxCards = json["max_cards"] as? Int else {
            return nil
        }
        self.maxCards = maxCards
        
        guard let players = json["players"] as? [Player] else {
            return nil
        }
        self.players = players
        
        guard let hands = json["hands"] as? [NamedHand] else {
            return nil
        }
        self.hands = hands
        
        if let currentPlayerNickname = json["cp_nickname"] as? String {
            self.currentPlayerNickname = currentPlayerNickname
        }
        
        guard let history = json["history"] as? [HistoryItem] else {
            return nil
        }
        self.history = history
    }
}

struct Player {
      let nickname: String
      let n_cards: Int
}

struct NamedHand {
    let nickname: String
    let hand: [Card]
}

struct Card {
    enum Value {
        case nine, ten, jack, queen, king, ace
    }
    enum Colour {
        case clubs, diamonds, hearts, spades
    }
    let value: Value
    let colour: Colour
}

struct HistoryItem {
    let player: String
    let actionId: Action
}

enum Status: String {
    case notStarted = "Not started"
    case running = "Running"
    case finished = "Finished"
}

enum Action {
    case highCard9
    case highCard10
    case highCardJ
    case highCardQ
    case highCardK
    case highCardA
    case pairOf9s
    case pairOf10s
    case pairOfJs
    case pairOfQs
    case pairOfKs
    case pairOfAs
    case twoPairs10sAnd9s
    case twoPairsJsAnd9s
    case twoPairsJsAnd10s
    case twoPairsQsAnd9s
    case twoPairsQsAnd10s
    case twoPairsQsAndJs
    case twoPairsKsAnd9s
    case twoPairsKsAnd10s
    case twoPairsKsAndJs
    case twoPairsKsAndQs
    case twoPairsAsAnd9s
    case twoPairsAsAnd10s
    case twoPairsAsAndJs
    case twoPairsAsAndQs
    case twoPairsAsAndKs
    case smallStraight
    case bigStraight
    case greatStraight
    case three9s
    case three10s
    case threeJs
    case threeQs
    case threeKs
    case threeAs
    case fullHouse9sOn10s
    case fullHouse9sOnJs
    case fullHouse9sOnQs
    case fullHouse9sOnKs
    case fullHouse9sOnAs
    case fullHouse10sOn9s
    case fullHouse10sOnJs
    case fullHouse10sOnQs
    case fullHouse10sOnKs
    case fullHouse10sOnAs
    case fullHouseJsOn9s
    case fullHouseJsOn10s
    case fullHouseJsOnQs
    case fullHouseJsOnKs
    case fullHouseJsOnAs
    case fullHouseQsOn9s
    case fullHouseQsOn10s
    case fullHouseQsOnJs
    case fullHouseQsOnKs
    case fullHouseQsOnAs
    case fullHouseKsOn9s
    case fullHouseKsOn10s
    case fullHouseKsOnJs
    case fullHouseKsOnQs
    case fullHouseKsOnAs
    case fullHouseAsOn9s
    case fullHouseAsOn10s
    case fullHouseAsOnJs
    case fullHouseAsOnQs
    case fullHouseAsOnKs
    case colourClubs
    case colourDiamonds
    case colourHearts
    case colourSpades
    case four9s
    case four10s
    case fourJs
    case fourQs
    case fourKs
    case fourAs
    case smallFlushClubs
    case smallFlushDiamonds
    case smallFlushHearts
    case smallFlushSpades
    case bigFlushClubs
    case bigFlushDiamonds
    case bigFlushHearts
    case bigFlushSpades
    case greatFlushClubs
    case greatFlushDiamonds
    case greatFlushHearts
    case greatFlushSpades
    case check
}
