//
//  StartScene.swift
//  Blef
//
//  Created by Adrian Golian on 15.04.20.
//  Copyright © 2020 Blef Team.
//

import SpriteKit
import GameplayKit

var errorMessageLabel: SKLabelNode?

class StartScene: SKScene, GameManagerDelegate {
    
    var gameManager = GameManager()
    var customGameLabel: SKNode?
    var quickGameLabel: SKNode?
    var joinLabel: SKNode?
    var errorMessageLabel: SKLabelNode!
    var player: Player?
    var playerNickname: String?
    var isDisplayingMessage = false
    var preparingCustomGame = false
    var preparingQuickGame = false
    var numberOfQuickGameAIAgents = 2
    var invitedAIs = 0
    
    override func didMove(to view: SKView) {
        
        self.gameManager.delegate = self
        self.gameManager.getPublicGames()
        
        errorMessageLabel = SKLabelNode(fontNamed:"HelveticaNeue-UltraLight")
        errorMessageLabel.text = ""
        errorMessageLabel.fontSize = 15
        errorMessageLabel.position = CGPoint(x:self.frame.midX, y:self.frame.midY)
        self.addChild(errorMessageLabel)
        
        self.customGameLabel = childNode(withName: "//customGameLabel")
        self.quickGameLabel = childNode(withName: "//quickGameLabel")
        self.joinLabel = childNode(withName: "//joinLabel")
        if let joinLabel = joinLabel {
            joinLabel.alpha = 0
        }
    }
    
    /**
     React to the users touches
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.isDisplayingMessage {
            clearMessage()
        }
        else if let touch = touches.first {
            let location = touch.location(in: self)
            let nodesarray = nodes(at: location)
            
            for node in nodesarray {
                // If the Custom game button was tapped
                if node.name == "customGameButton" {
                    customGameButtonPressed()
                }
                // If the Quick game button was tapped
                if node.name == "quickGameButton" {
                    quickGameButtonPressed()
                }
                // If the Join button was tapped
                if node.name == "joinButton" {
                    joinButtonPressed()
                }
            }
        }
    }
    
    func quickGameButtonPressed() {
        if let label = quickGameLabel {
            pulseLabel(label)
        }
        if preparingQuickGame || preparingCustomGame {
            return
        }
        preparingQuickGame = true
        print("Going to attempt an API call")
        gameManager.createGame()
        print("Made API call")
    }
    
    func customGameButtonPressed() {
        if let label = customGameLabel {
            pulseLabel(label)
        }
        if preparingCustomGame || preparingQuickGame {
            return
        }
        preparingCustomGame = true
        print("Going to attempt an API call")
        gameManager.createGame()
        print("Made API call")
    }
    
    func joinButtonPressed() {
        if gameManager.publicGames.count == 0 {
            return
        }
        if let label = joinLabel {
            pulseLabel(label)
        }
        if preparingCustomGame || preparingQuickGame {
            return
        }
        moveToJoinScene()
    }
    
    func didGetPublicGames() {
        displayJoinLabel()
    }
    
    func displayJoinLabel() {
        if let label = joinLabel {
            if self.gameManager.publicGames.count > 0 {
                fadeInNode(label)
                slowPulseLabel(label)
            } else {
                label.removeAllActions()
                fadeOutNode(label)
            }
        }
    }
    
    func didCreateNewGame() {
        if let nickname = playerNickname {
            gameManager.joinGame(nickname: nickname)
        }
        else {
            let nickname = generatePlayerNickname()
            gameManager.joinGame(nickname: nickname)
            self.playerNickname = nickname
        }
    }
    
    func didJoinGame(_ player: Player) {
        print(player)
        var player = player
        player.nickname = formatSerialisedNickname(playerNickname ?? "no name")
        self.player = player
        if preparingQuickGame {
            numberOfQuickGameAIAgents.times {
                gameManager.inviteAI()
                usleep(50000)
            }
        } else {
            moveToGameScene(player)
        }
    }
    
    func didInviteAI() {
        invitedAIs += 1
        if invitedAIs == numberOfQuickGameAIAgents {
            gameManager.startGame()
        }
    }
    
    func didStartGame() {
        if let player = player {
            moveToGameScene(player)
        }
    }
    
    func moveToGameScene(_ player: Player) {
        preparingQuickGame = false
        preparingCustomGame = false
        if let gameScene = GameScene(fileNamed: "GameScene") {
            let transition = SKTransition.fade(withDuration: 1.0)
            gameScene.scaleMode = .aspectFit
            gameScene.player = player
            gameScene.gameManager = gameManager
            scene?.view?.presentScene(gameScene, transition: transition)
        }
    }
    
    func moveToJoinScene() {
        preparingQuickGame = false
        preparingCustomGame = false
        if let joinScene = JoinScene(fileNamed: "JoinScene") {
            let transition = SKTransition.fade(withDuration: 0.5)
            joinScene.scaleMode = .aspectFit
            joinScene.gameManager = gameManager
            scene?.view?.presentScene(joinScene, transition: transition)
        }
    }
    
    func didFailWithError(error: Error) {
        print("didFailWithError")
        print(error.localizedDescription)
        preparingQuickGame = false
        preparingCustomGame = false
        if error.localizedDescription == "Nickname already taken" {
            let nickname = generatePlayerNickname()
            gameManager.joinGame(nickname: nickname)
            self.playerNickname = nickname
        }
        displayMessage("Something went wrong. Try again.")
    }
    
    func clearStartUI() {
        errorMessageLabel.alpha = 0.0
        joinLabel?.removeAllActions()
        fadeOutNode(joinLabel)
        fadeOutNode(customGameLabel)
        fadeOutNode(quickGameLabel)
    }
 
    func displayMessage(_ message: String) {
        isDisplayingMessage = true
        clearStartUI()
        errorMessageLabel.text = message
        fadeInNode(errorMessageLabel)
    }
    
    func clearMessage() {
        isDisplayingMessage = false
        fadeOutNode(errorMessageLabel)
        fadeInNode(customGameLabel)
        fadeInNode(quickGameLabel)
        displayJoinLabel()
    }
    
}
