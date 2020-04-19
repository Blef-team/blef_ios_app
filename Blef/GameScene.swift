//
//  GameScene.swift
//  Blef
//
//  Created by Adrian Golian on 15.04.20.
//  Copyright © 2020 Blef Team.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, GameManagerDelegate {
    
    var gameManager = GameManager()
    var gameUuid: String?
    var playerNickname: String?
    var game: Game?
    private var helloLabel : SKLabelNode?
    private var gameUuidLabel : SKLabelNode?
    private var adminLabel : SKLabelNode?
    private var publicLabel : SKLabelNode?
    private var statusLabel : SKLabelNode?
    private var roundLabel : SKLabelNode?
    private var maxCardsLabel : SKLabelNode?
    private var currentPlayerLabel : SKLabelNode?
    private var playersLabel : SKLabelNode?
    private var handsLabel : SKLabelNode?
    private var historyLabel : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    override func didMove(to view: SKView) {
        
        self.gameManager.delegate = self
        updateGame()
        
        self.helloLabel = self.childNode(withName: "//helloLabel") as? SKLabelNode
        if let label = self.helloLabel {
            label.text = "Hello  \(playerNickname?.replacingOccurrences(of: "_", with: " ") ?? "new player")"
            label.run(SKAction.fadeOut(withDuration: 2.0))
        }
        
    }
    
    /**
     Request updated game state.
     */
    func updateGame() {
        if let gameUuid = self.gameUuid {
            gameManager.updateGame(gameUuid: gameUuid)
        }
    }
    
    func didFailWithError(error: Error) {
        print(error.localizedDescription)
    }
    
    func didUpdateGame(_ game: Game) {
        print(game)
        self.game = game
        updateLabels()
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
        
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        
    }
    
    func touchUp(atPoint pos : CGPoint) {
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    func updateLabels() {
        self.gameUuidLabel = self.childNode(withName: "//gameUuidLabel") as? SKLabelNode
        if let label = self.gameUuidLabel, let id = gameUuid {
            label.alpha = 0.0
            label.text = "Game ID: \(id)"
            label.run(SKAction.fadeIn(withDuration: 1.0))
        }
        print(self.gameUuidLabel?.text)
        self.adminLabel = self.childNode(withName: "//adminLabel") as? SKLabelNode
        if let label = self.adminLabel, let game = self.game {
            label.alpha = 0.0
            label.text = "Admin: \(game.adminNickname)"
            label.run(SKAction.fadeIn(withDuration: 1.0))
        }
        print(self.adminLabel?.text)
        self.publicLabel = self.childNode(withName: "//publicLabel") as? SKLabelNode
        if let label = self.publicLabel, let game = self.game{
            label.alpha = 0.0
            label.text = "Is public: \(game.isPublic)"
            label.run(SKAction.fadeIn(withDuration: 1.0))
        }
        self.statusLabel = self.childNode(withName: "//statusLabel") as? SKLabelNode
        if let label = self.statusLabel, let game = self.game{
            label.alpha = 0.0
            label.text = "Status: \(game.status.rawValue)"
            label.run(SKAction.fadeIn(withDuration: 1.0))
        }
        self.roundLabel = self.childNode(withName: "//roundLabel") as? SKLabelNode
        if let label = self.roundLabel, let game = self.game{
            label.alpha = 0.0
            label.text = "Round: \(game.roundNumber)"
            label.run(SKAction.fadeIn(withDuration: 1.0))
        }
        self.maxCardsLabel = self.childNode(withName: "//maxCardsLabel") as? SKLabelNode
        if let label = self.maxCardsLabel, let game = self.game{
            label.alpha = 0.0
            label.text = "Maximum cards: \(game.maxCards)"
            label.run(SKAction.fadeIn(withDuration: 1.0))
        }
        self.currentPlayerLabel = self.childNode(withName: "//currentPlayerLabel") as? SKLabelNode
        if let label = self.currentPlayerLabel, let game = self.game{
            label.alpha = 0.0
            label.text = "Current player: \(game.currentPlayerNickname)"
            label.run(SKAction.fadeIn(withDuration: 1.0))
        }
        self.playersLabel = self.childNode(withName: "//playersLabel") as? SKLabelNode
        if let label = self.playersLabel, let game = self.game{
            label.alpha = 0.0
            label.text = "Players: \(game.players.map { "\($0.nickname): \($0.n_cards) cards"}.joined(separator: " | "))"
            label.run(SKAction.fadeIn(withDuration: 1.0))
        }
        self.handsLabel = self.childNode(withName: "//handsLabel") as? SKLabelNode
        if let label = self.handsLabel, let game = self.game{
            label.alpha = 0.0
            let hand = game.hands.first(where:{$0.nickname == playerNickname})
            label.text = "Your hand: \(hand)"
            label.run(SKAction.fadeIn(withDuration: 1.0))
        }
        self.historyLabel = self.childNode(withName: "//historyLabel") as? SKLabelNode
        if let label = self.historyLabel, let game = self.game{
            label.alpha = 0.0
            label.text = game.history.map{ "\($0.player): \($0.actionId)"}.joined(separator: " , ")
            label.run(SKAction.fadeIn(withDuration: 1.0))
        }
    }
}
