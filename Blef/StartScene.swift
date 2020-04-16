//
//  StartScene.swift
//  Blef
//
//  Created by Adrian Golian on 15.04.20.
//

import SpriteKit
import GameplayKit

class StartScene: SKScene {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            let nodesarray = nodes(at: location)

            for node in nodesarray {
                if node.name == "newGameButton" {
                let gameScene = GameScene(fileNamed: "GameScene")
                    let transition = SKTransition.fade(withDuration: 1.0)
                gameScene?.scaleMode = .aspectFill
                scene?.view?.presentScene(gameScene!, transition: transition)
                }

            }
        }
    }
}
