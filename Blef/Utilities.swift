//
//  Effects.swift
//  Blef
//
//  Created by Adrian Golian on 24.04.20.
//  Copyright © 2020 Blef. All rights reserved.
//

import SpriteKit

func pulseLabel (_ label: SKNode) {
    let pulseSequence = SKAction.sequence([
        SKAction.fadeAlpha(by: -0.7, duration: 0.1),
        SKAction.fadeAlpha(by: 0.7, duration: 0.2)
    ])
    label.run(pulseSequence)
}

func updateLabelText(_ label: SKLabelNode, _ newLabelText: String) {
    if label.text?.lowercased() != newLabelText.lowercased() {
        label.text = newLabelText
        fadeInNode(label)
    }
}

func fadeInNode(_ node: SKNode?) {
    if let node = node {
        node.alpha = 0.0
        node.run(SKAction.fadeIn(withDuration: 1.0))
    }
}

func fadeOutNode(_ node: SKNode?) {
    if let node = node {
        node.run(SKAction.fadeOut(withDuration: 1.0))
    }
}

func formatDisplayNickname(_ nickname: String) -> String {
    return nickname.replacingOccurrences(of: "_", with: " ")
}

func formatSerialisedNickname(_ nickname: String) -> String {
    return nickname.replacingOccurrences(of: " ", with: "_")
}

func playerIsCurrentPlayer(player: Player, game: Game) -> Bool {
    return player.nickname != "" && formatDisplayNickname(game.currentPlayerNickname ?? "") == formatDisplayNickname(player.nickname ?? "")
}

func stringifyCard(_ card: Card) -> String {
    return "\(card.value) of \(card.colour)"
}

func canStartGame(_ game: Game, _ player: Player, _ players: [PlayerInfo]?) -> Bool {
    return game.status == .notStarted && game.adminNickname == player.nickname && (players?.count ?? 0) >= 2 
}

func generatePlayerNickname() -> String {
    return "Haughty Hedgehog"
}
