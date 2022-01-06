//
//  GameManager.swift
//  Blef
//
//  Created by Adrian Golian on 17.04.20.
//  Copyright © 2020 Blef Team.
//

import Foundation

struct RuntimeError: Error {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    public var localizedDescription: String {
        return message
    }
}

protocol GameManagerDelegate {
    func didCreateNewGame()
    func didJoinGame(_ player: Player)
    func didStartGame()
    func didInviteAI()
    func didUpdateGame(_ game: Game)
    func didResetWatchGameWebsocket()
    func didPlay(_ game: Game)
    func failedIllegalPlay()
    func didFailWithError(error: Error)
    func didGetPublicGames()
}

extension GameManagerDelegate {
    func didCreateNewGame() {
        print("GameManager created a NewGame, but the result is not being used.")
        //this is a empty implementation to allow this method to be optional
    }
    func didJoinGame(_ player: Player) {
        print("GameManager let a player join a game, but the result is not being used.")
        //this is a empty implementation to allow this method to be optional
    }
    func didStartGame() {
        print("GameManager started a game, but the result is not being used.")
        //this is a empty implementation to allow this method to be optional
    }
    func didInviteAI() {
        print("GameManager invited an AI agent, but the result is not being used.")
        //this is a empty implementation to allow this method to be optional
    }
    func didUpdateGame(_ game: Game) {
        print("GameManager updated a Game, but the result is not being used.")
        //this is a empty implementation to allow this method to be optional
    }
    func didResetWatchGameWebsocket() {
        print("GameManager reset the watch game websocket, but the result is not being used.")
        //this is a empty implementation to allow this method to be optional
    }
    func didPlay(_ game: Game) {
        print("GameManager did play, but the result is not being used.")
        //this is a empty implementation to allow this method to be optional
    }
    func failedIllegalPlay() {
        print("GameManager did play an illegal move, but the result is not being used.")
        //this is a empty implementation to allow this method to be optional
    }
    func didGetPublicGames() {
        print("GameManager did get public games, but the result is not being used.")
        //this is a empty implementation to allow this method to be optional
    }
}

func defaultParser(_: JSON?) -> Bool {
    return false
}

func defaultArrayParser(_: JSONArray?) -> Bool {
    return false
}

class GameManager: NSObject, URLSessionWebSocketDelegate {
    let GameEngineServiceURL = "https://n4p6oovxsg.execute-api.eu-west-2.amazonaws.com/games"
    let watchGameWebsocketEnvironment = "production"
    var publicGames: [UUID: PublicGame] = [:]
    var newGame: NewGame?
    var game: Game?
    var gameUuid: UUID?
    var player: Player?
    var delegate: GameManagerDelegate?
    
    var watchGameWebsocket: URLSessionWebSocketTask?
    
    func resetWatchGameWebsocket() {
        let websocketString = "wss://mx2uhu5jme.execute-api.eu-west-2.amazonaws.com/\(watchGameWebsocketEnvironment)"
        print(websocketString)
        print("gameUuid: \(gameUuid)")
        print("playerUuid: \(player?.uuid)")
        let session = URLSession(configuration: .default,
                                 delegate: self,
                                 delegateQueue: OperationQueue()
        )
        let url = URL(string: websocketString)
        var request = URLRequest(url: url!)
        if let gameUuid = gameUuid {
            request.addValue(gameUuid.uuidString.lowercased(), forHTTPHeaderField: "game_uuid")
        }
        if let playerUuid = player?.uuid {
            request.addValue(playerUuid.uuidString.lowercased(), forHTTPHeaderField: "player_uuid")
        }
        print("request (URLRequest): \(request)")
        self.watchGameWebsocket = session.webSocketTask(with: request)
        self.watchGameWebsocket?.resume()
    }
    
    func pingWatchGameWebsocket() {
        // Ping the watchGameWebsocket to keet it alive
        watchGameWebsocket?.sendPing { error in
            if error != nil {
                self.resetWatchGameWebsocket()
            }
            else {
                DispatchQueue.global().asyncAfter(deadline: .now() + 20) {
                    self.pingWatchGameWebsocket()
                }
            }
        }
    }
    
