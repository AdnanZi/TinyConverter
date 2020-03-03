//
//  Configuration.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 14.02.20.
//  Copyright © 2020 Adnan Zildzic. All rights reserved.
//
import UIKit

protocol Configuration {
    var updateOnStart: Bool { get set }
    var automaticUpdates: Bool { get set }
    var updateInterval: Int { get set }
    var updateIntervals: [Int] { get }

    func registerDefaults()
}

class StandardConfiguration: Configuration {
    private let defaults = UserDefaults.standard

    var updateOnStart: Bool {
        get {
            return defaults.bool(forKey: .updateOnStartKey)
        }
        set {
            if newValue == updateOnStart { return }
            defaults.set(newValue, forKey: .updateOnStartKey)
        }
    }

    var automaticUpdates: Bool {
        get {
            defaults.bool(forKey: .automaticUpdatesKey)
        }
        set {
            if newValue == automaticUpdates { return }

            defaults.set(newValue, forKey: .automaticUpdatesKey)
            triggerAutomaticUpdateToggledNotification()
        }
    }

    var updateInterval: Int {
        get {
            defaults.integer(forKey: .updateIntervalKey)
        }
        set {
            defaults.set(newValue, forKey: .updateIntervalKey)
            triggerAutomaticUpdateToggledNotification()
        }
    }

    var updateIntervals: [Int] {
        return [2, 6, 24, 48]
    }

    func registerDefaults() {
        let initialDefaults: [ String: Any ] = [ .updateIntervalKey: updateIntervals[0], .updateOnStartKey: true, .automaticUpdatesKey: true ]

        defaults.register(defaults: initialDefaults)
    }

    private func triggerAutomaticUpdateToggledNotification() {
        NotificationCenter.default.post(name: Notification.automaticUpdatesToggledNotification, object: nil)
    }
}

fileprivate extension String {
    static let updateIntervalKey = "updateInterval"
    static let updateOnStartKey = "updateOnStart"
    static let automaticUpdatesKey = "automaticUpdates"
}

extension Notification {
    static var automaticUpdatesToggledNotification: Name { return Name("AutomaticUpdatesToggled") }
}
