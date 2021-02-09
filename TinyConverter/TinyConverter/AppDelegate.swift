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

    let container = SwinjectStoryboard.container
    var configuration: Configuration {
        return container.resolve(Configuration.self)!
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        coordinator = Coordinator(window!)

        toggleMinimumBackgroundFetchInterval()

        NotificationCenter.default.addObserver(self, selector: #selector(toggleMinimumBackgroundFetchInterval), name: Notification.automaticUpdatesToggledNotification, object: nil)

        return true
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard let store = container.resolve(Store.self) else {
            completionHandler(.noData)
            return
        }

        store.refreshData()
            .receive(on: RunLoop.main)
            .sink {
                completionHandler($0 ? .newData : .noData)
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

