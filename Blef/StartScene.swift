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
    var gameUpdateInterval = 0.05
    var gameUpdateTimer: Timer?
    var gameUpdateScheduled: Bool?
    var customGameLabel: SKLabelNode?
    var quickGameLabel: SKLabelNode?
    var joinLabel: SKLabelNode?
    var continueLabel: SKLabelNode?
    var errorMessageLabel: SKLabelNode!
    var player: Player?
    var savedGameUuid: UUID?
    var savedPlayer: Player?
    var playerNickname: String?
    var isDisplayingMessage = false
    var preparingCustomGame = false
    var preparingQuickGame = false
    var numberOfQuickGameAIAgents = 2
    var invitedAIs = 0
    var adjustSceneAspectDone = false
    
    override func didMove(to view: SKView) {
        
        self.gameManager.delegate = self
        self.gameManager.getPublicGames()
        
        getSavedGame()
        
        errorMessageLabel = SKLabelNode(fontNamed:"HelveticaNeue-UltraLight")
        errorMessageLabel.text = ""
        errorMessageLabel.fontSize = 15
        errorMessageLabel.position = CGPoint(x:self.frame.midX, y:self.frame.midY)
        self.addChild(errorMessageLabel)
        
        self.customGameLabel = childNode(withName: "//customGameLabel") as? SKLabelNode
        customGameLabel?.text = NSLocalizedString("customGame", comment: "Button text to start a custom game")
        print(customGameLabel?.text) //DEBUG
        self.quickGameLabel = childNode(withName: "//quickGameLabel") as? SKLabelNode
        quickGameLabel?.text = NSLocalizedString("quickGame", comment: "Button text to start a quick game")
        self.joinLabel = childNode(withName: "//joinLabel") as? SKLabelNode
        if let joinLabel = joinLabel {
            joinLabel.text = NSLocalizedString("joinARoom", comment: "Button text to join game rooms")
            joinLabel.alpha = 0
        }
        self.continueLabel = childNode(withName: "//continueLabel") as? SKLabelNode
        if let continueLabel = continueLabel {
            continueLabel.text = NSLocalizedString("continue", comment: "Button text to continue a game")
            continueLabel.alpha = 0
            continueLabel.zPosition = 10
        }
        
        resumeGameUpdateTimer()
        
        displayLabels()
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
                // If the Continue button was tapped
                if node.name == "continueButton" {
                    continueButtonPressed()
                }
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        adjustSceneAspect(self)
    }
    
    func getSavedGame() {
        let savedGames = getSavedGames()
        if savedGames.count < 1 {
            return
        }
        let orderedSavedGames = savedGames.values.sorted(by: orderSavedGames)
        if orderedSavedGames.count < 1 {
            return
        }
        let savedGame = orderedSavedGames[0]
        self.savedGameUuid = savedGame.gameUuid
        self.savedPlayer = Player(uuid: savedGame.playerUuid, nickname: savedGame.playerNickname)
    }
    
    func resumeGameUpdateTimer() {
        gameManager.resetWatchGameWebsocket()
        gameUpdateTimer = Timer.scheduledTimer(timeInterval: self.gameUpdateInterval, target: self, selector: #selector(updatePublicGames), userInfo: nil, repeats: true)
        gameUpdateScheduled = true
    }
    
    func pauseGameUpdateTimer() {
        if let timer = gameUpdateTimer {
            gameManager.closeWatchGameWebsocket()
            timer.invalidate()
            gameUpdateScheduled = false
        }
    }
    
    func resetGameUpdateTimer() {
        pauseGameUpdateTimer()
        resumeGameUpdateTimer()
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
    
    func continueButtonPressed() {
        if let label = continueLabel {
            pulseLabel(label)
        }
        if preparingCustomGame || preparingQuickGame {
            return
        }
        guard let savedGameUuid = savedGameUuid, let savedPlayer = savedPlayer else {
            return
        }
        self.gameManager.gameUuid = savedGameUuid
        self.gameManager.player = savedPlayer
        self.moveToGameScene(savedPlayer)
    }
    
    func didUpdatePublicGames() {
        displayJoinLabel()
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
    
    func displayContinueLabel() {
        if let label = continueLabel {
            if self.savedGameUuid != nil && self.savedPlayer != nil {
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
    
    func windDownSceneActivity() {
        preparingQuickGame = false
        preparingCustomGame = false
        pauseGameUpdateTimer()
    }
    
    func moveToGameScene(_ player: Player) {
        if let gameScene = GameScene(fileNamed: "GameScene") {
            windDownSceneActivity()
            let transition = SKTransition.fade(withDuration: 1.0)
            gameScene.scaleMode = .aspectFit
            gameScene.player = player
            gameScene.gameManager = gameManager
            scene?.view?.presentScene(gameScene, transition: transition)
        }
    }
    
    func moveToJoinScene() {
        if let joinScene = JoinScene(fileNamed: "JoinScene") {
            windDownSceneActivity()
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
        let messageText = NSLocalizedString("errorMessage", comment: "Message to say something went wrong")
        displayMessage(messageText)
    }
    
    @objc func updatePublicGames() {
        gameManager.receiveWatchGameWebsocket()
    }
    
    func displayLabels() {
        fadeInNode(customGameLabel)
        fadeInNode(quickGameLabel)
        displayJoinLabel()
        displayContinueLabel()
    }
    
    func clearStartUI() {
        errorMessageLabel.alpha = 0.0
        joinLabel?.removeAllActions()
        fadeOutNode(joinLabel)
        continueLabel?.removeAllActions()
        fadeOutNode(continueLabel)
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
        displayLabels()
    }
    
}
