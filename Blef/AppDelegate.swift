//
//  AppDelegate.swift
//  Blef
//
//  Created by Adrian Golian on 15.04.20.
//  Copyright © 2020 Blef Team.
//

import UIKit
import SpriteKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GameManagerDelegate {

    var gameManager = GameManager()
    var playerNickname: String?
    var gameUuid: UUID?
    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
    
    func application(_ application: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:] ) -> Bool {
        
        // Determine who sent the URL.
        let sendingAppID = options[.sourceApplication]
        print("source application = \(sendingAppID ?? "Unknown")")
        
        // Process the URL.
        print(url) // DEBUG
        print(NSURLComponents(url: url, resolvingAgainstBaseURL: true)) // DEBUG
        print(NSURLComponents(url: url, resolvingAgainstBaseURL: true)?.path?.replacingOccurrences(of: "/", with: ""))
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
            let gameUuid = UUID(uuidString: components.path?.replacingOccurrences(of: "/", with: "")  ?? "") else {
                print("Invalid URL")
                return false
        }
        
        self.gameManager.delegate = self
        playerNickname = generatePlayerNickname()
        self.gameUuid = gameUuid
        if let playerNickname = playerNickname {
            gameManager.joinGame(gameUuid: gameUuid, nickname: playerNickname)
        }
        return true
    }

    func didJoinGame(_ player: Player) {
        print(player)
        var player = player
        player.nickname = playerNickname
        let gameScene = GameScene(fileNamed: "GameScene")
        let transition = SKTransition.fade(withDuration: 1.0)
        gameScene?.scaleMode = .aspectFit
        gameScene?.gameUuid = gameUuid
        gameScene?.player = player
        (self.window?.rootViewController!.view as! SKView).presentScene(gameScene!, transition: transition)
    }
    
    func didFailWithError(error: Error) {
        print("didFailWithError")
        print(error.localizedDescription)
        if error.localizedDescription == "Nickname already taken" {
            if let gameUuid = gameUuid{
                let nickname = generatePlayerNickname()
                gameManager.joinGame(gameUuid: gameUuid, nickname: nickname)
                self.playerNickname = nickname
                return
            }
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

