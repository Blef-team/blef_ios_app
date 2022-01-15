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


class JoinScene: SKScene, GameManagerDelegate {
    
    var gameManager: GameManager?
    var messageLabel: SKLabelNode!
    var player: Player?
    var playerNickname: String?
    var isDisplayingMessage = false
    var preparingToJoin = false
    private var roomSprites: [SKSpriteNode] = []
    private var roomLabels: [SKLabelNode] = []
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        self.gameManager!.delegate = self
        
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
            let sprite = SKSpriteNode(texture: SKTexture(image: #imageLiteral(resourceName: "white-door")), size: CGSize(width: 100, height: 100))
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
        
        displayRooms()
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
                if let name = node.name {
                    pressedRoomSprite(name)
                }
            }
        }
    }
    
    func didFailWithError(error: Error) {
        print("didFailWithError")
        print(error.localizedDescription)
        preparingToJoin = false
        if error.localizedDescription == "Nickname already taken" {
            let nickname = generatePlayerNickname()
            gameManager?.joinGame(nickname: nickname)
            self.playerNickname = nickname
        }
        displayMessage("Something went wrong. Try again.")
    }
    
    func didJoinGame(_ player: Player) {
        print(player)
        var player = player
        player.nickname = formatSerialisedNickname(playerNickname ?? "no name")
        self.player = player
        moveToGameScene(player)
    }
    
    func pressedRoomSprite(_ name: String) {
        if preparingToJoin {
            return
        }
        if let gameManager = gameManager, let uuid = UUID(uuidString: name), let _ = gameManager.publicGames[uuid] {
            preparingToJoin = true
            let nickname = generatePlayerNickname()
            gameManager.gameUuid = uuid
            gameManager.joinGame(nickname: nickname)
            self.playerNickname = nickname
        }
    }
    
    func moveToGameScene(_ player: Player) {
        preparingToJoin = false
        if let gameScene = GameScene(fileNamed: "GameScene") {
            let transition = SKTransition.fade(withDuration: 1.0)
            gameScene.scaleMode = .aspectFit
            gameScene.player = player
            gameScene.gameManager = gameManager
            scene?.view?.presentScene(gameScene, transition: transition)
        }
    }
    
    func getRoomPosition(_ roomIndex: Int) -> CGPoint {
        let xPosition = size.width * -0.35 + CGFloat(100 * (roomIndex % 6))
        let yPosition = size.height * -0.25 * CGFloat((Double(roomIndex / 6) - 0.5))
        return CGPoint(x: xPosition, y: yPosition)
    }
    
    func displayRooms() {
        guard let publicGames = gameManager?.publicGames else {
            return
        }
        
        let orderedPublicGames = publicGames.sorted { $0.value.lastModified < $1.value.lastModified }
        var roomIndex = 0
        for (_, game) in orderedPublicGames {
            roomSprites[roomIndex].name = game.uuid.uuidString
            roomLabels[roomIndex].text = game.room.description
            fadeInNode(roomSprites[roomIndex])
            fadeInNode(roomLabels[roomIndex])
            roomIndex += 1
        }
    }
    
    func clearRooms() {
        for sprite in roomSprites {
            fadeOutNode(sprite)
        }
        for label in roomLabels {
            fadeOutNode(label)
        }
    }
 
    func displayMessage(_ message: String) {
        isDisplayingMessage = true
        clearRooms()
        messageLabel.text = message
        fadeInNode(messageLabel)
    }
    
    func clearMessage() {
        isDisplayingMessage = false
        fadeOutNode(messageLabel)
        displayRooms()
    }
}
