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

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        let window = UIWindow()
        window.rootViewController = PageViewController()
        window.makeKeyAndVisible()

        self.window = window

        self.appearance()

        return true
    }

    private func appearance() {
        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().barStyle = .blackOpaque
        UINavigationBar.appearance().barTintColor = UIColor(r: 237, g: 82, b: 63, a: 1)

        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(r: 237, g: 82, b: 63, a: 1)
        UIPageControl.appearance().backgroundColor = .clear
    }
}
