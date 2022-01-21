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
    private var startGameLabel: SKLabelNode?
    private var playLabel: SKLabelNode?
    private var actionPickerView : UIPickerView?
    private var helloLabel : SKLabelNode?
    private var shareLabel : SKLabelNode?
    private var inviteAILabel : SKLabelNode?
    private var exitLabel : SKLabelNode?
    private var currentPlayerLabel : SKLabelNode?
    private var playersLabel : SKLabelNode?
    private var actionPickerField: UITextField?
    private var playerCardSprites: [SKSpriteNode]?
    private var revealCardSprites: [[SKSpriteNode]]?
    private var revealNicknameLabels: [SKLabelNode]?
    private var cardLabels: [SKLabelNode]?
    private var betSprites: [SKSpriteNode]?
    private var betLabel: SKLabelNode?
    private var betScrollNode: SKNode?
    private var historyBets: [[SKSpriteNode]] = []
    private var helpLabelSprite: SKSpriteNode?
    private var manageRoomLabel: SKLabelNode?
    
    override func didMove(to view: SKView) {
        
        self.gameManager!.delegate = self
        
        self.startGameLabel = childNode(withName: "//startGameLabel") as? SKLabelNode
        startGameLabel?.alpha = 0.0
        self.playLabel = childNode(withName: "//playLabel") as? SKLabelNode
        playLabel?.alpha = 0.0
        self.shareLabel = self.childNode(withName: "//shareLabel") as? SKLabelNode
        shareLabel?.alpha = 0.0
        self.inviteAILabel = self.childNode(withName: "//inviteAILabel") as? SKLabelNode
        inviteAILabel?.alpha = 0.0
        self.exitLabel = self.childNode(withName: "//exitLabel") as? SKLabelNode
        exitLabel?.alpha = 0.0
        self.currentPlayerLabel = self.childNode(withName: "//currentPlayerLabel") as? SKLabelNode
        currentPlayerLabel?.alpha = 0.0
        self.playersLabel = self.childNode(withName: "//playersLabel") as? SKLabelNode
        playersLabel?.alpha = 0.0
        playersLabel?.numberOfLines = 0
        playersLabel?.preferredMaxLayoutWidth = 400
        self.manageRoomLabel = self.childNode(withName: "//manageRoomLabel") as? SKLabelNode
        self.manageRoomLabel?.alpha = 0.0

        self.actionPickerField = UITextField(frame: CGRect(x: UIScreen.main.bounds.size.width * 0.65, y: UIScreen.main.bounds.size.height * 0.2, width: 200, height: 30))
        
        actionPickerView = UIPickerView()
        actionPickerView?.dataSource = self
        actionPickerView?.delegate = self
        if let myField = actionPickerField {
            myField.inputView = actionPickerView
            myField.font = UIFont(name: "HelveticaNeue-Light", size: 20)
            myField.textColor = .black
            myField.backgroundColor = .lightGray
            myField.borderStyle = UITextField.BorderStyle.roundedRect
            myField.delegate = self
        }
        
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
            label.text = "Hello, \(formatDisplayNickname(player?.nickname ?? "new player"))"
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
                
        betSprites = []
        for cardIndex in 0...5 {
            let sprite = SKSpriteNode(texture: SKTexture(image: #imageLiteral(resourceName: "empty")), size: CGSize(width: 80, height: 80))
            sprite.position = getBetCardPosition(cardIndex)
            betScrollNode?.addChild(sprite)
            betSprites?.append(sprite)
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
    
    /**
     Request updated game state.
     */
    @objc func updateGame() {
        gameManager?.receiveWatchGameWebsocket()
    }
    
    func didFailWithError(error: Error) {
        displayMessage("Something went wrong.")
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
        if game.lastModified < self.game?.lastModified ?? 0 {
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
        if let playLabel = playLabel, let actionPickerField = actionPickerField {
            fadeOutNode(playLabel)
            actionPickerField.text = ""
            actionPickerField.isHidden = true
            actionPickerField.removeFromSuperview()
        }
        didUpdateGame(game)
    }
    
    func failedIllegalPlay() {
        print("failedIllegalPlay")
        displayMessage("You can't do that now")
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
            return String(describing: action.description)
        }
        return "?"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let actionId = getActionIdForRow(row)
        if let myField = actionPickerField, let action = Action.init(rawValue: actionId){
            myField.text = String(describing: action.description)
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
        displayMessage("Share the link with another player")
        
        let firstActivityItem = "Join me for a game of Blef"
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
        let gameRules = """
                        Game rules

                        There are 24 cards in the deck (9 to Ace).
                        New cards are dealt to each player at the start of each round.

                        In Blef, you can only bet or check.
                        E.g. if you bet "Pair of 9s", you are betting that at least two 9s can be found among all cards dealt this round.
                        
                        If anyone checks, the round ends.
                        If someone checks your bet and it can't be found among all cards, you lose the round and gain a card.
                        If your bet was correct, the player who checked you loses and gains a card.

                        Reach too many cards and you're out of the game.
                        """
        displayMessage(gameRules)
    }
    
    func manageRoomButtonPressed() {
        if let player = self.player, let game = self.game {
            if canManageRoom(game, player) {
                if game.isPublic {
                    gameManager?.makeGamePrivate()
                } else {
                    gameManager?.makeGamePublic()
                }
            }
        }
    }
    
    func displayHands(_ hands: [NamedHand]) {
        if let revealCardSprites = revealCardSprites, let revealNicknameLabels = revealNicknameLabels {
            fadeOutNode(messageLabel)
            displayMessage("")
            
            var playerIndex = 0
            for namedHand in hands {
                let nickname = (namedHand.nickname == player?.nickname ? "You" : formatDisplayNickname(namedHand.nickname) )
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
    
    func updateCurrentPlayerLabel() {
        // Update currentPlayerLabel
        if let label = self.currentPlayerLabel, let game = self.game, let currentPlayer = game.currentPlayerNickname, let player = player {
            var newLabelText: String
            if playerIsCurrentPlayer(player: player, game: game) {
                newLabelText = "Current player: You"
            }
            else {
                newLabelText = "Current player: \(formatDisplayNickname(currentPlayer))"
            }
            updateLabelText(label, newLabelText)
        }
    }
    
    func computePlayersStrings(_ game: Game, _ players: [PlayerInfo], _ player: Player) -> [String] {
        // Construct strings describing each player
        var playersStrings: [String] = []
        if game.status == .notStarted {
            for playerObject in players {
                if player.nickname == playerObject.nickname {
                    playersStrings.append("You")
                }
                else {
                    playersStrings.append("\(formatDisplayNickname(playerObject.nickname))")
                }
            }
        }
        else if game.status == .finished {
            for playerObject in players {
                var statusString = ""
                if playerObject.nCards == 0 {
                    statusString = "lost"
                }
                else {
                    statusString = "won"
                }
                if player.nickname == playerObject.nickname {
                    playersStrings.append("You: \(statusString)")
                }
                else {
                    playersStrings.append("\(formatDisplayNickname(playerObject.nickname)): \(statusString)")
                }
            }
        }
        else {
            for playerObject in players {
                var nCardsString = ""
                if playerObject.nCards == 0 {
                    nCardsString = "lost"
                }
                else {
                    nCardsString = String(playerObject.nCards)
                }
                if player.nickname == playerObject.nickname {
                    playersStrings.append("You: \(nCardsString)")
                }
                else {
                    playersStrings.append("\(formatDisplayNickname(playerObject.nickname)): \(nCardsString)")
                }
            }
        }
        return playersStrings
    }
    
    func updatePlayersLabel() {
        // Update playersLabel
        if let label = self.playersLabel, let game = self.game, let players = game.players, let player = player {
            let playersStrings = computePlayersStrings(game, players, player)
            let newLabelText = "Players: \(playersStrings.joined(separator: " | "))"
            updateLabelText(label, newLabelText)
        }

    }
    
    func updateLastBet() {
        // Update betSprites (and in emergency, betLabel text)
        if let lastBet = lastBet {
            if displayedBet != lastBet {
                if let images = BetToCards[lastBet], let betSprites = betSprites {
                    resetCardSprites(betSprites)
                    for (cardIndex, image) in images.enumerated() {
                        betSprites[cardIndex].texture = SKTexture(image: image)
                    }
                }
                else if let betLabel = betLabel {
                    updateLabelText(betLabel, String(describing: lastBet))
                }
                self.displayedBet = lastBet
            }
        }
        else {
            if let betSprites = betSprites {
                resetCardSprites(betSprites)
                self.displayedBet = nil
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
        betScrollNode.removeAllChildren()
        for (betIndex, bet) in history.enumerated() {
            if let images = BetToCards[bet.action] {
                var newBetSprites: [SKSpriteNode] = []
                for (cardIndex, cardImage) in images.enumerated() {
                    let sprite = SKSpriteNode(texture: SKTexture(image: cardImage), size: getCardSize())
                    sprite.position = getBetCardPosition(cardIndex, withBetIndexOffset: history.count - betIndex - 1)
                    if isDisplayingMessage {
                        sprite.alpha = 0
                    }
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
        updateCurrentPlayerLabel()
        updatePlayersLabel()
        updateLastBet()
        updateHistoryBets()
        updateCards()
    }
    
    func updateGameUI() {
        updateLabelValues()
        if isDisplayingMessage {
            return
        }
        displayLabels()
    }
    
    func displayPlayersLabel() {
        if let label = self.playersLabel {
            fadeInNode(label)
        }
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
        if let playLabel = self.playLabel, let player = self.player, let game = self.game, let actionPickerField = actionPickerField {
            if game.status == .running && playerIsCurrentPlayer(player: player, game: game) {
                pressedPlayButton = false
                if playLabel.alpha < 1 {
                    fadeInNode(playLabel)
                }
                if self.view != nil && !actionPickerField.isDescendant(of: self.view!) {
                    self.view!.addSubview(actionPickerField)
                }
                actionPickerField.isHidden = false
            }
            else {
                if self.view != nil && actionPickerField.isDescendant(of: self.view!) {
                    actionPickerField.removeFromSuperview()
                }
                actionPickerField.isHidden = true
                fadeOutNode(playLabel)
            }
        }
    }
    
    func displayVictoryStatusMessage() {
        if let game = game, let player = player {

            if let playerInfo = game.players?.first(where:{$0.nickname == player.nickname }) {
                
                if game.status == .finished {
                    if playerInfo.nCards > 0 {
                        displayMessage("You won")
                    }
                    else {
                        displayMessage("Game over")
                    }
                }
                else if game.status != .notStarted && playerInfo.nCards == 0 {
                    if !playerLost {
                        playerLost = true
                        displayMessage("You lost")
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
    
    func displayBet() {
        for sprite in betSprites ?? [] {
            fadeInNode(sprite)
        }
    }
    
    func displayHistoryBets() {
        for sprites in historyBets {
            for sprite in sprites {
                fadeInNode(sprite)
            }
        }
    }
    
    func clearHistoryBets() {
        for sprites in historyBets {
            for sprite in sprites {
                fadeOutNode(sprite)
            }
        }
    }
    
    func displayManageRoomLabel() {
        guard let label = self.manageRoomLabel else {
            return
        }
        if let player = self.player, let game = self.game, let room = game.room {
            if canManageRoom(game, player) {
                label.text = "Open the room"
                if game.isPublic {
                    label.text = "Room \(room)"
                }
                fadeInNode(label)
                return
            }
        }
        fadeOutNode(label)
    }
    
    func displayLabels() {
        displayCards()
        displayBet()
        displayHistoryBets()
        displayPlayersLabel()
        displayExitLabel()
        displayHelpLabelSprite()
        displayShareLabel()
        displayInviteAILabel()
        displayStartGameLabel()
        displayPlayLabel()
        displayVictoryStatusMessage()
        displayManageRoomLabel()
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
    
    func getBetCardPosition(_ cardIndex: Int, withBetIndexOffset yOffset: Int = 0) -> CGPoint {
        return CGPoint(x: CGFloat(60*cardIndex), y: CGFloat(80*yOffset))
    }
    
    func getCardSize() -> CGSize {
        return CGSize(width: 80, height: 80)
    }
    
    func getBetScrollNodePosition(offsetByNumBets: Int = 0) -> CGPoint {
        return CGPoint(x: size.width * -0.35, y: CGFloat(-max(0, offsetByNumBets)) * getCardSize().height)
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
        fadeOutNode(playersLabel)
        fadeOutNode(currentPlayerLabel)
        fadeOutNode(playLabel)
        fadeOutNode(startGameLabel)
        fadeOutNode(manageRoomLabel)
        if let actionPickerField = actionPickerField {
            actionPickerField.isHidden = true
        }
        
        for sprite in playerCardSprites ?? [] {
            fadeOutNode(sprite)
        }
        for sprite in betSprites ?? [] {
            fadeOutNode(sprite)
        }
        clearHistoryBets()
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
