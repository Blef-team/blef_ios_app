//
//  Effects.swift
//  Blef
//
//  Created by Adrian Golian on 24.04.20.
//  Copyright © 2020 Blef. All rights reserved.
//

import SpriteKit

func pulseLabel (_ label: SKNode) {
    let pulseSequence = SKAction.sequence([
        SKAction.fadeAlpha(by: -0.7, duration: 0.1),
        SKAction.fadeAlpha(by: 0.7, duration: 0.2)
    ])
    label.run(pulseSequence)
}

func updateLabelText(_ label: SKLabelNode, _ newLabelText: String) {
    if label.text?.lowercased() != newLabelText.lowercased() {
        label.text = newLabelText
        fadeInLabel(label)
    }
}

func fadeInLabel(_ label: SKLabelNode) {
    label.alpha = 0.0
    label.run(SKAction.fadeIn(withDuration: 1.0))
}

func fadeOutLabel(_ label: SKLabelNode) {
    label.run(SKAction.fadeOut(withDuration: 1.0))
}

func formatDisplayNickname(_ nickname: String) -> String {
    return nickname.replacingOccurrences(of: "_", with: " ")
}
