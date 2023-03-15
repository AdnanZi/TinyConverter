//
//  AppDelegate.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 10.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import UIKit
import Combine
import BackgroundTasks

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var cancellable = Set<AnyCancellable>()

    var window: UIWindow?
    var coordinator: Coordinator?

    var container: RootComponent!
    var configuration: Configuration {
        return container.configuration
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if ProcessInfo.processInfo.runningTests { // Skip loading view controllers when running unit tests
            return true
        }

        registerProviderFactories()
        container = RootComponent()
        window = UIWindow(frame: UIScreen.main.bounds)

        coordinator = Coordinator(window!, container)

        BGTaskScheduler.shared.register(forTaskWithIdentifier: .refreshTaskId, using: nil) { task in
            self.performFetch(task: task as! BGAppRefreshTask)
        }

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleAppRefresh()
    }

    private func performFetch(task: BGAppRefreshTask) {
        scheduleAppRefresh()

        let operationTask = Task {
            self.container.store.refreshData()
                .receive(on: RunLoop.main)
                .sink {
                    task.setTaskCompleted(success: $0)
                }
                .store(in: &cancellable)
        }

        task.expirationHandler = {
            operationTask.cancel()
        }
    }

    private func scheduleAppRefresh() {
        let updateInterval = container.configuration.automaticUpdates ? TimeInterval(container.configuration.updateInterval) : TimeInterval.infinity

        let request = BGAppRefreshTaskRequest(identifier: .refreshTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: updateInterval)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Scheduling failed.")
        }
    }
}

fileprivate extension String {
    static let refreshTaskId = "com.company.adnan.TinyConverter.refresh"
}

