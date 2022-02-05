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
    
    var gameManager: GameManager?
    var gameUpdateInterval = 0.05
    var gameUpdateTimer: Timer?
    var gameUpdateScheduled: Bool?
    var player: Player?
    var game: Game?
    var lastBet: Action?
    var displayedBet: Action?
    var messageLabel: SKLabelNode!
    var isDisplayingMessage = false
    var actionSelected: Action?
    var pressedPlayButton = false
    var playerLost = false
    var roundNumber: Int?
    var betScrollStartY: CGFloat = 0.0
    var betScrollLastY: CGFloat = 0.0
    var isBetScrolling = false
    var viewingBetIndex: Int?
    var adjustSceneAspectDone = false
    private var menuNavigateLabel: SKLabelNode?
    private var startGameLabel: SKLabelNode?
    private var playLabel: SKLabelNode?
    private var actionPickerView : UIPickerView?
    private var helloLabel : SKLabelNode?
    private var shareLabel : SKLabelNode?
    private var inviteAILabel : SKLabelNode?
    private var exitLabel : SKLabelNode?
    private var playerLabels : [SKLabelNode] = []
    private var playerCardSprites: [SKSpriteNode]?
    private var revealCardSprites: [[SKSpriteNode]]?
    private var revealNicknameLabels: [SKLabelNode]?
    private var cardLabels: [SKLabelNode]?
    private var betLabel: SKLabelNode?
    private var betScrollNode: SKNode?
    private var historyBets: [[SKSpriteNode]] = []
    private var helpLabelSprite: SKSpriteNode?
    private var manageRoomLabel: SKLabelNode?
    
    override func didMove(to view: SKView) {
        
        self.gameManager!.delegate = self
    
        self.menuNavigateLabel = childNode(withName: "//menuNavigateLabel") as? SKLabelNode
        menuNavigateLabel?.alpha = 0.0
        menuNavigateLabel?.text = NSLocalizedString("menu", comment: "Button name to move to StartScene")
        self.startGameLabel = childNode(withName: "//startGameLabel") as? SKLabelNode
        startGameLabel?.alpha = 0.0
        startGameLabel?.text = NSLocalizedString("startGame", comment: "Button name to start the game")
        self.playLabel = childNode(withName: "//playLabel") as? SKLabelNode
        playLabel?.alpha = 0.0
        playLabel?.text = NSLocalizedString("play", comment: "Button name to play a move")
        self.shareLabel = self.childNode(withName: "//shareLabel") as? SKLabelNode
        shareLabel?.alpha = 0.0
        shareLabel?.text = NSLocalizedString("share", comment: "Button name to share a game link")
        self.inviteAILabel = self.childNode(withName: "//inviteAILabel") as? SKLabelNode
        inviteAILabel?.alpha = 0.0
        inviteAILabel?.text = NSLocalizedString("inviteAI", comment: "Button name to invite an AI")
        self.exitLabel = self.childNode(withName: "//exitLabel") as? SKLabelNode
        exitLabel?.alpha = 0.0
        exitLabel?.text = NSLocalizedString("exit", comment: "Button name to exit the game")
        for i in 1...8 {
            if let label = self.childNode(withName: "//player\(i)Label") as? SKLabelNode {
                label.text = ""
                label.alpha = 0
                self.playerLabels.append(label)
            }
        }
        self.manageRoomLabel = self.childNode(withName: "//manageRoomLabel") as? SKLabelNode
        self.manageRoomLabel?.alpha = 0.0
        manageRoomLabel?.text = NSLocalizedString("openRoom", comment: "Button name to open the game room")
        
        messageLabel = SKLabelNode(fontNamed:"HelveticaNeue-Light")
        messageLabel.text = ""
        messageLabel.fontSize = 15
        messageLabel.position = CGPoint(x:self.frame.midX, y:self.frame.midY)
        messageLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        messageLabel.numberOfLines = 0
        messageLabel.preferredMaxLayoutWidth = size.width * 0.8
        messageLabel.verticalAlignmentMode = .center
        self.addChild(messageLabel)
        
        self.helloLabel = self.childNode(withName: "//helloLabel") as? SKLabelNode
        if let label = self.helloLabel {
            let helloText = NSLocalizedString("hello", comment: "Hello greeting")
            label.text = "\(helloText), \(formatDisplayNickname(player?.nickname ?? "new player"))"
            label.run(SKAction.fadeOut(withDuration: 2.0))
        }
        
        playerCardSprites = []
        for cardIndex in 0...10 {
            let sprite = SKSpriteNode(texture: SKTexture(image: #imageLiteral(resourceName: "empty")), size: CGSize(width: 70, height: 70))
            sprite.position = getPlayerCardPosition(cardIndex)
            addChild(sprite)
            playerCardSprites?.append(sprite)
        }
        cardLabels = []
        
        revealCardSprites = []
        for playerIndex in 0...7 {
            var sprites: [SKSpriteNode] = []
            for cardIndex in 0...10 {
                let sprite = SKSpriteNode(texture: SKTexture(image: #imageLiteral(resourceName: "empty")), size: CGSize(width: 50, height: 50))
                sprite.position = getOthersCardPosition(cardIndex: cardIndex, playerIndex: playerIndex)
                addChild(sprite)
                sprites.append(sprite)
            }
            revealCardSprites?.append(sprites)
        }
        
        revealNicknameLabels = []
        for playerIndex in 0...7 {
            let nicknameLabel = SKLabelNode(fontNamed:"HelveticaNeue-Light")
            nicknameLabel.text = ""
            nicknameLabel.fontSize = 15
            nicknameLabel.position = getOthersCardPosition(cardIndex: 0, playerIndex: playerIndex)
            nicknameLabel.position.x -= size.width * 0.05
            nicknameLabel.horizontalAlignmentMode = .right
            revealNicknameLabels?.append(nicknameLabel)
            self.addChild(nicknameLabel)
        }
        
        betScrollNode = SKNode()
        if let betScrollNode = betScrollNode {
            betScrollNode.position = getBetScrollNodePosition()
            self.addChild(betScrollNode)
        }
        
        self.betLabel = self.childNode(withName: "//betLabel") as? SKLabelNode
        if let betLabel = betLabel {
            betLabel.alpha = 0.0
            betLabel.position = getBetCardPosition(0)
        }

        let helpLabelSprite = SKSpriteNode(texture: SKTexture(image: #imageLiteral(resourceName: "help")), size: CGSize(width: 30, height: 30))
        helpLabelSprite.position = CGPoint(x: size.width*0.45, y: size.height*0.45)
        helpLabelSprite.name = "helpLabelSprite"
        addChild(helpLabelSprite)
        self.helpLabelSprite = helpLabelSprite
        
        resumeGameUpdateTimer()
    }
    
    func saveGame() {
        guard let game = gameManager?.game, let gameUuid = gameManager?.gameUuid, let player = gameManager?.player else {
            return
        }
        guard let currentGameSaved = SavedGame.init(game: game, gameUuid: gameUuid, player: player) else {
            return
        }
        var savedGames = pruneSavedGames(getSavedGames(), ifAtLeast: 3, downTo: 2)
        if game.status == .finished {
            savedGames.removeValue(forKey: gameUuid.uuidString)
        } else {
            savedGames[gameUuid.uuidString] = currentGameSaved
        }
        saveGames(savedGames)
    }
    
    /**
     Request updated game state.
     */
    @objc func updateGame() {
        gameManager?.receiveWatchGameWebsocket()
    }
    
    func didFailWithError(error: Error) {
        let messageText = NSLocalizedString("errorMessage", comment: "Message to say something went wrong")
        displayMessage(messageText)
    }
    
    func didJoinGame() {
        if let label = startGameLabel {
            fadeOutNode(label)
            label.removeFromParent()
        }
        updateGame()
    }
    
    func didStartGame() {
        if let label = startGameLabel {
            fadeOutNode(label)
            label.removeFromParent()
        }
        updateGame()
    }
    
    func didMakeGamePublic() {
        updateGame()
    }
    
    func didMakeGamePrivate() {
        updateGame()
    }
    
    func didUpdateGame(_ game: Game) {
        print(game)
        if game.lastModified <= self.game?.lastModified ?? 0 {
            if let receivedHands = game.hands {
                if game.roundNumber < self.game?.roundNumber ?? 0 && game.hands?.count ?? 0 > 1 {
                    print("Received an old game state update, but will display hands")
                    displayHands(receivedHands)
                }
            } else {
                print("Received an old game state update, ignoring")
            }
            return
        }
        self.game = game
        saveGame()
        self.lastBet = game.history?.last?.action
        if game.status == .running {
            self.roundNumber = game.roundNumber
        }
        
        if let hands = game.hands {
            
            if hands.count > 1 {
                displayHands(hands)
                self.roundNumber = nil // Go to the latest round
            }
        }
        
        if actionSelected != nil {
            if let game = self.game, let player = player {
                if !playerIsCurrentPlayer(player: player, game: game) {
                    actionSelected = nil
                }
            }
        }
        updateGameUI()
    }
    
    func didResetWatchGameWebsocket() {
        self.gameManager?.updateGame(round: self.roundNumber)
    }
    
    func didPlay(_ game: Game) {
        if let playLabel = playLabel {
            fadeOutNode(playLabel)
        }
        didUpdateGame(game)
    }
    
    func failedIllegalPlay() {
        print("failedIllegalPlay")
        let messageText = NSLocalizedString("illegalMoveMessage", comment: "Message to say you can't do that")
        displayMessage(messageText)
    }
    
    func getActionPickerView() {
        let windowSize = self.view!.frame.size
        let originalAspect = originalSize.width / originalSize.height
        let windowAspect = windowSize.width / windowSize.height
        let xScaling = max(1.0, windowAspect / originalAspect)
        let yScaling = max(1.0, originalAspect / windowAspect)
        let width = UIScreen.main.bounds.width * 0.45 / xScaling
        let height = UIScreen.main.bounds.height * 0.35 / yScaling
        let xPosition = UIScreen.main.bounds.width * computeRescaledPosition(0.5, xScaling)
        let yPosition = UIScreen.main.bounds.height * computeRescaledPosition(0.5, yScaling)
        self.actionPickerView = UIPickerView(frame: CGRect(x: xPosition, y: yPosition, width: width, height: height))
        if let actionPickerView = actionPickerView {
            actionPickerView.dataSource = self
            actionPickerView.delegate = self
            actionPickerView.layer.zPosition = 10
            self.view?.addSubview(actionPickerView)
        }
    }
    
    func clearActionPickerView() {
        for subView in self.view?.subviews ?? [] {
            if let picker = subView as? UIPickerView {
                picker.removeFromSuperview()
            }
        }
    }
    
    func touchDown(atPoint pos : CGPoint) {
        self.view?.endEditing(true)
        let nodesarray = nodes(at: pos)
        for node in nodesarray {
            if node.name == "betScrollArea" {
                isBetScrolling = true
            }
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        
    }
    
    func touchUp(atPoint pos : CGPoint) {
        isBetScrolling = false
        if self.isDisplayingMessage {
            clearMessage()
        }
        else {
            let nodesarray = nodes(at: pos)
            for node in nodesarray {
                if node.name == "startGameButton" {
                    startGameButtonPressed()
                }
                if node.name == "playButton" {
                    if !pressedPlayButton {
                        playButtonPressed()
                    }
                }
                if node.name == "shareButton" {
                    shareButtonPressed()
                }
                if node.name == "exitButton" {
                    exitButtonPressed()
                }
                if node.name == "helpLabelSprite" {
                    helpLabelSpritePressed()
                }
                if node.name == "inviteAIButton" {
                    inviteAIButtonPressed()
                }
                if node.name == "manageRoomButton" {
                    manageRoomButtonPressed()
                }
                if node.name == "menuNavigateButton" {
                    menuNavigateButtonPressed()
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
        if let yLocation = touches.first?.location(in: self).y {
            betScrollStartY = yLocation
            betScrollLastY = yLocation
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let pos = t.location(in: self)
            self.touchMoved(toPoint: pos)
            
            if isBetScrolling {
                moveBetScroll(pos.y)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        updateHistoryBetsAlpha()
        updateBettingPlayerLabel()
        adjustSceneAspect(self)
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
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let actionId = getActionIdForRow(row)
        if let action = Action.init(rawValue: actionId){
            self.actionSelected = action
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label = UILabel()
        if let v = view as? UILabel { label = v }
        label.font = UIFont(name: "HelveticaNeue-Light", size: 18)
        label.adjustsFontSizeToFitWidth = true
        label.textColor = .white
        label.textAlignment = .center
        let actionId = getActionIdForRow(row)
        label.text = "?"
        if let action = Action.init(rawValue: actionId) {
            label.text = String(describing: action.description)
        }
        return label
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
        gameManager?.resetWatchGameWebsocket()
        gameUpdateTimer = Timer.scheduledTimer(timeInterval: self.gameUpdateInterval, target: self, selector: #selector(updateGame), userInfo: nil, repeats: true)
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
    
    func moveBetScroll(_ currentY: CGFloat) {
        guard let betScrollNode = betScrollNode else {
            isBetScrolling = false
            return
        }
        
        // Set Top and Bottom scroll distances
        let topLimit = getTopScrollLimit()
        let bottomLimit = CGFloat(0)

        // Set scrolling speed - Higher number is faster speed
        let scrollSpeed:CGFloat = 1.0

        // Calculate distance moved since last touch registered and add it to current position
        let newY = betScrollNode.position.y + ((currentY - betScrollLastY)*scrollSpeed)

        // Perform checks to see if new position will be over the limits, otherwise set as new position
        if newY < -topLimit {
            betScrollNode.position = CGPoint(x: betScrollNode.position.x, y: -topLimit)
        }
        else if newY > bottomLimit {
            betScrollNode.position = CGPoint(x: betScrollNode.position.x, y: bottomLimit)
        }
        else {
            betScrollNode.position = CGPoint(x: betScrollNode.position.x, y: newY)
        }

        // Set new last location for next time
        betScrollLastY = currentY
    }
    
    func startGameButtonPressed() {
        if let game = game {
            if game.status != .notStarted {
                return
            }
        }
        if let label = startGameLabel {
            pulseLabel(label)
        }
        messageLabel.text = ""
        if let game = self.game, let players = game.players, let player = player {
            if canStartGame(game, player, players) {
                print("Going to attempt an API call")
                gameManager?.startGame()
                print("Made API call")
            }
        }
    }
    
    func playButtonPressed() {
        pressedPlayButton = true
        if let game = game, let player = player {
            if playerIsCurrentPlayer(player: player, game: game) {
                if let label = playLabel {
                    pulseLabel(label)
                }
                messageLabel.text = ""
                if let action = actionSelected {
                    if game.status == .running {
                        print("Going to attempt an API call")
                        gameManager?.play(action: action)
                        print("Made API call")
                    }
                }
            }
        }
        pressedPlayButton = false
    }
    
    func shareButtonPressed() {
        if let game = game {
            if game.status != .notStarted {
                return
            }
        }
        if let game = self.game, let players = game.players {
            if !canShare(game, players) {
                return
            }
        }
        let pasteboard = UIPasteboard.general
        let messageText = NSLocalizedString("shareMessage", comment: "Message to say share the link with another player")
        displayMessage(messageText)
        
        let firstActivityItem = NSLocalizedString("inviteString", comment: "Text message to invite someone with")
        if let uuid = gameManager?.gameUuid?.uuidString.lowercased() {
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
    
    func inviteAIButtonPressed() {
        if let game = game {
            if game.status != .notStarted {
                return
            }
        }
        if let label = inviteAILabel {
            pulseLabel(label)
        }
        messageLabel.text = ""
        if let game = self.game, let players = game.players, let player = player {
            if canInviteAI(game, player, players) {
                print("Going to attempt an API call")
                gameManager?.inviteAI()
                print("Made API call")
            }
        }
    }
    
    func exitButtonPressed() {
        if let game = game {
            if game.status != .finished {
                return
            }
        }
        let startScene = StartScene(fileNamed: "StartScene")
        let transition = SKTransition.fade(withDuration: 1.0)
        startScene?.scaleMode = .aspectFit
        pauseGameUpdateTimer()
        self.removeFromParent()
        scene?.view?.presentScene(startScene!, transition: transition)
    }
    
    func helpLabelSpritePressed() {
        let gameRules = NSLocalizedString("gameRules", comment: "Multi-line description of the game rules")
        displayMessage(gameRules)
    }
    
    func manageRoomButtonPressed() {
        if let player = self.player, let game = self.game {
            if canManageRoom(game, player) {
                if let label = manageRoomLabel {
                    pulseLabel(label)
                }
                if game.isPublic {
                    gameManager?.makeGamePrivate()
                } else {
                    gameManager?.makeGamePublic()
                }
            }
        }
    }
    
    func menuNavigateButtonPressed() {
        if let label = menuNavigateLabel {
            pulseLabel(label)
        }
        moveToStartScene()
    }
    
    func moveToStartScene() {
        if let startScene = StartScene(fileNamed: "StartScene") {
            let transition = SKTransition.fade(withDuration: 1.0)
            startScene.scaleMode = .aspectFit
            clearActionPickerView()
            scene?.view?.presentScene(startScene, transition: transition)
        }
    }
    
    func displayHands(_ hands: [NamedHand]) {
        if let revealCardSprites = revealCardSprites, let revealNicknameLabels = revealNicknameLabels {
            fadeOutNode(messageLabel)
            displayMessage("")
            
            let youText = NSLocalizedString("you", comment: "Second person singular pronoun")
            var playerIndex = 0
            for namedHand in hands {
                let nickname = (namedHand.nickname == player?.nickname ? youText : formatDisplayNickname(namedHand.nickname) )
                if namedHand.hand.count == 0 {
                    continue
                }
                updateAndDisplayLabel(revealNicknameLabels[playerIndex], nickname)
                for (cardIndex, card) in namedHand.hand.enumerated() {
                    if let image = getCardImage(card) {
                        revealCardSprites[playerIndex][cardIndex].texture = image
                        fadeInNode(revealCardSprites[playerIndex][cardIndex])
                    }
                }
                playerIndex += 1
            }
        }
    }
    
    func clearDisplayedHands() {
        if let revealNicknameLabels = revealNicknameLabels {
            for label in revealNicknameLabels {
                fadeOutNode(label)
                label.text = ""
            }
        }
        if let revealCardSprites = revealCardSprites {
            for sprites in revealCardSprites {
                for sprite in sprites {
                    fadeOutNode(sprite)
                }
            }
        }
    }

    func updatePlayerLabels() {
        guard let game = self.game, let players = game.players, let player = player else {
            return
        }
        for (i, playerObject) in players.enumerated() {
            if i > playerLabels.endIndex {
                continue
            }
            let playerText = NSLocalizedString("player", comment: "The noun describing a game participant")
            var displayNickname = formatDisplayNickname(playerObject.nickname)
            if playerObject.nickname == player.nickname ?? "\(playerText) \(i)" {
                displayNickname = NSLocalizedString("you", comment: "Second person singular pronoun")
            }
            var cardsStatus = ""
            if playerObject.nCards > 0 {
                if game.status == .running {
                    cardsStatus = String(playerObject.nCards)
                } else {
                    cardsStatus = NSLocalizedString("won", comment: "Third person perfect aspect of the verb to win")
                }
            } else if game.status == .finished {
                cardsStatus = NSLocalizedString("lost", comment: "Third person perfect aspect of the verb to lose")
            }
            let label = playerLabels[i]
            label.text = "\(displayNickname): \(cardsStatus)"
            
            if playerObject.nickname == game.currentPlayerNickname {
                label.fontSize = 20
            } else {
                label.fontSize = 15
            }
        }
    }
    
    func updateBettingPlayerLabel() {
        guard let viewingBetIndex = viewingBetIndex, let players = game?.players, let history = game?.history else {
            return
        }
        if history.count <= viewingBetIndex {
            if let players = game?.players {
                for (i, _) in players.enumerated() {
                    if i <= playerLabels.endIndex {
                        playerLabels[i].removeEffects()
                    }
                }
            }
            return
        }
        let viewingBetOfPlayerNickname = history[viewingBetIndex].player
        for (i, playerObject) in players.enumerated() {
            if i > playerLabels.endIndex {
                break
            }
            let label = playerLabels[i]
            if playerObject.nickname == viewingBetOfPlayerNickname {
                label.addGlow()
            } else {
                label.removeEffects()
            }
        }
    }
    
    func updateHistoryBets() {
        guard let betScrollNode = betScrollNode, let game = game, let history = game.history else {
            return
        }
        betScrollNode.position.y -= getCardSize().height
        let newPosition = getBetScrollNodePosition()
        let scrollAction = SKAction.move(to: newPosition, duration: TimeInterval(0.5))
        betScrollNode.run(scrollAction)
        for sprites in historyBets {
            for sprite in sprites {
                sprite.alpha = 0
            }
        }
        betScrollNode.removeAllChildren()
        historyBets = []
        for (betIndex, bet) in history.enumerated() {
            if let images = BetToCards[bet.action] {
                var newBetSprites: [SKSpriteNode] = []
                let centeringOffset = Double(6 - images.count) / 2
                for (cardIndex, cardImage) in images.enumerated() {
                    let sprite = SKSpriteNode(texture: SKTexture(image: cardImage), size: getCardSize())
                    
                    sprite.position = getBetCardPosition(cardIndex, withBetIndexOffset: history.count - betIndex - 1, withCenteringOffset: centeringOffset)
                    sprite.alpha = 0
                    betScrollNode.addChild(sprite)
                    newBetSprites.append(sprite)
                }
                historyBets.append(newBetSprites)
            }
        }
    }
    
    func clearCardAndBetLabelsAtRoundStart() {
        /*
         Clear cardLabels amd betLabel at round start
         NOTE: these two are never displayed,
               unless card images are missing
         */
        if let game = self.game, let history = game.history {
            if history.count == 0 {
                if let cardLabels = cardLabels {
                    for label in cardLabels {
                        label.removeFromParent()
                    }
                }
                self.cardLabels = []
                if let betLabel = betLabel {
                    betLabel.text = ""
                }
            }
        }
    }
    
    func updateCards() {
        // Update playerCardSprites (and in emergency, cardLabels)
        if let game = self.game, let player = player {

            clearCardAndBetLabelsAtRoundStart()

            if game.status != .notStarted {
                // If game was started
                if let hand = game.hands?.first(where:{$0.nickname == player.nickname })?.hand, let playerCardSprites = playerCardSprites {
                    if !playerLost && game.status != .finished {
                        for (cardIndex, card) in hand.enumerated() {
                            if let image = getCardImage(card) {
                                playerCardSprites[cardIndex].texture = image
                            }
                            else {
                                let cardLabel = getCardLabel(card)
                                cardLabel.position = getPlayerCardPosition(cardIndex)
                                addChild(cardLabel)
                                cardLabels?.append(cardLabel)
                            }
                        }
                    }
                }
            } else {
                // Clear playerCardSprites
                if let playerCardSprites = playerCardSprites {
                    resetCardSprites(playerCardSprites)
                }
            }
        }
    }
    
    func updateLabelValues() {
        updateHistoryBets()
        updateCards()
        updatePlayerLabels()
    }
    
    func updateGameUI() {
        updateLabelValues()
        if isDisplayingMessage {
            return
        }
        displayLabels()
    }
    
    func displayExitLabel() {
        if let label = self.exitLabel, let game = self.game {
            if game.status == .finished {
                if label.alpha < 1 {
                    fadeInNode(label)
                }
            }
        }
    }
    
    func displayHelpLabelSprite() {
        if let label = self.helpLabelSprite {
            if label.alpha < 1 {
                fadeInNode(label)
            }
        }
    }
    
    func displayShareLabel() {
        if let label = self.shareLabel, let game = self.game, let players = game.players {
            if game.status == .notStarted && canShare(game, players) {
                if label.alpha < 1 {
                    fadeInNode(label)
                    slowPulseLabel(label)
                }
            }
            else {
                if label.alpha > 0 {
                    fadeOutNode(label)
                }
            }
        }
    }
    
    func displayInviteAILabel() {
        if let label = self.inviteAILabel, let game = self.game, let player = self.player, let players = game.players {
            if game.status == .notStarted && canInviteAI(game, player, players) {
                if label.alpha < 1 {
                    fadeInNode(label)
                    slowPulseLabel(label)
                }
            }
            else {
                if label.alpha > 0 {
                    fadeOutNode(label)
                }
            }
        }
    }
    
    func displayMenuNavigateLabel() {
        fadeInNode(menuNavigateLabel)
    }
    
    func clearMenuNavigateLabel() {
        fadeOutNode(menuNavigateLabel)
    }
    
    func displayStartGameLabel() {
        if let label = self.startGameLabel, let game = self.game, let player = player, let players = game.players {
            if canStartGame(game, player, players) {
                if label.alpha < 1 {
                    fadeInNode(label)
                }
            }
            else {
                fadeOutNode(label)
            }
        }
    }
    
    func displayPlayLabel() {
        if let playLabel = self.playLabel, let player = self.player, let game = self.game {
            if game.status == .running && playerIsCurrentPlayer(player: player, game: game) {
                pressedPlayButton = false
                if playLabel.alpha < 1 {
                    fadeInNode(playLabel)
                    getActionPickerView()
                }
            }
            else {
                fadeOutNode(playLabel)
                clearActionPickerView()
            }
        }
    }
    
    func displayVictoryStatusMessage() {
        if let game = game, let player = player {

            if let playerInfo = game.players?.first(where:{$0.nickname == player.nickname }) {
                
                if game.status == .finished {
                    if playerInfo.nCards > 0 {
                        let youWonMessage = NSLocalizedString("youWon", comment: "Message to say that you won in the game")
                        displayMessage(youWonMessage)
                    }
                    else {
                        let gameOverMessage = NSLocalizedString("gameOver", comment: "Message to say that the game is over")
                        displayMessage(gameOverMessage)
                    }
                }
                else if game.status != .notStarted && playerInfo.nCards == 0 {
                    if !playerLost {
                        playerLost = true
                        let youLostMessage = NSLocalizedString("youLost", comment: "Message to say that you lost in the game")
                        displayMessage(youLostMessage)
                    }
                }
            }
        }
    }
    
    func displayCards() {
        for sprite in playerCardSprites ?? [] {
            fadeInNode(sprite)
        }
    }
    
    func updateHistoryBetsAlpha() {
        guard let betScrollNode = betScrollNode else {
            return
        }
        if isDisplayingMessage {
            return
        }
        let yDisplacement = betScrollNode.position.y - getBetScrollNodePosition().y
        let cardHeight = getCardSize().height
        var maxAlphaIndex: Int?
        var maxAlpha = CGFloat(0)
        for (spriteIndex, sprites) in historyBets.enumerated() {
            var newAlpha = CGFloat(0)
            for sprite in sprites {
                newAlpha = getBetSpriteAlpha(sprite, with: yDisplacement, range: cardHeight)
                sprite.alpha = newAlpha
            }
            if newAlpha > maxAlpha {
                maxAlpha = newAlpha
                maxAlphaIndex = spriteIndex
            }
        }
        if let maxAlphaIndex = maxAlphaIndex {
            self.viewingBetIndex = maxAlphaIndex
        }
    }
    
    func getBetSpriteAlpha(_ sprite: SKSpriteNode, with displacement: CGFloat, range: CGFloat) -> CGFloat {
        let distanceRatio = (sprite.position.y - (-displacement)) / range
        return 1 - min(1.0, max(0, abs(distanceRatio)))
    }
        
    func clearHistoryBets() {
        for sprites in historyBets {
            for sprite in sprites {
                fadeOutNode(sprite)
            }
        }
    }
    
    func clearPlayerLabels() {
        for label in playerLabels {
            fadeOutNode(label)
        }
    }
    
    func displayManageRoomLabel() {
        guard let label = self.manageRoomLabel else {
            return
        }
        if let player = self.player, let game = self.game, let room = game.room {
            if canManageRoom(game, player) {
                label.text = NSLocalizedString("openRoom", comment: "Button name to open the game room")
                if game.isPublic {
                    let roomText = NSLocalizedString("room", comment: "The noun meaning a closed space that can be occupied")
                    label.text = "\(roomText) \(room)"
                }
                fadeInNode(label)
                return
            }
        }
        fadeOutNode(label)
    }
    
    func displayPlayerLabels() {
        for label in playerLabels {
            fadeInNode(label)
        }
    }
    
    func displayLabels() {
        displayCards()
        displayExitLabel()
        displayHelpLabelSprite()
        displayShareLabel()
        displayInviteAILabel()
        displayMenuNavigateLabel()
        displayStartGameLabel()
        displayPlayLabel()
        displayVictoryStatusMessage()
        displayManageRoomLabel()
        displayPlayerLabels()
        displayMenuNavigateLabel()
    }
    
    func getPlayerCardPosition(_ cardIndex: Int) -> CGPoint {
        return CGPoint(x: size.width * -0.45 + CGFloat(60*cardIndex), y: size.height * -0.4)
    }
    
    func getOthersCardPosition(cardIndex: Int, playerIndex: Int) -> CGPoint {
        var xOffset = CGFloat(40*cardIndex)
        var yOffset = CGFloat(-70*playerIndex)
        if playerIndex > 4 {
            xOffset += size.width * 0.4
            yOffset += CGFloat(310)
        }
        return CGPoint(x: size.width * -0.15 + xOffset, y: size.width * 0.2 + yOffset)
    }
    
    func getBetCardPosition(_ cardIndex: Int, withBetIndexOffset yOffset: Int = 0, withCenteringOffset xOffset: Double = 0 ) -> CGPoint {
        return CGPoint(x: CGFloat(60*cardIndex) + CGFloat(60*xOffset), y: CGFloat(80*yOffset))
    }
    
    func getCardSize() -> CGSize {
        return CGSize(width: 80, height: 80)
    }
    
    func getBetScrollNodePosition(offsetByNumBets: Int = 0) -> CGPoint {
        return CGPoint(x: size.width * -0.45, y: CGFloat(-max(0, offsetByNumBets)) * getCardSize().height)
    }
    
    func getTopScrollLimit() -> CGFloat{
        guard let game = game, let history = game.history else {
            return CGFloat(0)
        }
        return getCardSize().height * CGFloat((history.count-1))
    }
    
    func clearGameLabels() {
        messageLabel.alpha = 0.0
        shareLabel?.removeAllActions()
        inviteAILabel?.removeAllActions()
        fadeOutNode(shareLabel)
        fadeOutNode(inviteAILabel)
        fadeOutNode(exitLabel)
        fadeOutNode(helpLabelSprite)
        fadeOutNode(playLabel)
        clearActionPickerView()
        fadeOutNode(startGameLabel)
        fadeOutNode(manageRoomLabel)
        for sprite in playerCardSprites ?? [] {
            fadeOutNode(sprite)
        }
        clearMenuNavigateLabel()
        clearHistoryBets()
        clearPlayerLabels()
    }
    
    func displayMessage(_ message: String) {
        isDisplayingMessage = true
        clearGameLabels()
        messageLabel.text = message
        fadeInNode(messageLabel)
    }
    
    func clearMessage() {
        isDisplayingMessage = false
        fadeOutNode(messageLabel)
        clearDisplayedHands()
        displayLabels()
    }
    
}