    func receiveWatchGameWebsocket() {
        // Check if there's anything in watchGameWebsocket
        watchGameWebsocket?.receive(completionHandler: {[weak self] result in
            print("Called receiveWatchGameWebsocket")
            switch result {
            case .success(let message):
                print("SUCCESS in receiveWatchGameWebsocket")
                switch message {
                case .data(let data):
                    print("Got data from the websocket \(data)")
                case .string(let string):
                    print("Got string from the websocket: \(string)")
                    let fullJsonObject = (try? JSONSerialization.jsonObject(with: string.data(using: .utf8)!, options: [])) as? JSON
                    print("fullJsonObject: \(String(describing: fullJsonObject))")
                    let bodyString = fullJsonObject?["body"] as! String
                    let jsonBody = (try? JSONSerialization.jsonObject(with: bodyString.data(using: .utf8)!, options: [])) as? JSON
                    if let succeeded = self?.parseUpdateGameResponse(jsonBody) ?? self?.parseNewGameResponse(jsonBody) {
                        /**
                         The `DispatchQueue` is necessary - otherwise Main Thread Checker will throw:
                         `invalid use of AppKit, UIKit, and other APIs from a background thread`
                         */
                        if !succeeded {
                            if let errorResponse = jsonBody.flatMap(ErrorResponse.init){
                                print("Made errorResponse object")
                                DispatchQueue.main.async {
                                    print("Calling didFailWithError")
                                    self?.delegate?.didFailWithError(error: RuntimeError(errorResponse.error))
                                }
                            }
                            if let message = jsonBody.flatMap(Message.init){
                                print("Made Message object")
                                DispatchQueue.main.async {
                                    print("Calling didFailWithError")
                                    self?.delegate?.didFailWithError(error: RuntimeError(message.message))
                                }
                            }
                            else {
                                print("Failed to parse json")
                                DispatchQueue.main.async {
                                    print("Calling didFailWithError")
                                    self?.delegate?.didFailWithError(error: RuntimeError("Failed to parse json response."))
                                }
                            }
                        }
                    }
                @unknown default:
                    break
                }
            case .failure(let error):
                print("Received an error from the websocket \(error)")
                DispatchQueue.main.async {
                    print("Calling didFailWithError")
                    self?.delegate?.didFailWithError(error: error)
                }
                self?.closeWatchGameWebsocket()
                self?.resetWatchGameWebsocket()
            }
        } )
    }
    
    func closeWatchGameWebsocket() {
        watchGameWebsocket?.cancel(with: .goingAway, reason: "Stopped watching the game".data(using: .utf8))
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        // On watchGameWebsocket connect
        print("Web Socket did connect")
        pingWatchGameWebsocket()
        self.delegate?.didResetWatchGameWebsocket()
        receiveWatchGameWebsocket()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        // On watchGameWebsocket disconnect
        print("Web Socket did disconnect")
        if closeCode == URLSessionWebSocketTask.CloseCode(rawValue: 1002) || closeCode == URLSessionWebSocketTask.CloseCode(rawValue: 1003) {
            resetWatchGameWebsocket()
        }
    }
    
    func getPublicGames() {
        let urlString = "\(GameEngineServiceURL)"
        print(urlString)
        performRequest(with: urlString, arrayParser: parseGetPublicGamesResponse(_:))
    }
    
    func setGameUuid(_ gameUuid: UUID) {
        self.gameUuid = gameUuid
    }
    
    func createGame() {
        let urlString = "\(GameEngineServiceURL)/create"
        print(urlString)
        performRequest(with: urlString, parser: parseNewGameResponse(_:))
    }
    
    func joinGame(nickname: String) {
        if let gameUuidString = gameUuid?.uuidString.lowercased() {
            let urlString = "\(GameEngineServiceURL)/\(gameUuidString)/join?nickname=\(formatSerialisedNickname(nickname))"
            print(urlString)
            self.player = Player(uuid: UUID(), nickname: nickname)
            performRequest(with: urlString, parser: parseJoinGameResponse(_:))
        } else {
            print("Game UUID missing in joinGame!")
        }
    }
    
    func startGame() {
        if let gameUuidString = gameUuid?.uuidString.lowercased(), let playerUuidString = player?.uuid.uuidString.lowercased() {
            let urlString = "\(GameEngineServiceURL)/\(gameUuidString)/start?admin_uuid=\(playerUuidString)"
            print(urlString)
            performRequest(with: urlString, parser: parseStartGameResponse(_:))
        } else {
            print("Game UUID missing in startGame!")
        }
    }
    
