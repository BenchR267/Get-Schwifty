//
//  AppDelegate.swift
//  WWDC
//
//  Created by Benjamin Herzog on 29.03.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let window = UIWindow()
        let ctrl = ViewController()
        let nav = UINavigationController(rootViewController: ctrl)
        window.rootViewController = nav
        window.makeKeyAndVisible()
        
        self.window = window
        
        return true
    }
}

