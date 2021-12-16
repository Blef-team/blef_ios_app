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
    func didCreateNewGame(_ newGame: NewGame)
    func didJoinGame(_ player: Player)
    func didStartGame()
    func didUpdateGame(_ game: Game)
    func didPlay(_ game: Game)
    func failedIllegalPlay()
    func didFailWithError(error: Error)
}

extension GameManagerDelegate {
    func didCreateNewGame(_ newGame: NewGame) {
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
    func didUpdateGame(_ game: Game) {
        print("GameManager updated a Game, but the result is not being used.")
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
}

class GameManager: NSObject, URLSessionWebSocketDelegate {
    let GameEngineServiceURL = "https://n4p6oovxsg.execute-api.eu-west-2.amazonaws.com/games"
    let watchGameWebsocketEnvironment = "production"
    var newGame: NewGame?
    var game: Game?
    var player: Player?
    var delegate: GameManagerDelegate?
    
    var watchGameWebsocket: URLSessionWebSocketTask?
    
    func resetWatchGameWebsocket(gameUuid: UUID? = nil, playerUuid: UUID? = nil) {
        let websocketString = "wss://mx2uhu5jme.execute-api.eu-west-2.amazonaws.com/\(watchGameWebsocketEnvironment)"
        print(websocketString)
        print("gameUuid: \(gameUuid)")
        print("playerUuid: \(playerUuid)")
        let session = URLSession(configuration: .default,
                                 delegate: self,
                                 delegateQueue: OperationQueue()
        )
        let url = URL(string: websocketString)
        var request = URLRequest(url: url!)
        if let gameUuid = gameUuid {
            request.addValue(gameUuid.uuidString.lowercased(), forHTTPHeaderField: "game_uuid")
        }
        if let playerUuid = playerUuid {
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
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
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
                    print("jsonBody: \(String(describing: jsonBody))")
                    if let succeeded = self?.parseUpdateGameResponse(jsonBody) ?? self?.parseNewGameResponse(jsonBody) {
                        print("succeeded: \(succeeded)")
                        if !succeeded {
                            if let errorResponse = jsonBody.flatMap(ErrorResponse.init){
                                print("Made errorResponse object")
                                self?.delegate?.didFailWithError(error: RuntimeError(errorResponse.error))
                            }
                            if let message = jsonBody.flatMap(Message.init){
                                print("Made Message object")
                                self?.delegate?.didFailWithError(error: RuntimeError(message.message))
                            }
                            else {
                                print("Failed to parse json")
                                self?.delegate?.didFailWithError(error: RuntimeError("Failed to parse json response."))
                            }
                        }
                    }
                @unknown default:
                    break
                }
            case .failure(let error):
                print("Received an error from the websocket \(error)")
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
        receiveWatchGameWebsocket()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        // On watchGameWebsocket disconnect
        print("Web Socket did disconnect")
        if closeCode == URLSessionWebSocketTask.CloseCode(rawValue: 1002) || closeCode == URLSessionWebSocketTask.CloseCode(rawValue: 1003) {
            resetWatchGameWebsocket()
        }
    }
    
    func createGame() {
        let urlString = "\(GameEngineServiceURL)/create"
        print(urlString)
        performRequest(with: urlString, parser: parseNewGameResponse(_:))
    }
    
    func joinGame(gameUuid: UUID, nickname: String) {
        let urlString = "\(GameEngineServiceURL)/\(gameUuid.uuidString.lowercased())/join?nickname=\(formatSerialisedNickname(nickname))"
        print(urlString)
        performRequest(with: urlString, parser: parseJoinGameResponse(_:))
    }
    
    func startGame(gameUuid: UUID, playerUuid: UUID) {
        let urlString = "\(GameEngineServiceURL)/\(gameUuid.uuidString.lowercased())/start?admin_uuid=\(playerUuid.uuidString.lowercased())"
        print(urlString)
        performRequest(with: urlString, parser: parseStartGameResponse(_:))
    }
    
    func updateGame(gameUuid: UUID, playerUuid: UUID, round: Int?) {
        var roundString = ""
        if let r = round {
            roundString = String(r)
        }
        let urlString = "\(GameEngineServiceURL)/\(gameUuid.uuidString.lowercased())?player_uuid=\(playerUuid.uuidString.lowercased())&round=\(roundString)"
        print(urlString)
        performRequest(with: urlString, parser: parseUpdateGameResponse(_:))
    }
    
    func play(gameUuid: UUID, playerUuid: UUID, action: Action) {
        let urlString = "\(GameEngineServiceURL)/\(gameUuid.uuidString.lowercased())/play?player_uuid=\(playerUuid.uuidString.lowercased())&action_id=\(action.rawValue)"
        print(urlString)
        performRequest(with: urlString, parser: parsePlayResponse(_:))
    }
    
    func performRequest(with urlString: String, parser parseResponse: @escaping (JSON?) -> Bool) {
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
                    let jsonObject = (try? JSONSerialization.jsonObject(with: safeData, options: [])) as? JSON
                    print(jsonObject as Any)
                    let succeeded = parseResponse(jsonObject)
                    if !succeeded {
                        if let errorResponse = jsonObject.flatMap(ErrorResponse.init){
                            print("Made errorResponse object")
                            self.delegate?.didFailWithError(error: RuntimeError(errorResponse.error))
                        }
                        if let message = jsonObject.flatMap(Message.init){
                            print("Made Message object")
                            self.delegate?.didFailWithError(error: RuntimeError(message.message))
                        }
                        else {
                            print("Failed to parse json")
                            self.delegate?.didFailWithError(error: RuntimeError("Failed to parse json response."))
                        }
                    }
                }
            }
            task.resume()
        }
    }
    
    func parseNewGameResponse(_ jsonObject: JSON?) -> Bool {
        if let newGame = jsonObject.flatMap(NewGame.init){
            print("Made newGame object")
            self.newGame = newGame
            /**
             The `DispatchQueue` is necessary - otherwise Main Thread Checker will throw:
             `invalid use of AppKit, UIKit, and other APIs from a background thread`
             */
            DispatchQueue.main.async {
                print("Calling didCreateNewGame")
                self.delegate?.didCreateNewGame(newGame)
            }
            return true
        }
        return false
    }

    func parseJoinGameResponse(_ jsonObject: JSON?) -> Bool {
        if let player = jsonObject.flatMap(Player.init){
            print("Made Player object")
            self.player = player
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
