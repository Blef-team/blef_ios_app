//
//  Game.swift
//  Blef
//
//  Created by Adrian Golian on 18.04.20.
//  Copyright © 2020 Blef Team.
//

import Foundation

struct Game {
    var adminNickname: String?
    var isPublic: Bool
    var status: Status
    var roundNumber: Int
    var maxCards: Int
    var players: [PlayerInfo]?
    var hands: [NamedHand]?
    var currentPlayerNickname: String?
    var history: [HistoryItem]?
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
        
        if let playersJson = json["players"] as? [Dictionary<String, Any>] {
            if let players = playersJson.map({ PlayerInfo(json: $0)}) as? [PlayerInfo] {
                self.players = players
            }
        }
        
        if let handsJson = json["hands"] as? [Dictionary<String, Any>] {
            if let hands = handsJson.map({ NamedHand(json: $0)}) as? [NamedHand] {
                self.hands = hands
            }
        }
        
        if let currentPlayerNickname = json["cp_nickname"] as? String {
            self.currentPlayerNickname = currentPlayerNickname
        }
        
        if let historyJson = json["history"] as? [Dictionary<String, Any>] {
            if let history = historyJson.map({ HistoryItem(json: $0)}) as? [HistoryItem] {
                self.history = history
            }
        }
    }
}

struct PlayerInfo {
    let nickname: String
    let nCards: Int
    
    init?(json: Dictionary<String, Any>) {
        guard let nickname = json["nickname"] as? String else {
            return nil
        }
        self.nickname = nickname
        guard let nCards = json["n_cards"] as? Int else {
            return nil
        }
        self.nCards = nCards
    }
}

struct NamedHand {
    let nickname: String
    let hand: [Card]
    
    init?(json: Dictionary<String, Any>) {
        print("GOING TO PARSE A HAND:")
        guard let nickname = json["nickname"] as? String else {
            return nil
        }
        print(nickname)
        self.nickname = nickname
        print(json["hand"] as? [Dictionary<String, Any>])
        guard let handJson = json["hand"] as? [Dictionary<String, Int>], let hand = handJson.map({ Card(json: $0)}) as? [Card] else {
            return nil
        }
        self.hand = hand
    }
}

struct Card {
    enum Value: Int {
        case nine, ten, jack, queen, king, ace
    }
    enum Colour: Int {
        case clubs, diamonds, hearts, spades
    }
    let value: Value
    let colour: Colour
    
    init?(json: Dictionary<String, Int>) {
        print("MAPPING A CARD:")
        guard let jsonValue = json["value"], let value = Value(rawValue: jsonValue) else {
            return nil
        }
        print(value)
        self.value = value
        guard let jsonColour = json["colour"], let colour = Colour(rawValue: jsonColour) else {
            return nil
        }
        print(colour)
        self.colour = colour
    }
}

struct HistoryItem {
    let player: String
    let action: Action
    
    init?(json: Dictionary<String, Any>) {
        guard let player = json["player"] as? String else {
            return nil
        }
        self.player = player
        guard let actionId = json["action_id"] as? Int, let action = Action(rawValue: actionId) else {
            return nil
        }
        self.action = action
    }
}

enum Status: String {
    case notStarted = "Not started"
    case running = "Running"
    case finished = "Finished"
}

enum Action: Int, CaseIterable {
    case highCard9 = 0
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
