//
//  SettingsViewModel.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 14.02.20.
//  Copyright © 2020 Adnan Zildzic. All rights reserved.
//
import Foundation
import Combine

class SettingsViewModel {
    private var cancellable = Set<AnyCancellable>()

    @Published var updateOnStart: Bool = false
    @Published var automaticUpdates: Bool = false
    @Published var updateInterval: String?

    let updateOnStartSubject = PassthroughSubject<Bool, Never>()
    let automaticUpdatesSubject = PassthroughSubject<Bool, Never>()

    private var configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration

        fetchValues()
        setupSubscriptions()
    }

    func fetchValues() {
        updateOnStart = configuration.updateOnStart
        automaticUpdates = configuration.automaticUpdates
        updateInterval = String(configuration.updateInterval)
    }

    func setupSubscriptions() {
        updateOnStartSubject
            .sink { [weak self] in
                self?.configuration.updateOnStart = $0
            }
            .store(in: &cancellable)

        automaticUpdatesSubject
            .sink { [weak self] in
                self?.configuration.automaticUpdates = $0
            }
            .store(in: &cancellable)
    }

    func refreshUpdateInterval() {
        updateInterval = String(configuration.updateInterval)
    }
}