    func inviteAI(_ agentName: String = "Dazhbog") {
        if let gameUuidString = gameUuid?.uuidString.lowercased(), let playerUuidString = player?.uuid.uuidString.lowercased() {
            let urlString = "\(GameEngineServiceURL)/\(gameUuidString)/invite-aiagent?admin_uuid=\(playerUuidString)&agent_name=\(agentName)"
            print(urlString)
            performRequest(with: urlString, parser: parseInviteAIResponse(_:))
        } else {
            print("Game UUID missing in updateGame!")
        }
    }
    
    func updateGame(round: Int?) {
        var roundString = ""
        if let r = round {
            roundString = String(r)
        }
        if let gameUuidString = gameUuid?.uuidString.lowercased(), let playerUuidString = player?.uuid.uuidString.lowercased() {
            let urlString = "\(GameEngineServiceURL)/\(gameUuidString)?player_uuid=\(playerUuidString)&round=\(roundString)"
            print(urlString)
            performRequest(with: urlString, parser: parseUpdateGameResponse(_:))
        } else {
            print("Game UUID missing in updateGame!")
        }
    }
    
    func play(action: Action) {
        if let gameUuidString = gameUuid?.uuidString.lowercased(), let playerUuidString = player?.uuid.uuidString.lowercased() {
            let urlString = "\(GameEngineServiceURL)/\(gameUuidString)/play?player_uuid=\(playerUuidString)&action_id=\(action.rawValue)"
            print(urlString)
            performRequest(with: urlString, parser: parsePlayResponse(_:))
        } else {
            print("Game UUID missing in play!")
        }
    }
    
    func updatePublicGame(_  game: PublicGame) {
        guard let existingGame = self.publicGames[game.uuid] else {
            self.publicGames[game.uuid] = game
            return
        }
        if game.lastModified <= existingGame.lastModified {
            self.publicGames[game.uuid] = game
        }
        if let isPublic = game.isPublic {
            if !isPublic {
                self.publicGames.removeValue(forKey: game.uuid)
            }
        }
    }
    
    func updatePublicGames(_ games: [PublicGame]) {
        // Update received public games
        for game in games {
            updatePublicGame(game)
        }
        // Given that the received array is complete,
        // we can remove any games not public anymore
        let publicGameUuids = games.map { $0.uuid }
        for (uuid, game) in self.publicGames {
            if !publicGameUuids.contains(uuid) {
                self.publicGames.removeValue(forKey: uuid)
            }
        }
    }
    
