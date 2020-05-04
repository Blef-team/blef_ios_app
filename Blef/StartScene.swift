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
    var newGameLabel: SKNode?
    var errorMessageLabel: SKLabelNode!
    var gameUuid: UUID?
    var playerNickname: String?
    var isDisplayingMessage = false
    var newGameButtonPressed = false
    
    override func didMove(to view: SKView) {
        
        self.gameManager.delegate = self
        
        errorMessageLabel = SKLabelNode(fontNamed:"HelveticaNeue-UltraLight")
        errorMessageLabel.text = ""
        errorMessageLabel.fontSize = 15
        errorMessageLabel.position = CGPoint(x:self.frame.midX, y:self.frame.midY)
        self.addChild(errorMessageLabel)
        
        self.newGameLabel = childNode(withName: "//newGameLabel")
        
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
                // If the New game button was tapped
                if node.name == "newGameButton", let label = self.newGameLabel {
                    if !newGameButtonPressed {
                        newGameButtonPressed = true
                        pulseLabel(label)
                        print("Going to attempt an API call")
                        gameManager.createGame()
                        print("Made API call")
                    }
                }
                
            }
        }
    }
    
    func didCreateNewGame(_ newGame: NewGame) {
        print(newGame)
        gameUuid = newGame.uuid
        if let nickname = playerNickname {
            gameManager.joinGame(gameUuid: newGame.uuid, nickname: nickname)
        }
        else {
            let nickname = generatePlayerNickname()
            gameManager.joinGame(gameUuid: newGame.uuid, nickname: nickname)
            self.playerNickname = nickname
        }
    }
    
    func didJoinGame(_ player: Player) {
        print(player)
        var player = player
        player.nickname = formatSerialisedNickname(playerNickname ?? "no name")
        let gameScene = GameScene(fileNamed: "GameScene")
        let transition = SKTransition.fade(withDuration: 1.0)
        gameScene?.scaleMode = .aspectFit
        gameScene?.gameUuid = gameUuid
        gameScene?.player = player
        scene?.view?.presentScene(gameScene!, transition: transition)
    }
    
    func didFailWithError(error: Error) {
        print("didFailWithError")
        print(error.localizedDescription)
        if error.localizedDescription == "Nickname already taken" {
            if let gameUuid = gameUuid {
                let nickname = generatePlayerNickname()
                gameManager.joinGame(gameUuid: gameUuid, nickname: nickname)
                self.playerNickname = nickname
            }
        }
        displayMessage("Something went wrong. Try again.")
    }
 
    func displayMessage(_ message: String) {
        isDisplayingMessage = true
        
        errorMessageLabel.removeFromParent()
        errorMessageLabel.text = message
        errorMessageLabel.alpha = 0.0
        self.addChild(errorMessageLabel)
        
        fadeOutNode(newGameLabel)
        
        fadeInNode(errorMessageLabel)
    }
    
    func clearMessage() {
        isDisplayingMessage = false
        fadeOutNode(errorMessageLabel)
        
        fadeInNode(newGameLabel)

        
    }
    
}
