//
//  AppDelegate.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 10.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var coordinator: Coordinator? = nil

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        coordinator = Coordinator(window!.rootViewController as! UINavigationController)

        UIApplication.shared.setMinimumBackgroundFetchInterval(7200)

        return true
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        ConverterStore.shared.refreshData() { refreshed in
            completionHandler(refreshed ? .newData : .noData)
        }
    }
}

