//
//  StartScene.swift
//  Blef
//
//  Created by Adrian Golian on 15.04.20.
//  Copyright © 2020 Blef Team.
//

import SpriteKit
import GameplayKit

var errorMessageLabel: SKLabelNode!

class StartScene: SKScene, GameManagerDelegate {
    
    var gameManager = GameManager()
    var newGameLabel: SKNode?
    var playerNickname: String?
    
    override func didMove(to view: SKView) {
        
        self.gameManager.delegate = self
        
        self.playerNickname = "Warty_Warthog"
        
        self.newGameLabel = childNode(withName: "//newGameLabel")
        errorMessageLabel = SKLabelNode(fontNamed:"Chalkduster")
        errorMessageLabel.text = ""
        errorMessageLabel.fontSize = 12
        errorMessageLabel.position = CGPoint(x:self.frame.midX, y:self.frame.midY-50)

        self.addChild(errorMessageLabel)
    }
    
    /**
    React to the users touches
    */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            let nodesarray = nodes(at: location)

            for node in nodesarray {
                // If the New game button was tapped
                if node.name == "newGameButton" {
                    pulseLabel()
                    errorMessageLabel.text = ""
                    print("Going to attempt an API call")
                    gameManager.createGame(nickname: self.playerNickname ?? "Warty_Warthog")
                    print("Made API call")
                }

            }
        }
    }
    
    /**
     Display a visual effect on tap of the New game label
     */
    func pulseLabel () {
        if let newGameLabel = self.newGameLabel {
            print(newGameLabel)
            let pulseSequence = SKAction.sequence([
                SKAction.fadeAlpha(by: -0.7, duration: 0.1),
                SKAction.fadeAlpha(by: 0.7, duration: 0.2)
             ])
            newGameLabel.run(pulseSequence)
        }
    }
    
    func didCreateNewGame(_ newGame: NewGame) {
        print(newGame)
        let gameScene = GameScene(fileNamed: "GameScene")
            let transition = SKTransition.fade(withDuration: 1.0)
        gameScene?.scaleMode = .aspectFill
        gameScene?.gameUuid = newGame.game_uuid
        gameScene?.playerNickname = playerNickname
        scene?.view?.presentScene(gameScene!, transition: transition)
    }
    
    func didFailWithError(error: Error) {
        print("didFailWithError")
        print(error.localizedDescription)
        errorMessageLabel.removeFromParent()
        errorMessageLabel.text = "Something went wrong. Try again."
        self.addChild(errorMessageLabel)
    }

}
