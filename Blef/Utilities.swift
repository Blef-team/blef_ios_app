//
//  Effects.swift
//  Blef
//
//  Created by Adrian Golian on 24.04.20.
//  Copyright © 2020 Blef. All rights reserved.
//

import SpriteKit

extension Int {
    func times(_ f: () -> ()) {
        if self > 0 {
            for _ in 0..<self {
                f()
            }
        }
    }
    
    func times(_ f: @autoclosure () -> ()) {
        if self > 0 {
            for _ in 0..<self {
                f()
            }
        }
    }
}

extension SKNode {
    func addGlow(radius:CGFloat=10) {
        if hasEffect() {
            return
        }
        let view = SKView()
        let effectNode = SKEffectNode()
        let texture = view.texture(from: self)
        effectNode.shouldRasterize = true
        effectNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius":radius])
        addChild(effectNode)
        effectNode.addChild(SKSpriteNode(texture: texture))
    }
    func hasEffect() -> Bool {
        for child in self.children {
            if child is SKEffectNode {
                return true
            }
        }
        return false
    }
    func removeEffects() {
        for child in self.children {
            if child is SKEffectNode {
                child.removeFromParent()
            }
        }
    }
}

func pulseLabel (_ label: SKNode) {
    let pulseSequence = SKAction.sequence([
        SKAction.fadeAlpha(by: -0.7, duration: 0.1),
        SKAction.fadeAlpha(by: 0.7, duration: 0.2)
    ])
    label.run(pulseSequence)
}

func slowPulseLabel (_ label: SKNode) {
    let pulseSequence = SKAction.repeatForever(SKAction.sequence([
        SKAction.fadeAlpha(by: -0.7, duration: 0.5),
        SKAction.fadeAlpha(by: 0.7, duration: 0.5)
    ]))
    label.run(pulseSequence, withKey: "slowPulse")
}

func updateAndDisplayLabel (_ label: SKLabelNode, _ newLabelText: String) {
    updateLabelText(label, newLabelText)
    fadeInNode(label)
}

func updateLabelText(_ label: SKLabelNode, _ newLabelText: String) {
    if label.text?.lowercased() != newLabelText.lowercased() {
        label.text = newLabelText
    }
}

func fadeInNode(_ node: SKNode?) {
    if let node = node {
        node.removeAllActions()
        node.run(SKAction.fadeIn(withDuration: 1.0))
    }
}

func fadeOutNode(_ node: SKNode?) {
    if let node = node {
        node.removeAllActions()
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

func resetCardSprites(_ cardSprites: [SKSpriteNode]) {
    for sprite in cardSprites {
        sprite.texture = SKTexture(image: #imageLiteral(resourceName: "empty"))
    }
}

func getCardImage(_ card: Card) -> SKTexture? {
    let imageName = "card-\(card.value)-\(card.colour)"
    if let image = UIImage(named: imageName) {
        return SKTexture(image: image)
    }
    return nil
}

func getCardLabel(_ card: Card) -> SKLabelNode {
    let label = SKLabelNode(fontNamed:"HelveticaNeue-UltraLight")
    label.fontSize = 10
    label.text = "\(card.value) of \(card.colour)"
    return label
}

func canStartGame(_ game: Game, _ player: Player, _ players: [PlayerInfo]?) -> Bool {
    return game.status == .notStarted && game.adminNickname == player.nickname && (players?.count ?? 0) >= 2 
}

func canShare(_ game: Game, _ players: [PlayerInfo]?) -> Bool {
    return game.status == .notStarted && (players?.count ?? 0) < 8
}

func canInviteAI(_ game: Game, _ player: Player, _ players: [PlayerInfo]?) -> Bool {
    return game.status == .notStarted && game.adminNickname == player.nickname && (players?.count ?? 0) < 8
}

func canManageRoom(_ game: Game, _ player: Player) -> Bool {
    if game.room == nil {
        return false
    }
    return game.status == .notStarted && game.adminNickname == player.nickname
}

func generatePlayerNickname() -> String {
    guard let randomNames = Nicknames.randomElement(), let animal = randomNames.animals.randomElement(), let adjective = randomNames.adjectives.randomElement() else {
        let number = Int.random(in: 999 ... 9999)
        return "player_\(number)"
    }
    return "\((adjective))_\(animal)"
}
