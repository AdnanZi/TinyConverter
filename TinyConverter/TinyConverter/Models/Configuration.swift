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

    static let shared = StandardConfiguration()

    var updateOnStart: Bool {
        get {
            return defaults.bool(forKey: .updateOnStartKey)
        }
        set {
            defaults.set(newValue, forKey: .updateOnStartKey)
        }
    }

    var automaticUpdates: Bool {
        get {
            defaults.bool(forKey: .automaticUpdatesKey)
        }
        set {
            defaults.set(newValue, forKey: .automaticUpdatesKey)
        }
    }

    var updateInterval: Int {
        get {
            defaults.integer(forKey: .updateIntervalKey)
        }
        set {
            defaults.set(newValue, forKey: .updateIntervalKey)
        }
    }

    var updateIntervals: [Int] {
        return [2, 6, 24, 48]
    }

    func registerDefaults() {
        let initialDefaults: [ String: Any ] = [ .updateIntervalKey: updateIntervals[0], .updateOnStartKey: true, .automaticUpdatesKey: true ]

        defaults.register(defaults: initialDefaults)
    }
}

fileprivate extension String {
    static let updateIntervalKey = "updateInterval"
    static let updateOnStartKey = "updateOnStart"
    static let automaticUpdatesKey = "automaticUpdates"
}
