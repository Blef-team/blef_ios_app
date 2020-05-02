//
//  GameScene.swift
//  Blef
//
//  Created by Adrian Golian on 15.04.20.
//  Copyright © 2020 Blef Team.
//

import SpriteKit
import UIKit
import GameplayKit

class GameScene: SKScene, GameManagerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    var gameManager = GameManager()
    var gameUpdateInterval = 1.0
    var gameUpdateTimer: Timer?
    var gameUpdateScheduled: Bool?
    var gameUuid: UUID?
    var player: Player?
    var game: Game?
    var lastBet: Action?
    var errorMessageLabel: SKLabelNode!
    var isDisplayingMessage = false
    var actionSelected: Action?
    private var startGameLabel: SKLabelNode?
    private var playLabel: SKLabelNode?
    private var actionPickerLabel: SKLabelNode?
    private var actionPickerView : UIPickerView?
    private var helloLabel : SKLabelNode?
    private var shareLabel : SKLabelNode?
    private var adminLabel : SKLabelNode?
    private var publicLabel : SKLabelNode?
    private var statusLabel : SKLabelNode?
    private var roundLabel : SKLabelNode?
    private var maxCardsLabel : SKLabelNode?
    private var currentPlayerLabel : SKLabelNode?
    private var playersLabel : SKLabelNode?
    private var handsLabel : SKLabelNode?
    private var historyLabel : SKLabelNode?
    private var actionPickerField: UITextField?
    
    override func didMove(to view: SKView) {
        
        self.gameManager.delegate = self
        
        self.startGameLabel = childNode(withName: "//startGameLabel") as? SKLabelNode
        startGameLabel?.alpha = 0.0
        self.playLabel = childNode(withName: "//playLabel") as? SKLabelNode
        playLabel?.alpha = 0.0
        self.actionPickerLabel = childNode(withName: "//actionPickerLabel") as? SKLabelNode
        actionPickerLabel?.alpha = 0.0
        self.shareLabel = self.childNode(withName: "//shareLabel") as? SKLabelNode
        shareLabel?.alpha = 0.0
        self.currentPlayerLabel = self.childNode(withName: "//currentPlayerLabel") as? SKLabelNode
        currentPlayerLabel?.alpha = 0.0
        self.playersLabel = self.childNode(withName: "//playersLabel") as? SKLabelNode
        playersLabel?.alpha = 0.0
        self.handsLabel = self.childNode(withName: "//handsLabel") as? SKLabelNode
        handsLabel?.alpha = 0.0
        
        self.actionPickerField = UITextField(frame: CGRect(x: UIScreen.main.bounds.size.width * 0.65, y: UIScreen.main.bounds.size.height * 0.2, width: 200, height: 30))
        
        actionPickerView = UIPickerView()
        actionPickerView?.dataSource = self
        actionPickerView?.delegate = self
        if let myField = actionPickerField {
            myField.inputView = actionPickerView
            myField.font = UIFont(name: "HelveticaNeue-UltraLight", size: 20)
            myField.textColor = .black
            myField.backgroundColor = .lightGray
            myField.borderStyle = UITextField.BorderStyle.roundedRect
            myField.delegate = self
        }
        
        errorMessageLabel = SKLabelNode(fontNamed:"HelveticaNeue-UltraLight")
        errorMessageLabel.text = ""
        errorMessageLabel.fontSize = 15
        errorMessageLabel.position = CGPoint(x:self.frame.midX, y:self.frame.midY)
        self.addChild(errorMessageLabel)
        
        self.helloLabel = self.childNode(withName: "//helloLabel") as? SKLabelNode
        if let label = self.helloLabel {
            label.text = "Hello, \(formatDisplayNickname(player?.nickname ?? "new player"))"
            label.run(SKAction.fadeOut(withDuration: 2.0))
        }
        
        resumeGameUpdateTimer()
    }
    
    /**
     Request updated game state.
     */
    @objc func updateGame() {
        if let gameUuid = self.gameUuid, let playerUuid = player?.uuid {
            gameManager.updateGame(gameUuid: gameUuid, playerUuid: playerUuid)
        }
    }
    
    func didFailWithError(error: Error) {
        displayMessage("Something went wrong. Try again.")
    }
    
    func didStartGame(_ message: Message) {
        if let label = startGameLabel {
            fadeOutNode(label)
            label.removeFromParent()
        }
        updateGame()
    }
    
    func didUpdateGame(_ game: Game) {
        print(game)
        self.game = game
        self.lastBet = game.history?.last?.action
        updateLabels()
    }
    
    func didPlay() {
        if let playLabel = playLabel, let actionPickerLabel = actionPickerLabel, let actionPickerField = actionPickerField {
            fadeOutNode(playLabel)
            fadeOutNode(actionPickerLabel)
            actionPickerField.text = ""
            actionPickerField.isHidden = true
        }
    }
    
    func failedIllegalPlay() {
        print("failedIllegalPlay")
        displayMessage("You can't do that now")
    }
    
    func touchDown(atPoint pos : CGPoint) {
        if self.isDisplayingMessage {
            clearMessage()
        }
        else{
            self.view?.endEditing(true)
        }
        
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if self.isDisplayingMessage {
            clearMessage()
        }
        else {
            let nodesarray = nodes(at: pos)
            for node in nodesarray {
                // If the New game button was tapped
                if node.name == "startGameButton" {
                    startGameButtonPressed()
                }
                if node.name == "playButton" {
                    playButtonPressed()
                }
                if node.name == "shareButton" {
                    let pasteboard = UIPasteboard.general
                    pulseLabel(node)
                    displayMessage("Game link copied")
                    
                    let firstActivityItem = "Join me for a game of Blef"
                    if let uuid = gameUuid?.uuidString {
                        let gameUrlString = "blef:///\(uuid)"
                        pasteboard.string = gameUrlString
                        let secondActivityItem : NSURL = NSURL(string: gameUrlString)!
                        let activityViewController : UIActivityViewController = UIActivityViewController(
                            activityItems: [firstActivityItem, secondActivityItem], applicationActivities: nil)
                        
                        activityViewController.popoverPresentationController?.sourceView = self.view
                        activityViewController.popoverPresentationController?.sourceRect = CGRect(x: 150, y: 150, width: 0, height: 0)
                        
                        activityViewController.excludedActivityTypes = [
                            UIActivity.ActivityType.postToWeibo,
                            UIActivity.ActivityType.print,
                            UIActivity.ActivityType.assignToContact,
                            UIActivity.ActivityType.saveToCameraRoll,
                            UIActivity.ActivityType.addToReadingList,
                            UIActivity.ActivityType.postToFlickr,
                            UIActivity.ActivityType.postToVimeo,
                            UIActivity.ActivityType.postToTencentWeibo,
                        ]
                        
                        self.view?.window?.rootViewController?.present(activityViewController, animated: true, completion: nil)
                    }
                    
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if let lastBet = lastBet {
            return Action.allCases.count - lastBet.rawValue - 1
        }
        return Action.allCases.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let actionId = getActionIdForRow(row)
        if let action = Action.init(rawValue: actionId) {
            return String(describing: action)
        }
        return "?"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let actionId = getActionIdForRow(row)
        if let myField = actionPickerField, let action = Action.init(rawValue: actionId){
            myField.text = String(describing: action)
            self.actionSelected = action
        }
    }
    
    func getActionIdForRow(_ row: Int) -> Int {
        var actionId = row - 1
        if let lastBet = lastBet {
            actionId += lastBet.rawValue + 1
        }
        if row == 0 {
            actionId = 88
        }
        return actionId
    }
    
    func resumeGameUpdateTimer() {
        gameUpdateTimer = Timer.scheduledTimer(timeInterval: self.gameUpdateInterval, target: self, selector: #selector(updateGame), userInfo: nil, repeats: true)
        gameUpdateScheduled = true
    }
    
    func pauseGameUpdateTimer() {
        if let timer = gameUpdateTimer {
            timer.invalidate()
            gameUpdateScheduled = false
        }
    }
    
    func resetGameUpdateTimer() {
        pauseGameUpdateTimer()
        resumeGameUpdateTimer()
    }
    
    func startGameButtonPressed() {
        if let label = startGameLabel {
            pulseLabel(label)
        }
        errorMessageLabel.text = ""
        if let gameUuid = gameUuid, let playerUuid = player?.uuid, let game = self.game, let players = game.players, let player = player {
            if canStartGame(game, player, players) {
                print("Going to attempt an API call")
                gameManager.startGame(gameUuid: gameUuid, playerUuid: playerUuid)
                print("Made API call")
                resetGameUpdateTimer()
            }
        }
    }
    
    func playButtonPressed() {
        if let game = game, let player = player {
            if playerIsCurrentPlayer(player: player, game: game) {
                if let label = playLabel {
                    pulseLabel(label)
                }
                errorMessageLabel.text = ""
                if let gameUuid = gameUuid, let action = actionSelected {
                    if game.status == .running {
                        print("Going to attempt an API call")
                        gameManager.play(gameUuid: gameUuid, playerUuid: player.uuid, action: action)
                        print("Made API call")
                        resetGameUpdateTimer()
                    }
                }
            }
        }
    }
    
    func updateLabels() {
        if let label = self.shareLabel, let game = self.game {
            if game.status == .notStarted {
                if label.alpha == 0 {
                    fadeInNode(label)
                }
            }
        }
        
        if let label = self.startGameLabel, let game = self.game, let player = player, let players = game.players {
            if canStartGame(game, player, players) {
                if label.alpha == 0 {
                    fadeInNode(label)
                }
            }
            else {
                fadeOutNode(label)
            }
        }
        
        if let playLabel = self.playLabel, let actionPickerLabel = actionPickerLabel, let player = self.player, let game = self.game, let actionPickerField = actionPickerField {
            if game.status == .running && playerIsCurrentPlayer(player: player, game: game) {
                if playLabel.alpha == 0 {
                    fadeInNode(playLabel)
                }
                if actionPickerLabel.alpha == 0 {
                    fadeInNode(actionPickerLabel)
                    self.view?.addSubview(actionPickerField)
                    actionPickerField.isHidden = false
                }
            }
            else {
                fadeOutNode(playLabel)
                fadeOutNode(actionPickerLabel)
            }
        }
        
        if let label = self.currentPlayerLabel, let game = self.game {
            if let currentPlayer = game.currentPlayerNickname {
                let newLabelText = "Current player: \(formatDisplayNickname(currentPlayer))"
                updateLabelText(label, newLabelText)
            }
        }
        
        if let label = self.playersLabel, let game = self.game {
            let newLabelText = "Players: \(game.players?.map { "\(formatDisplayNickname($0.nickname)): \($0.nCards) cards"}.joined(separator: " | ") ?? "no details available")"
            updateLabelText(label, newLabelText)
        }
        
        if let label = self.handsLabel, let game = self.game {
            if game.status != .notStarted {
                if let hand = game.hands?.first(where:{$0.nickname != "" })?.hand {
                    let cards = hand.map(stringifyCard(_:))
                    updateLabelText(label, "Your hand: \(cards.joined(separator: ", "))")
                }
            }
        }
        
        if let label = self.historyLabel, let game = self.game {
            let newLabelText = "Moves this round: \(game.history?.map{ "\(formatDisplayNickname($0.player)): \($0.action)"}.joined(separator: " , ") ?? "none yet")"
            updateLabelText(label, newLabelText)
        }
    }
    
    func displayMessage(_ message: String) {
        isDisplayingMessage = true
        
        pauseGameUpdateTimer()
        errorMessageLabel.removeFromParent()
        errorMessageLabel.text = message
        errorMessageLabel.alpha = 0.0
        self.addChild(errorMessageLabel)
        
        fadeOutNode(shareLabel)
        fadeOutNode(statusLabel)
        fadeOutNode(adminLabel)
        fadeOutNode(playersLabel)
        fadeOutNode(currentPlayerLabel)
        fadeOutNode(maxCardsLabel)
        fadeOutNode(handsLabel)
        fadeOutNode(historyLabel)
        fadeOutNode(roundLabel)
        fadeOutNode(publicLabel)
        fadeOutNode(playLabel)
        fadeOutNode(startGameLabel)
        fadeOutNode(actionPickerLabel)
        if let actionPickerField = actionPickerField {
            actionPickerField.isHidden = true
        }
        
        fadeInNode(errorMessageLabel)
    }
    
    func clearMessage() {
        isDisplayingMessage = false
        fadeOutNode(errorMessageLabel)
        
        fadeInNode(shareLabel)
        fadeInNode(statusLabel)
        fadeInNode(adminLabel)
        fadeInNode(playersLabel)
        fadeInNode(currentPlayerLabel)
        fadeInNode(maxCardsLabel)
        fadeInNode(handsLabel)
        fadeInNode(historyLabel)
        fadeInNode(roundLabel)
        fadeInNode(publicLabel)
        
        if let game = game, let players = game.players, let player = player, let startGameLabel = startGameLabel, let playLabel = playLabel, let actionPickerField = actionPickerField {
            if canStartGame(game, player, players) && startGameLabel.alpha == 0 {
                fadeInNode(startGameLabel)
            }
            if playerIsCurrentPlayer(player: player, game: game) && playLabel.alpha == 0 {
                fadeInNode(playLabel)
                fadeInNode(actionPickerLabel)
                actionPickerField.isHidden = false
            }
        }
        
        resumeGameUpdateTimer()
        
    }
    
}
