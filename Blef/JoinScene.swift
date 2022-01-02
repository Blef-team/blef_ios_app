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
    
    var messageLabel: SKLabelNode!
    var isDisplayingMessage = false
    
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

    }
}
