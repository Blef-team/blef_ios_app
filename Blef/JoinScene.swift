//
//  JoinScene.swift
//  Blef
//
//  Created by Adrian Golian on 02/01/2022.
//  Copyright © 2022 Blef. All rights reserved.
//

import Foundation
import SpriteKit
import GameplayKit


class JoinScene: SKScene {
    
    var gameManager: GameManager?
    var messageLabel: SKLabelNode!
    var isDisplayingMessage = false
    private var roomSprites: [SKSpriteNode] = []
    private var roomLabels: [SKLabelNode] = []
    
    override func didMove(to view: SKView) {
        
        messageLabel = SKLabelNode(fontNamed:"HelveticaNeue-Light")
        messageLabel.text = ""
        messageLabel.fontSize = 15
        messageLabel.position = CGPoint(x:self.frame.midX, y:self.frame.midY)
        messageLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        messageLabel.numberOfLines = 0
        messageLabel.preferredMaxLayoutWidth = size.width * 0.8
        messageLabel.verticalAlignmentMode = .center
        self.addChild(messageLabel)
        
        
        roomSprites = []
        for roomIndex in 0...17 {
            let position = getRoomPosition(roomIndex)
            let sprite = SKSpriteNode(texture: SKTexture(image: #imageLiteral(resourceName: "white-door")), size: CGSize(width: 120, height: 120))
            sprite.alpha = 0
            sprite.position = position
            addChild(sprite)
            roomSprites.append(sprite)
            let label = SKLabelNode(fontNamed:"HelveticaNeue-Light")
            label.fontSize = 30
            label.alpha = 0
            label.position = position
            addChild(label)
            roomLabels.append(label)
        }
    }
    
    func getRoomPosition(_ roomIndex: Int) -> CGPoint {
        let xPosition = size.width * -0.35 + CGFloat(100 * (roomIndex % 6))
        let yPosition = size.height * -0.3 * CGFloat((Double(roomIndex / 6) - 0.7).rounded())
        return CGPoint(x: xPosition, y: yPosition)
    }
    
}
