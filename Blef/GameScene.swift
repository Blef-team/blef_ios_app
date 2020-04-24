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
    var gameUuid: UUID?
    var player: Player?
    var game: Game?
    private var startGameLabel: SKLabelNode?
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
    
    override func didMove(to view: SKView) {
        
        self.gameManager.delegate = self
        
        self.startGameLabel = childNode(withName: "//startGameLabel") as? SKLabelNode
        startGameLabel?.alpha = 0.0
        self.gameUuidLabel = self.childNode(withName: "//gameUuidLabel") as? SKLabelNode
        gameUuidLabel?.alpha = 0.0
        self.adminLabel = self.childNode(withName: "//adminLabel") as? SKLabelNode
        adminLabel?.alpha = 0.0
        self.publicLabel = self.childNode(withName: "//publicLabel") as? SKLabelNode
        publicLabel?.alpha = 0.0
        self.statusLabel = self.childNode(withName: "//statusLabel") as? SKLabelNode
        statusLabel?.alpha = 0.0
        self.roundLabel = self.childNode(withName: "//roundLabel") as? SKLabelNode
        roundLabel?.alpha = 0.0
        self.maxCardsLabel = self.childNode(withName: "//maxCardsLabel") as? SKLabelNode
        maxCardsLabel?.alpha = 0.0
        self.currentPlayerLabel = self.childNode(withName: "//currentPlayerLabel") as? SKLabelNode
        currentPlayerLabel?.alpha = 0.0
        self.playersLabel = self.childNode(withName: "//playersLabel") as? SKLabelNode
        playersLabel?.alpha = 0.0
        self.handsLabel = self.childNode(withName: "//handsLabel") as? SKLabelNode
        handsLabel?.alpha = 0.0
        self.historyLabel = self.childNode(withName: "//historyLabel") as? SKLabelNode
        historyLabel?.alpha = 0.0
        
        errorMessageLabel = SKLabelNode(fontNamed:"Chalkduster")
        errorMessageLabel.text = ""
        errorMessageLabel.fontSize = 12
        errorMessageLabel.position = CGPoint(x:self.frame.midX+80, y:self.frame.midY-50)
        self.addChild(errorMessageLabel)
        
        self.helloLabel = self.childNode(withName: "//helloLabel") as? SKLabelNode
        if let label = self.helloLabel {
            label.text = "Hello, \(formatDisplayNickname(player?.nickname ?? "new player"))"
            label.run(SKAction.fadeOut(withDuration: 2.0))
        }
        
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateGame), userInfo: nil, repeats: true)
    }
    
    /**
     Request updated game state.
     */
    @objc func updateGame() {
        if let gameUuid = self.gameUuid, let playerUuid = player?.uuid {
            gameManager.updateGame(gameUuid: gameUuid, playerUuid: playerUuid)
        }
    }
    
    func didFailWithError(error: Error) {
        print("didFailWithError")
        print(error.localizedDescription)
        errorMessageLabel.removeFromParent()
        errorMessageLabel.text = "Something went wrong. Try again."
        self.addChild(errorMessageLabel)
    }
    
    func didStartGame(_ message: Message) {
        if let label = startGameLabel {
            fadeOutLabel(label)
        }
        updateGame()
    }
    
    func didUpdateGame(_ game: Game) {
        print(game)
        self.game = game
        updateLabels()
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
        let nodesarray = nodes(at: pos)
        for node in nodesarray {
            // If the New game button was tapped
            if node.name == "startGameButton" {
                if let label = startGameLabel {
                    pulseLabel(label)
                }
                errorMessageLabel.text = ""
                if let gameUuid = gameUuid, let playerUuid = player?.uuid, let game = self.game, let players = game.players {
                    if game.status == .notStarted && players.count >= 2 {
                        print("Going to attempt an API call")
                        gameManager.startGame(gameUuid: gameUuid, playerUuid: playerUuid)
                        print("Made API call")
                    }
                }
            }
        }
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
        if let label = self.startGameLabel, let game = self.game, let players = game.players {
            if game.status == .notStarted && players.count >= 2 {
                label.run(SKAction.fadeIn(withDuration: 1.0))
            }
        }
        print(self.startGameLabel?.text as Any)
        
        if let label = self.gameUuidLabel, let id = gameUuid?.uuidString {
            let newLabelText = "Game ID: \(id)"
            updateLabelText(label, newLabelText)
        }
        print(self.gameUuidLabel?.text as Any)
        
        if let label = self.adminLabel, let game = self.game {
            let newLabelText = "Admin: \(game.adminNickname?.replacingOccurrences(of: "_", with: " ") ?? "none yet")"
            updateLabelText(label, newLabelText)
        }
        print(self.adminLabel?.text as Any)
        
        if let label = self.publicLabel, let game = self.game{
            let newLabelText = "Is public: \(game.isPublic)"
            updateLabelText(label, newLabelText)
        }
        
        if let label = self.statusLabel, let game = self.game{
            let newLabelText = "Status: \(game.status.rawValue)"
            updateLabelText(label, newLabelText)
        }
        
        if let label = self.roundLabel, let game = self.game{
            let newLabelText = "Round: \(game.roundNumber)"
            updateLabelText(label, newLabelText)
        }
        
        if let label = self.maxCardsLabel, let game = self.game{
            let newLabelText = "Maximum cards: \(game.maxCards)"
            updateLabelText(label, newLabelText)
        }
        
        if let label = self.currentPlayerLabel, let game = self.game{
            let newLabelText = "Current player: \(formatDisplayNickname(game.currentPlayerNickname ?? "none yet"))"
            updateLabelText(label, newLabelText)
        }
        
        if let label = self.playersLabel, let game = self.game{
            let newLabelText = "Players: \(game.players?.map { "\(formatDisplayNickname($0.nickname)): \($0.nCards) cards"}.joined(separator: " | ") ?? "no details available")"
            updateLabelText(label, newLabelText)
        }
        
        if let label = self.handsLabel, let game = self.game{
            var newLabelText = "Failed getting your hand info"
            if let hand = game.hands?.first(where:{$0.nickname != "" })?.hand {
                newLabelText = "Your hand: \(hand)"
            }
            updateLabelText(label, newLabelText)
        }
        
        if let label = self.historyLabel, let game = self.game{
            let newLabelText = "Moves this round: \(game.history.map{ "\($0.player): \($0.actionId)"}.joined(separator: " , "))"
            updateLabelText(label, newLabelText)
        }
    }
}
