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
    let configuration = StandardConfiguration.shared

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        coordinator = Coordinator(window!.rootViewController as! UINavigationController)

        configuration.registerDefaults()

        toggleMinimumBackgroundFetchInterval()

        NotificationCenter.default.addObserver(self, selector: #selector(toggleMinimumBackgroundFetchInterval), name: Notification.automaticUpdatesToggledNotification, object: nil)

        return true
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        ConverterStore.shared.refreshData() { refreshed in
            completionHandler(refreshed ? .newData : .noData)
        }
    }

    @objc func toggleMinimumBackgroundFetchInterval() {
        if configuration.automaticUpdates {
            let updateInterval = TimeInterval(configuration.updateInterval * 3600)
            UIApplication.shared.setMinimumBackgroundFetchInterval(updateInterval)
        } else {
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalNever)
        }
    }
}

