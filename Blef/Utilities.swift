//
//  Effects.swift
//  Blef
//
//  Created by Adrian Golian on 24.04.20.
//  Copyright © 2020 Blef. All rights reserved.
//

import SpriteKit

let baseShareURL = "https://www.blef.app/join.html?game_uuid="

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
    func addGlow(radius:CGFloat=5) {
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

func orderHand(_ hand: [Card], orderByColour: Bool = false) -> [Card] {
    if orderByColour {
        return hand.sorted { $0.colour < $1.colour || ($0.colour == $1.colour && $0.value < $1.value) }
    }
    return hand.sorted { $0 < $1 }
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

func checkPlayerLostRound(_ player: Player, _ game: Game) -> Bool {
    if player.nickname == game.losingPlayer {
        return true
    }
    return false
}

func generatePlayerNickname() -> String {
    guard let randomNames = Nicknames.randomElement(), let animal = randomNames.animals.randomElement(), let adjective = randomNames.adjectives.randomElement() else {
        let number = Int.random(in: 999 ... 9999)
        return "player_\(number)"
    }
    return "\((adjective))_\(animal)"
}

func pruneSavedGames(_ games: SavedGamesDict, ifAtLeast minCount: Int = 25, downTo maxCount: Int = 10, maxAge: TimeInterval = TimeInterval(600000)) -> SavedGamesDict {
    if games.count < minCount {
        return games
    }
    let prunedGames =  games.values.filter { game in
        // Remove old games
        return Date(timeIntervalSince1970: TimeInterval(game.lastModified)) > Date(timeIntervalSinceNow: -maxAge)
        }.filter { game in
            return game.status != .finished // Remove finished games
        }.sorted(by: orderSavedGames).prefix(maxCount) // Trim down to maxCount saved games
    var resultDict: SavedGamesDict = [:]
    for game in prunedGames {
        resultDict[game.gameUuid.uuidString] = game
    }
    return resultDict
}

func orderSavedGames(first: SavedGame, second: SavedGame) -> Bool {
    return (first.status == .running && second.status != .running) ||
    (first.status == .running && second.status == .running && first.lastModified > second.lastModified) ||
    (first.status != .running && second.status != .running && first.lastModified > second.lastModified)
}

func getSavedGames(persistentStore: UserDefaults = UserDefaults.standard) -> SavedGamesDict {
    if let jsonObject = persistentStore.object(forKey: SavedGamesKey) as? ShallowNestedJSON {
        let savedGames = jsonObject.compactMapValues(SavedGame.init)
        return savedGames
    }
    return SavedGamesDict()
}

func saveGames(_ games: SavedGamesDict, persistentStore: UserDefaults = UserDefaults.standard) {
    let serialisedGames = games.mapValues { game in return game.serialised }
    persistentStore.set(serialisedGames, forKey: SavedGamesKey)
}

func computeRescaledPosition(_ distanceRatio: CGFloat, _ scaling: CGFloat) -> CGFloat {
    return distanceRatio * scaling + (1 - scaling) / 2
}

var originalSize = CGSize(width: 666.999, height: 375)

func adjustSceneAspect(_ scene: GameScene) {
    if scene.adjustSceneAspectDone {
        return
    }
    adjustSceneAspect(scene as SKScene)
    scene.adjustSceneAspectDone = true
}

func adjustSceneAspect(_ scene: StartScene) {
    if scene.adjustSceneAspectDone {
        return
    }
    adjustSceneAspect(scene as SKScene)
    scene.adjustSceneAspectDone = true
}

func adjustSceneAspect(_ scene: JoinScene) {
    if scene.adjustSceneAspectDone {
        return
    }
    adjustSceneAspect(scene as SKScene)
    scene.adjustSceneAspectDone = true
}

func adjustSceneAspect(_ scene: SKScene) {
    let winSize = scene.view!.frame.size
    let originalAspect = originalSize.width/originalSize.height
    let windowAspect = winSize.width/winSize.height
    var newSize = originalSize; do {
        if windowAspect > originalAspect {
            newSize.width = originalSize.height * windowAspect
        } else if windowAspect < originalAspect {
            newSize.height = originalSize.width / windowAspect
        }
    }
    scene.size = newSize
    scene.scaleMode = .aspectFit
}

var playUpdateSound = SKAction.playSoundFileNamed("Blef-update.wav", waitForCompletion: true)
var playLossSound = SKAction.playSoundFileNamed("Blef-loss.wav", waitForCompletion: true)
var playWinSound = SKAction.playSoundFileNamed("Blef-win.wav", waitForCompletion: true)
