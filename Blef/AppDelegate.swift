//
//  AppDelegate.swift
//  Blef
//
//  Created by Adrian Golian on 15.04.20.
//  Copyright © 2020 Blef Team.
//

import UIKit
import SpriteKit
import AVFAudio

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GameManagerDelegate {

    var gameManager = GameManager()
    var playerNickname: String?
    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback)
            try audioSession.setActive(true)
        } catch {}
        return true
    }
    
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // Get URL components from the incoming user activity.
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let incomingURL = userActivity.webpageURL,
            let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true) else {
            return false
        }

        guard let path = components.path,
        let params = components.queryItems else {
            return false
        }
        print("path = \(path)")

        guard let gameUuidString = params.first(where: { $0.name == "game_uuid" } )?.value, let gameUuid = UUID(uuidString: gameUuidString) else {
            print("No valid game uuid in the URL parameters")
            return false
        }
        prepareGame(gameUuid)
        return true
    }
    
    func application(_ application: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:] ) -> Bool {
        
        // Determine who sent the URL.
        let sendingAppID = options[.sourceApplication]
        print("source application = \(sendingAppID ?? "Unknown")")
        
        // Process the URL.
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true), let gameUuidString = components.path?.replacingOccurrences(of: "/", with: ""), let gameUuid = UUID(uuidString: gameUuidString) else {
                print("Invalid URL")
                return false
        }
        
        prepareGame(gameUuid)
        return true
    }
    
    func prepareGame(_ gameUuid: UUID) {
        // Check if the new game uuid is not the same as current scene (avoid joining your own game)
        if let currentScene = (self.window?.rootViewController!.view as! SKView).scene as? GameScene {
            if let currentUuid = currentScene.gameManager?.gameUuid {
                if currentUuid == gameUuid {
                    return
                }
            }
        }
        
        if let savedGamePlayer =  getSavedGamePlayer(with: gameUuid) {
            gameManager.gameUuid = gameUuid
            gameManager.player = savedGamePlayer
            moveToGameScene(savedGamePlayer)
            return
        }
        
        self.gameManager.delegate = self
        playerNickname = generatePlayerNickname()
        if let playerNickname = playerNickname {
            gameManager.gameUuid = gameUuid
            gameManager.joinGame(nickname: playerNickname)
        }
    }
    
    func getSavedGamePlayer(with gameUuid: UUID) -> Player? {
        let savedGames = getSavedGames()
        if savedGames.count < 1 {
            return nil
        }
        guard let savedGame = savedGames[gameUuid.uuidString] else {
            return nil
        }
        return Player(uuid: savedGame.playerUuid, nickname: savedGame.playerNickname)
    }

    func didJoinGame(_ player: Player) {
        print(player)
        var player = player
        player.nickname = playerNickname
        moveToGameScene(player)
    }
    
    func didFailWithError(error: Error) {
        print("didFailWithError")
        print(error.localizedDescription)
        if error.localizedDescription == "Nickname already taken" {
            let nickname = generatePlayerNickname()
            gameManager.joinGame(nickname: nickname)
            self.playerNickname = nickname
            return
        }
        let startScene = StartScene(fileNamed: "StartScene")
        let transition = SKTransition.fade(withDuration: 1.0)
        startScene?.scaleMode = .aspectFill
        if let errorMessageLabel = startScene?.errorMessageLabel {
            startScene?.errorMessageLabel.removeFromParent()
            startScene?.errorMessageLabel.text = "Something went wrong. Try again."
            startScene?.addChild(errorMessageLabel)
            (self.window?.rootViewController!.view as! SKView).presentScene(startScene!, transition: transition)
        }
    }
    
    func moveToGameScene(_ player: Player) {
        guard let gameScene = GameScene(fileNamed: "GameScene") else {
            return
        }
        let transition = SKTransition.fade(withDuration: 1.0)
        gameScene.scaleMode = .aspectFit
        gameScene.player = player
        gameScene.gameManager = gameManager
        (self.window?.rootViewController!.view as! SKView).presentScene(gameScene, transition: transition)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }


}

