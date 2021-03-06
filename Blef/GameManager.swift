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
    func didStartGame(_ message: Message)
    func didUpdateGame(_ game: Game)
    func didPlay()
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
    func didStartGame(_ message: Message) {
        print("GameManager started a game, but the result is not being used.")
        //this is a empty implementation to allow this method to be optional
    }
    func didUpdateGame(_ game: Game) {
        print("GameManager updated a Game, but the result is not being used.")
        //this is a empty implementation to allow this method to be optional
    }
    func didPlay() {
        print("GameManager did play, but the result is not being used.")
        //this is a empty implementation to allow this method to be optional
    }
    func failedIllegalPlay() {
        print("GameManager did play an illegal move, but the result is not being used.")
        //this is a empty implementation to allow this method to be optional
    }
}

class GameManager {
    let GameEngineServiceURL = "http://18.132.35.89:8001/v2/games"
    var newGame: NewGame?
    var game: Game?
    var player: Player?
    var delegate: GameManagerDelegate?
    
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
    
    func updateGame(gameUuid: UUID, playerUuid: UUID, round: Int = -1) {
        let urlString = "\(GameEngineServiceURL)/\(gameUuid.uuidString.lowercased())?player_uuid=\(playerUuid.uuidString.lowercased())&round=\(round)"
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
                    print("Got nonempty data")
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
        if let message = jsonObject.flatMap(Message.init){
            print("Made Message object")
            /**
             The `DispatchQueue` is necessary - otherwise Main Thread Checker will throw:
             `invalid use of AppKit, UIKit, and other APIs from a background thread`
             */
            DispatchQueue.main.async {
                print("Calling didStartGame")
                self.delegate?.didStartGame(message)
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
        if jsonObject?.count == 0 {
            print("Received empty JSON - play call was accepted")
            /**
             The `DispatchQueue` is necessary - otherwise Main Thread Checker will throw:
             `invalid use of AppKit, UIKit, and other APIs from a background thread`
             */
            DispatchQueue.main.async {
                print("Calling didPlay")
                self.delegate?.didPlay()
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
