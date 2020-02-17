//
//  SettingsViewModel.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 14.02.20.
//  Copyright © 2020 Adnan Zildzic. All rights reserved.
//
import Foundation

class SettingsViewModel: NSObject {
    @objc dynamic var updateOnStart: Bool = false {
        didSet {
            configuration.updateOnStart = updateOnStart
        }
    }

    @objc dynamic var automaticUpdates: Bool = false {
        didSet {
            configuration.automaticUpdates = automaticUpdates
        }
    }

    @objc dynamic var updateInterval: String? = ""

    private var configuration: Configuration

    init(configuration: Configuration? = nil) {
        self.configuration = configuration ?? StandardConfiguration.shared

        super.init()

        fetchValues()
    }

    func fetchValues() {
        updateOnStart = configuration.updateOnStart
        automaticUpdates = configuration.automaticUpdates
        updateInterval = String(configuration.updateInterval)
    }

    func refreshUpdateInterval() {
        updateInterval = String(configuration.updateInterval)
    }
}
