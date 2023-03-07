//
//  AppDelegate.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 10.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import UIKit
import SwinjectStoryboard

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var coordinator: Coordinator?

    var container: RootComponent!
    var configuration: Configuration {
        return container.configuration
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        registerProviderFactories()
        container = RootComponent()
        window = UIWindow(frame: UIScreen.main.bounds)

        coordinator = Coordinator(window!, container)

        toggleMinimumBackgroundFetchInterval()

        NotificationCenter.default.addObserver(self, selector: #selector(toggleMinimumBackgroundFetchInterval), name: Notification.automaticUpdatesToggledNotification, object: nil)

        return true
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        container.store.refreshData() { refreshed in
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