    func performRequest(with urlString: String, parser parseResponse: @escaping (JSON?) -> Bool = defaultParser, arrayParser parseArrayResponse: @escaping (JSONArray?) -> Bool = defaultArrayParser) {
        if let url = URL(string: urlString) {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url) {(data, response, error) in
                if error != nil {
                    print(error!)
                    self.delegate?.didFailWithError(error: error!)
                }
                print("Got data")
                if let safeData = data {
                    print("Got nonempty data:")
                    print(data?.base64EncodedString())
                    var succeeded = false
                    var jsonObject: JSON? = nil
                    var jsonArray: JSONArray? = nil
                    jsonObject = (try? JSONSerialization.jsonObject(with: safeData, options: [])) as? JSON
                    succeeded = parseResponse(jsonObject)
                    if !succeeded {
                        jsonArray = (try? JSONSerialization.jsonObject(with: safeData, options: [])) as? JSONArray
                        succeeded = parseArrayResponse(jsonArray)
                    }
                    if !succeeded {
                        /**
                         The `DispatchQueue` is necessary - otherwise Main Thread Checker will throw:
                         `invalid use of AppKit, UIKit, and other APIs from a background thread`
                         */
                        if let errorResponse = jsonObject.flatMap(ErrorResponse.init){
                            print("Made errorResponse object")
                            DispatchQueue.main.async {
                                print("Calling didFailWithError")
                                self.delegate?.didFailWithError(error: RuntimeError(errorResponse.error))
                            }
                        }
                        if let message = jsonObject.flatMap(Message.init){
                            print("Made Message object")
                            DispatchQueue.main.async {
                                print("Calling didFailWithError")
                                self.delegate?.didFailWithError(error: RuntimeError(message.message))
                            }
                        }
                        else {
                            print("Failed to parse json")
                            DispatchQueue.main.async {
                                print("Calling didFailWithError")
                                self.delegate?.didFailWithError(error: RuntimeError("Failed to parse json response."))
                            }
                        }
                    }
                }
            }
            task.resume()
        }
    }
    
    func parseGetPublicGamesResponse(_ jsonArray: JSONArray?) -> Bool {
        if let array = jsonArray {
            for jsonObject in array {
                print(jsonObject)
            }
            let games = array.compactMap(PublicGame.init)
            updatePublicGames(games)
            /**
             The `DispatchQueue` is necessary - otherwise Main Thread Checker will throw:
             `invalid use of AppKit, UIKit, and other APIs from a background thread`
             */
            DispatchQueue.main.async {
                print("Calling didGetPublicGames")
                self.delegate?.didGetPublicGames()
            }
            return true
        }
        return false
    }
    
    func parseNewGameResponse(_ jsonObject: JSON?) -> Bool {
        if let newGame = jsonObject.flatMap(NewGame.init){
            print("Made newGame object")
            self.newGame = newGame
            self.setGameUuid(newGame.uuid)
            /**
             The `DispatchQueue` is necessary - otherwise Main Thread Checker will throw:
             `invalid use of AppKit, UIKit, and other APIs from a background thread`
             */
            DispatchQueue.main.async {
                print("Calling didCreateNewGame")
                self.delegate?.didCreateNewGame()
            }
            return true
        }
        return false
    }

    func parseJoinGameResponse(_ jsonObject: JSON?) -> Bool {
        if let player = jsonObject.flatMap(Player.init){
            print("Made Player object")
            if self.player != nil {
                self.player?.uuid = player.uuid
            } else {
                self.player = player
            }
            /**
             The `DispatchQueue` is necessary - otherwise Main Thread Checker will throw:
             `invalid use of AppKit, UIKit, and other APIs from a background thread`
             */
            DispatchQueue.main.async {
                print("Calling didJoinGame")
                self.delegate?.didJoinGame(player)
            }
            return true
        }
        return false
    }
    
    func parseStartGameResponse(_ jsonObject: JSON?) -> Bool {
        if let messageObject = jsonObject.flatMap(Message.init){
            if messageObject.message != "Game started" {
                return false
            }
            print(messageObject)
            /**
             The `DispatchQueue` is necessary - otherwise Main Thread Checker will throw:
             `invalid use of AppKit, UIKit, and other APIs from a background thread`
             */
            DispatchQueue.main.async {
                print("Calling didStartGame")
                self.delegate?.didStartGame()
            }
            return true
        }
        return false
    }
    
    func parseInviteAIResponse(_ jsonObject: JSON?) -> Bool {
        if let messageObject = jsonObject.flatMap(Message.init){
            if !messageObject.message.contains("(AI) joined the game") {
                return false
            }
            print(messageObject)
            /**
             The `DispatchQueue` is necessary - otherwise Main Thread Checker will throw:
             `invalid use of AppKit, UIKit, and other APIs from a background thread`
             */
            DispatchQueue.main.async {
                print("Calling didInviteAI")
                self.delegate?.didInviteAI()
            }
            return true
        }
        return false
    }
    
    func parseUpdateGameResponse(_ jsonObject: JSON?) -> Bool {
        if let game = jsonObject.flatMap(Game.init){
            print("Made Game object")
            self.game = game
            /**
             The `DispatchQueue` is necessary - otherwise Main Thread Checker will throw:
             `invalid use of AppKit, UIKit, and other APIs from a background thread`
             */
            DispatchQueue.main.async {
                print("Calling didUpdateGame")
                self.delegate?.didUpdateGame(game)
            }
            return true
        }
        return false
    }
    
    func parsePlayResponse(_ jsonObject: JSON?) -> Bool {
        if let game = jsonObject.flatMap(Game.init){
            print("Received game state - play call was accepted")
            self.game = game
            /**
             The `DispatchQueue` is necessary - otherwise Main Thread Checker will throw:
             `invalid use of AppKit, UIKit, and other APIs from a background thread`
             */
            DispatchQueue.main.async {
                print("Calling didPlay")
                self.delegate?.didPlay(game)
            }
            return true
        }
        else if let errorResponse = jsonObject.flatMap(ErrorResponse.init) {
            if errorResponse.error == "This action not allowed right now" {
                DispatchQueue.main.async {
                    print("Calling failedIllegalPlay")
                    self.delegate?.failedIllegalPlay()
                }
                return true
            }
        }
        return false
    }
    
}
