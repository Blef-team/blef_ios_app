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
    var room: Int?
    var isPublic: Bool
    var status: Status
    var roundNumber: Int
    var maxCards: Int
    var players: [PlayerInfo]?
    var hands: [NamedHand]?
    var currentPlayerNickname: String?
    var history: [HistoryItem]?
    var lastModified: Double
    var losingPlayer: String?
}

extension Game {
    init?(json: JSON) {
        if let adminNickname = json["admin_nickname"] as? String {
            self.adminNickname = adminNickname
        }
        
        if let room = json["room"] as? Int {
            self.room = room
        }
        
        guard let isPublicString = json["public"] as? String else {
            return nil
        }
        self.isPublic = isPublicString == "true"
        
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
        
        if let lastModified = json["last_modified"] as? Double {
            self.lastModified = lastModified
        } else {
            if let lastModified = json["last_modified"] as? Int {
                self.lastModified = Double(lastModified)
            } else {
                return nil
            }
        }
        
        if let historyJson = json["history"] as? [Dictionary<String, Any>] {
            if historyJson.count > 1 {
                if let player = historyJson.last?["player"] as? String, let actionId = historyJson.last?["action_id"] as? Int {
                    if actionId == 89 && Action(rawValue: actionId) == nil {
                        self.losingPlayer = player
                    }
                }
            }
        }
    }
}

struct PlayerInfo {
    let nickname: String
    let nCards: Int
    
