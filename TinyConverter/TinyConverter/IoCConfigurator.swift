//
//  IoCConfigurator.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 03.03.20.
//  Copyright © 2020 Adnan Zildzic. All rights reserved.
//

import NeedleFoundation

class RootComponent: BootstrapComponent {
    private var cacheService: CacheService {
        FileCacheService()
    }

    private var apiService: ApiService {
        FixerApiService()
    }


    var configuration: Configuration {
        shared { StandardConfiguration() }
    }

    var store: Store {
        shared { ConverterStore(apiService: apiService, cacheService: cacheService) }
    }

    var converterComponent: ConverterComponent {
        ConverterComponent(parent: self)
    }

    var settingsComponent: SettingsComponent {
        SettingsComponent(parent: self)
    }

    var updateIntervalComponent: UpdateIntervalComponent {
        UpdateIntervalComponent(parent: self)
    }
}

protocol ConverterDependency: Dependency {
    var configuration: Configuration { get }
    var store: Store { get }
}

class ConverterComponent: Component<ConverterDependency> {
    var converterViewModel: ConverterViewModel {
        ConverterViewModel(store: dependency.store, configuration: dependency.configuration)
    }
}

protocol SettingsDependency: Dependency {
    var configuration: Configuration { get }
}

class SettingsComponent: Component<SettingsDependency> {
    var settingsViewModel: SettingsViewModel {
        SettingsViewModel(configuration: dependency.configuration)
    }
}

class UpdateIntervalComponent: Component<SettingsDependency> {
    var updateIntervalViewModel: UpdateIntervalViewModel {
        UpdateIntervalViewModel(configuration: dependency.configuration)
    }
}
