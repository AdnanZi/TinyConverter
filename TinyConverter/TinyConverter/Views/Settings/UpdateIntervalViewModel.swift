//
//  UpdateIntervalViewModel.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 14.02.20.
//  Copyright © 2020 Adnan Zildzic. All rights reserved.
//
import UIKit

class UpdateIntervalViewModel {
    private var configuration: Configuration

    var updateIntervals: [Int] {
        return configuration.updateIntervals
    }

    var selectedInterval: Int {
        return configuration.updateInterval
    }

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    func setUpdateInterval(_ updateInterval: Int) {
        if !configuration.updateIntervals.contains(updateInterval) {
            return
        }

        configuration.updateInterval = updateInterval
    }
}
