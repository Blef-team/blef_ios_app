//
//  GameManager.swift
//  Blef
//
//  Created by Adrian Golian on 17.04.20.
//  Copyright © 2020 Blef Team.
//

import Foundation
import Keys

let keys = BlefKeys()

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
    func didFailWithError(error: Error)
}

class GameManager {
    let GameEngineServiceURL = keys.gameEngineServiceBaseURL + "/games"
    var newGame: NewGame?
    var delegate: GameManagerDelegate?
    
    func createGame(nickname: String) {
        let urlString = "\(GameEngineServiceURL)/create?nickname=\(nickname)"
        print(urlString)
        performRequest(with: urlString, parser: parseNewGameResponse)
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
                    print(jsonObject)
                    if let errorMessage = jsonObject?["error"] as? String {
                        self.delegate?.didFailWithError(error: RuntimeError(errorMessage))
                    }
                    let succeeded = parseResponse(jsonObject)
                    if !succeeded {
                        if let errorResponse = jsonObject.flatMap(ErrorResponse.init){
                            print("Made errorResponse object")
                            self.delegate?.didFailWithError(error: RuntimeError(errorResponse.message))
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

}
