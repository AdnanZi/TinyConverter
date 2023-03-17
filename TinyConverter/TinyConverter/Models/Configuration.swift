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
}

class StandardConfiguration: Configuration {
    @Config(key: .updateOnStartKey, defaultValue: true)
    var updateOnStart: Bool

    @Config(key: .automaticUpdatesKey, defaultValue: true)
    var automaticUpdates: Bool {
        didSet {
            triggerAutomaticUpdateToggledNotification()
        }
    }

    @Config(key: .updateIntervalKey, defaultValue: updateIntervals[0])
    var updateInterval: Int {
        didSet {
            triggerAutomaticUpdateToggledNotification()
        }
    }

    var updateIntervals: [Int] {
        Self.updateIntervals
    }

    private static let updateIntervals = [2, 6, 24, 48]

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

@propertyWrapper struct Config<T> {
    private let defaults = UserDefaults.standard
    private let key: String
    private var defaultValue: T

    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            defaults.object(forKey: key) as? T ?? defaultValue
        }
        set {
            defaults.setValue(newValue, forKey: key)
        }
    }
}
