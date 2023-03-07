//
//  AppDelegate.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 10.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import UIKit
import BackgroundTasks

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var coordinator: Coordinator?

    var container: RootComponent!
    var configuration: Configuration {
        return container.configuration
    }

    let queue = OperationQueue()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
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

        queue.maxConcurrentOperationCount = 1

        let operation = RefreshDataOperation(store: container.store)

        task.expirationHandler = {
            operation.cancel()
        }

        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled || operation.result)
        }

        queue.addOperation(operation)
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

private class RefreshDataOperation: Operation {
    let store: Store
    var result = false

    init(store: Store) {
        self.store = store
    }

    override func main() {
        if isCancelled { return }

        store.refreshData { [weak self] in
            guard let self, !self.isCancelled else { return }

            self.result = $0
            self.completionBlock?()
        }
    }
}

fileprivate extension String {
    static let refreshTaskId = "com.company.adnan.TinyConverter.refresh"
}

