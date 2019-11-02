//
//  AppDelegate.swift
//  hls-downloader
//
//  Created by Jacky on 2019/11/01.
//  Copyright © 2019 illegal. All rights reserved.
//

import UIKit
import Tiercel

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var sessionManager: SessionManager = {
        SessionManager.logLevel = .none
        var configuration = SessionConfiguration()
        configuration.allowsCellularAccess = false
        let manager = SessionManager("hls-downloader", configuration: configuration, operationQueue: DispatchQueue(label: "com.hls-downloader.SessionManager.operationQueue"))
        return manager
    }()
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        let downloadManagers = [sessionManager]
        for manager in downloadManagers {
            if manager.identifier == identifier {
                manager.completionHandler = completionHandler
                break
            }
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