    init?(json: JSON) {
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
    
    init?(json: JSON) {
        guard let nickname = json["nickname"] as? String else {
            return nil
        }
        self.nickname = nickname
        guard let handJson = json["hand"] as? [Dictionary<String, Int>], let hand = handJson.map({ Card($0)}) as? [Card] else {
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
    
    init?(_ json: Dictionary<String, Int>) {
        guard let jsonValue = json["value"], let value = Value(rawValue: jsonValue) else {
            return nil
        }
        self.value = value
        guard let jsonColour = json["colour"], let colour = Colour(rawValue: jsonColour) else {
            return nil
        }
        self.colour = colour
    }
}

struct HistoryItem {
    let player: String
    let action: Action
    
    init?(json: JSON) {
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
    case fullHouse9sOver10s
    case fullHouse9sOverJs
    case fullHouse9sOverQs
    case fullHouse9sOverKs
    case fullHouse9sOverAs
    case fullHouse10sOver9s
    case fullHouse10sOverJs
    case fullHouse10sOverQs
    case fullHouse10sOverKs
    case fullHouse10sOverAs
    case fullHouseJsOver9s
    case fullHouseJsOver10s
    case fullHouseJsOverQs
    case fullHouseJsOverKs
    case fullHouseJsOverAs
    case fullHouseQsOver9s
    case fullHouseQsOver10s
    case fullHouseQsOverJs
    case fullHouseQsOverKs
    case fullHouseQsOverAs
    case fullHouseKsOver9s
    case fullHouseKsOver10s
    case fullHouseKsOverJs
    case fullHouseKsOverQs
    case fullHouseKsOverAs
    case fullHouseAsOver9s
    case fullHouseAsOver10s
    case fullHouseAsOverJs
    case fullHouseAsOverQs
    case fullHouseAsOverKs
    case flushClubs
    case flushDiamonds
    case flushHearts
    case flushSpades
    case four9s
    case four10s
    case fourJs
    case fourQs
    case fourKs
    case fourAs
    case smallStraightFlushClubs
    case smallStraightFlushDiamonds
    case smallStraightFlushHearts
    case smallStraightFlushSpades
    case bigStraightFlushClubs
    case bigStraightFlushDiamonds
    case bigStraightFlushHearts
    case bigStraightFlushSpades
    case greatStraightFlushClubs
    case greatStraightFlushDiamonds
    case greatStraightFlushHearts
    case greatStraightFlushSpades
    case check
    
    var description: String {
        switch self {
        case .highCard9:
           return NSLocalizedString("highCard9", comment: "High card 9")
        case .highCard10:
            return NSLocalizedString("highCard10", comment: "High card 10")
        case .highCardJ:
            return NSLocalizedString("highCardJ", comment: "High card Jack")
        case .highCardQ:
            return NSLocalizedString("highCardQ", comment: "High card Queen")
        case .highCardK:
            return NSLocalizedString("highCardK", comment: "High card King")
        case .highCardA:
            return NSLocalizedString("highCardA", comment: "High card Ace")
        case .pairOf9s:
            return NSLocalizedString("pairOf9s", comment: "Pair of 9s")
        case .pairOf10s:
            return NSLocalizedString("pairOf10s", comment: "Pair of 10s")
        case .pairOfJs:
            return NSLocalizedString("pairOfJs", comment: "Pair of Jacks")
        case .pairOfQs:
            return NSLocalizedString("pairOfQs", comment: "Pair of Queens")
        case .pairOfKs:
            return NSLocalizedString("pairOfKs", comment: "Pair of Kings")
        case .pairOfAs:
            return NSLocalizedString("pairOfAs", comment: "Pair of Aces")
        case .twoPairs10sAnd9s:
            return NSLocalizedString("twoPairs10sAnd9s", comment: "Two pair, 10s and 9s")
        case .twoPairsJsAnd9s:
            return NSLocalizedString("twoPairsJsAnd9s", comment: "Two pair, Jacks and 9s")
        case .twoPairsJsAnd10s:
            return NSLocalizedString("twoPairsJsAnd10s", comment: "Two pair, Jacks and 10s")
        case .twoPairsQsAnd9s:
            return NSLocalizedString("twoPairsQsAnd9s", comment: "Two pair, Queens and 9s")
        case .twoPairsQsAnd10s:
            return NSLocalizedString("twoPairsQsAnd10s", comment: "Two pair, Queens and 10s")
        case .twoPairsQsAndJs:
            return NSLocalizedString("twoPairsQsAndJs", comment: "Two pair, Queens and Jacks")
        case .twoPairsKsAnd9s:
            return NSLocalizedString("twoPairsKsAnd9s", comment: "Two pair, Kings and 9s")
        case .twoPairsKsAnd10s:
            return NSLocalizedString("twoPairsKsAnd10s", comment: "Two pair, Kings and 10s")
        case .twoPairsKsAndJs:
            return NSLocalizedString("twoPairsKsAndJs", comment: "Two pair, Kings and Jacks")
        case .twoPairsKsAndQs:
            return NSLocalizedString("twoPairsKsAndQs", comment: "Two pair, Kings and Queens")
        case .twoPairsAsAnd9s:
            return NSLocalizedString("twoPairsAsAnd9s", comment: "Two pair, Aces and 9s")
        case .twoPairsAsAnd10s:
            return NSLocalizedString("twoPairsAsAnd10s", comment: "Two pair, Aces and 10s")
        case .twoPairsAsAndJs:
            return NSLocalizedString("twoPairsAsAndJs", comment: "Two pair, Aces and Jacks")
        case .twoPairsAsAndQs:
            return NSLocalizedString("twoPairsAsAndQs", comment: "Two pair, Aces and Queens")
        case .twoPairsAsAndKs:
            return NSLocalizedString("twoPairsAsAndKs", comment: "Two pair, Aces and Kings")
        case .smallStraight:
            return NSLocalizedString("smallStraight", comment: "Small straight (9-King)")
        case .bigStraight:
            return NSLocalizedString("bigStraight", comment: "Big straight (10-Ace)")
        case .greatStraight:
            return NSLocalizedString("greatStraight", comment: "Great straight (9-Ace)")
        case .three9s:
            return NSLocalizedString("three9s", comment: "Three 9s")
        case .three10s:
            return NSLocalizedString("three10s", comment: "Three 10s")
        case .threeJs:
            return NSLocalizedString("threeJs", comment: "Three Jacks")
        case .threeQs:
            return NSLocalizedString("threeQs", comment: "Three Queens")
        case .threeKs:
            return NSLocalizedString("threeKs", comment: "Three Kings")
        case .threeAs:
            return NSLocalizedString("threeAs", comment: "Three Aces")
        case .fullHouse9sOver10s:
            return NSLocalizedString("fullHouse9sOver10s", comment: "Full house, 9s over 10s")
        case .fullHouse9sOverJs:
            return NSLocalizedString("fullHouse9sOverJs", comment: "Full house, 9s over Jacks")
        case .fullHouse9sOverQs:
            return NSLocalizedString("fullHouse9sOverQs", comment: "Full house, 9s over Queens")
        case .fullHouse9sOverKs:
            return NSLocalizedString("fullHouse9sOverKs", comment: "Full house, 9s over Kings")
        case .fullHouse9sOverAs:
            return NSLocalizedString("fullHouse9sOverAs", comment: "Full house, 9s over Aces")
        case .fullHouse10sOver9s:
            return NSLocalizedString("fullHouse10sOver9s", comment: "Full house, 10s over 9s")
        case .fullHouse10sOverJs:
            return NSLocalizedString("fullHouse10sOverJs", comment: "Full house, 10s over Jacks")
        case .fullHouse10sOverQs:
            return NSLocalizedString("fullHouse10sOverQs", comment: "Full house, 10s over Queens")
        case .fullHouse10sOverKs:
            return NSLocalizedString("fullHouse10sOverKs", comment: "Full house, 10s over Kings")
        case .fullHouse10sOverAs:
            return NSLocalizedString("fullHouse10sOverAs", comment: "Full house, 10s over Aces")
        case .fullHouseJsOver9s:
            return NSLocalizedString("fullHouseJsOver9s", comment: "Full house, Jacks over 9s")
        case .fullHouseJsOver10s:
            return NSLocalizedString("fullHouseJsOver10s", comment: "Full house, Jacks over 10s")
        case .fullHouseJsOverQs:
            return NSLocalizedString("fullHouseJsOverQs", comment: "Full house, Jacks over Queens")
        case .fullHouseJsOverKs:
            return NSLocalizedString("fullHouseJsOverKs", comment: "Full house, Jacks over Kings")
        case .fullHouseJsOverAs:
            return NSLocalizedString("fullHouseJsOverAs", comment: "Full house, Jacks over Aces")
        case .fullHouseQsOver9s:
            return NSLocalizedString("fullHouseQsOver9s", comment: "Full house, Queens over 9s")
        case .fullHouseQsOver10s:
            return NSLocalizedString("fullHouseQsOver10s", comment: "Full house, Queens over 10s")
        case .fullHouseQsOverJs:
            return NSLocalizedString("fullHouseQsOverJs", comment: "Full house, Queens over Jacks")
        case .fullHouseQsOverKs:
            return NSLocalizedString("fullHouseQsOverKs", comment: "Full house, Queens over Kings")
        case .fullHouseQsOverAs:
            return NSLocalizedString("fullHouseQsOverAs", comment: "Full house, Queens over Aces")
        case .fullHouseKsOver9s:
            return NSLocalizedString("fullHouseKsOver9s", comment: "Full house, Kings over 9s")
        case .fullHouseKsOver10s:
            return NSLocalizedString("fullHouseKsOver10s", comment: "Full house, Kings over 10s")
        case .fullHouseKsOverJs:
            return NSLocalizedString("fullHouseKsOverJs", comment: "Full house, Kings over Jacks")
        case .fullHouseKsOverQs:
            return NSLocalizedString("fullHouseKsOverQs", comment: "Full house, Kings over Queens")
        case .fullHouseKsOverAs:
            return NSLocalizedString("fullHouseKsOverAs", comment: "Full house, Kings over Aces")
        case .fullHouseAsOver9s:
            return NSLocalizedString("fullHouseAsOver9s", comment: "Full house, Aces over 9s")
        case .fullHouseAsOver10s:
            return NSLocalizedString("fullHouseAsOver10s", comment: "Full house, Aces over 10s")
        case .fullHouseAsOverJs:
            return NSLocalizedString("fullHouseAsOverJs", comment: "Full house, Aces over Jacks")
        case .fullHouseAsOverQs:
            return NSLocalizedString("fullHouseAsOverQs", comment: "Full house, Aces over Queens")
        case .fullHouseAsOverKs:
            return NSLocalizedString("fullHouseAsOverKs", comment: "Full house, Aces over Kings")
        case .flushClubs:
            return NSLocalizedString("flushClubs", comment: "Flush of ♣")
        case .flushDiamonds:
            return  NSLocalizedString("flushDiamonds", comment: "Flush of ♦")
        case .flushHearts:
            return  NSLocalizedString("flushHearts", comment: "Flush of ♥")
        case .flushSpades:
            return NSLocalizedString("flushSpades", comment: "Flush of ♠")
        case .four9s:
            return NSLocalizedString("four9s", comment: "Four 9s")
        case .four10s:
            return NSLocalizedString("four10s", comment: "Four 10s")
        case .fourJs:
            return NSLocalizedString("fourJs", comment: "Four Jacks")
        case .fourQs:
            return NSLocalizedString("fourQs", comment: "Four Queens")
        case .fourKs:
            return NSLocalizedString("fourKs", comment: "Four Kings")
        case .fourAs:
            return NSLocalizedString("fourAs", comment: "Four Aces")
        case .smallStraightFlushClubs:
            return NSLocalizedString("smallStraightFlushClubs", comment: "Small straight flush (9-King) ♣")
        case .smallStraightFlushDiamonds:
            return NSLocalizedString("smallStraightFlushDiamonds", comment: "Small straight flush (9-King) ♦")
        case .smallStraightFlushHearts:
            return NSLocalizedString("smallStraightFlushHearts", comment: "Small straight flush (9-King) ♥")
        case .smallStraightFlushSpades:
            return NSLocalizedString("smallStraightFlushSpades", comment: "Small straight flush (9-King) ♠")
        case .bigStraightFlushClubs:
            return NSLocalizedString("bigStraightFlushClubs", comment: "Big straight flush (10-Ace) ♣")
        case .bigStraightFlushDiamonds:
            return NSLocalizedString("bigStraightFlushDiamonds", comment: "Big straight flush (10-Ace) ♦")
        case .bigStraightFlushHearts:
            return NSLocalizedString("bigStraightFlushHearts", comment: "Big straight flush (10-Ace) ♥")
        case .bigStraightFlushSpades:
            return NSLocalizedString("bigStraightFlushSpades", comment: "Big straight flush (10-Ace) ♠")
        case .greatStraightFlushClubs:
            return NSLocalizedString("greatStraightFlushClubs", comment: "Great straight flush (9-Ace) ♣")
        case .greatStraightFlushDiamonds:
            return NSLocalizedString("greatStraightFlushDiamonds", comment: "Great straight flush (9-Ace) ♦")
        case .greatStraightFlushHearts:
            return NSLocalizedString("greatStraightFlushHearts", comment: "Great straight flush (9-Ace) ♥")
        case .greatStraightFlushSpades:
            return NSLocalizedString("greatStraightFlushSpades", comment: "Great straight flush (9-Ace) ♠")
        case .check:
            return NSLocalizedString("check", comment: "CHECK")
        }
    }
}
