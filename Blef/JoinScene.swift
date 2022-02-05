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
    var gameUpdateInterval = 0.05
    var gameUpdateTimer: Timer?
    var gameUpdateScheduled: Bool?
    var messageLabel: SKLabelNode!
    var joinLabel: SKLabelNode?
    var joinButton: SKNode?
    var player: Player?
    var playerNickname: String?
    var isDisplayingMessage = false
    var isPresentingGameOverview = false
    var presentedUuid: UUID?
    var preparingToJoin = false
    var savedGame: SavedGame?
    var adjustSceneAspectDone = false
    private var menuNavigateLabel: SKLabelNode?
    private var roomSprites: [SKSpriteNode] = []
    private var roomLabels: [SKLabelNode] = []
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        self.gameManager!.delegate = self
        
        messageLabel = SKLabelNode(fontNamed:"HelveticaNeue-Light")
        messageLabel.text = ""
        messageLabel.fontSize = 15
        messageLabel.position = CGPoint(x:self.frame.midX, y:self.frame.midY)
        messageLabel.zPosition = 10
        messageLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        messageLabel.numberOfLines = 0
        messageLabel.preferredMaxLayoutWidth = size.width * 0.8
        messageLabel.verticalAlignmentMode = .center
        self.addChild(messageLabel)
        
        self.menuNavigateLabel = childNode(withName: "//menuNavigateLabel") as? SKLabelNode
        menuNavigateLabel?.text = NSLocalizedString("menu", comment: "Button name to move to StartScene")
        menuNavigateLabel?.alpha = 0.0
        
        self.joinLabel = childNode(withName: "//joinLabel") as? SKLabelNode
        if let joinLabel = joinLabel {
            joinLabel.text = NSLocalizedString("joinARoom", comment: "Button text to join the rooms")
            joinLabel.alpha = 0
            joinLabel.zPosition = 10
        }
        self.joinButton = childNode(withName: "//joinButton")
        
        roomSprites = []
        for roomIndex in 0...17 {
            let position = getRoomPosition(roomIndex)
            let sprite = SKSpriteNode(texture: SKTexture(image: #imageLiteral(resourceName: "white-door")), size: CGSize(width: 100, height: 100))
            sprite.alpha = 0
            sprite.position = position
            sprite.zPosition = 10
            addChild(sprite)
            roomSprites.append(sprite)
            let label = SKLabelNode(fontNamed:"HelveticaNeue-Light")
            label.fontSize = 30
            label.alpha = 0
            label.position = position
            label.zPosition = 10
            addChild(label)
            roomLabels.append(label)
        }
        
        displayLabels()
        resumeGameUpdateTimer()
    }
    
    /**
     React to the users touches
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.isPresentingGameOverview {
            if let touch = touches.first, let joinButton = joinButton {
                if nodes(at: touch.location(in: self)).contains(joinButton) {
                    pressedJoinButton()
                    return
                }
            }
            clearGameOverview()
        }
        else if self.isDisplayingMessage {
            clearMessage()
        }
        else if let touch = touches.first {
            let location = touch.location(in: self)
            let nodesarray = nodes(at: location)
            
            for node in nodesarray {
                // If a room sprite was tapped
                if let sprite = node as? SKSpriteNode, let name = node.name {
                    if roomSprites.contains(sprite) {
                        pressedRoomSprite(name)
                    }
                }
                // Menu pressed
                if node.name == "menuNavigateButton" {
                    menuNavigateButtonPressed()
                }
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        adjustSceneAspect(self)
    }
    
    func resumeGameUpdateTimer() {
        gameManager?.resetWatchGameWebsocket()
        gameUpdateTimer = Timer.scheduledTimer(timeInterval: self.gameUpdateInterval, target: self, selector: #selector(updatePublicGames), userInfo: nil, repeats: true)
        gameUpdateScheduled = true
    }
    
    func pauseGameUpdateTimer() {
        if let timer = gameUpdateTimer {
            gameManager?.closeWatchGameWebsocket()
            timer.invalidate()
            gameUpdateScheduled = false
        }
    }
    
    func resetGameUpdateTimer() {
        pauseGameUpdateTimer()
        resumeGameUpdateTimer()
    }
    
    @objc func updatePublicGames() {
        gameManager?.receiveWatchGameWebsocket()
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
        let messageText = NSLocalizedString("errorMessage", comment: "Message to say something went wrong")
        displayMessage(messageText)
    }
    
    func didUpdatePublicGames() {
        displayRooms()
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
        if let uuid = UUID(uuidString: name), let game = gameManager?.publicGames[uuid] {
            if game.players?.count ?? 0 >= 8 {
                let roomText = NSLocalizedString("room", comment: "The noun meaning a closed space that can be occupied")
                let isFullText = NSLocalizedString("isFull", comment: "State that something is full")
                displayMessage("\(roomText) \(game.room) \(isFullText)")
                return
            }
            if let savedGame = getSavedGames()[uuid.uuidString] {
                self.savedGame = savedGame
                displayGameOverview(uuid, continuingPlayerNickname: savedGame.playerNickname)
                return
            }
            displayGameOverview(uuid)
        }
    }
    
    func pressedJoinButton() {
        if let label = joinLabel {
            pulseLabel(label)
        }
        if preparingToJoin {
            return
        }
        guard let uuid = presentedUuid else {
            return
        }
        guard let game = gameManager?.publicGames[uuid], let players = game.players else {
            return
        }
        if let savedPlayerNickname = savedGame?.playerNickname {
            if players.contains(savedPlayerNickname) {
                continueGame(uuid)
                return
            }
        }
        joinGame(uuid)
    }
    
    func menuNavigateButtonPressed() {
        if let label = menuNavigateLabel {
            pulseLabel(label)
        }
        moveToStartScene()
    }
    
    func displayGameOverview(_ uuid: UUID, continuingPlayerNickname: String? = nil) {
        guard let game = gameManager?.publicGames[uuid] else {
            return
        }
        isPresentingGameOverview = true
        presentedUuid = uuid
        var playersString = ""
        if let players = game.players {
            let playersInRoomPrefixText = NSLocalizedString("playersInRoomPrefix", comment: "State that players in room (... are ...)")
            let playersInRoomPostfixText = NSLocalizedString("playersInRoomPostfix", comment: "POSTFIX FOR: State that players in room (... are ...)")
            let youText = NSLocalizedString("you", comment: "Second person singular pronoun")
            playersString = "\(playersInRoomPrefixText) \(game.room) \(playersInRoomPostfixText):\n"
            playersString += players.map { nickname in
                return (nickname == savedGame?.playerNickname) ? youText : formatDisplayNickname(nickname)
            }.map(formatDisplayNickname).joined(separator: "\n")
        }
        let continueText = NSLocalizedString("continue", comment: "To continue the game")
        let joinRoomText = NSLocalizedString("joinRoom", comment: "To join the room")
        displayMessage(playersString)
        if let joinLabel = joinLabel {
            updateAndDisplayLabel(joinLabel, (savedGame?.playerNickname != nil) ? continueText : joinRoomText)
        }
    }
    
    func clearGameOverview() {
        isPresentingGameOverview = false
        savedGame = nil
        presentedUuid = nil
        fadeOutNode(joinLabel)
        clearMessage()
    }
    
    func joinGame(_ uuid: UUID) {
        guard let gameManager = gameManager else {
            return
        }
        preparingToJoin = true
        let nickname = generatePlayerNickname()
        gameManager.gameUuid = uuid
        gameManager.joinGame(nickname: nickname)
        self.playerNickname = nickname
    }
    
    func continueGame(_ uuid: UUID) {
        guard let gameManager = gameManager, let savedGame = savedGame else {
            return
        }
        if savedGame.gameUuid != uuid {
            return
        }
        let player = Player(uuid: savedGame.playerUuid, nickname: savedGame.playerNickname)
        gameManager.gameUuid = uuid
        gameManager.player = player
        moveToGameScene(player)
    }
    
    func moveToGameScene(_ player: Player) {
        if let gameScene = GameScene(fileNamed: "GameScene") {
            let transition = SKTransition.fade(withDuration: 1.0)
            gameScene.scaleMode = .aspectFit
            gameScene.player = player
            gameScene.gameManager = gameManager
            preparingToJoin = false
            scene?.view?.presentScene(gameScene, transition: transition)
        }
    }
    
    func moveToStartScene() {
        if let startScene = StartScene(fileNamed: "StartScene") {
            let transition = SKTransition.fade(withDuration: 1.0)
            startScene.scaleMode = .aspectFit
            scene?.view?.presentScene(startScene, transition: transition)
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
        
        clearRooms()
        
        let orderedPublicGames = publicGames.sorted { $0.value.lastModified > $1.value.lastModified }
        var roomIndex = 0
        let roomCount = min(roomSprites.count, roomLabels.count)
        for (_, game) in orderedPublicGames.prefix(roomCount) {
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
    
    func displayMenuNavigateLabel() {
        fadeInNode(menuNavigateLabel)
    }
    
    func clearMenuNavigateLabel() {
        fadeOutNode(menuNavigateLabel)
    }
 
    func displayLabels() {
        displayRooms()
        displayMenuNavigateLabel()
    }
    
    func clearLabels() {
        clearRooms()
        clearMenuNavigateLabel()
    }
    
    func displayMessage(_ message: String) {
        isDisplayingMessage = true
        clearLabels()
        messageLabel.text = message
        fadeInNode(messageLabel)
    }
    
    func clearMessage() {
        isDisplayingMessage = false
        fadeOutNode(messageLabel)
        displayLabels()
    }
}
