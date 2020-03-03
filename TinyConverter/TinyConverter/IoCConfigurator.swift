//
//  IoCConfigurator.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 03.03.20.
//  Copyright © 2020 Adnan Zildzic. All rights reserved.
//
import UIKit
import SwinjectStoryboard

extension SwinjectStoryboard {
    static let container = SwinjectStoryboard.defaultContainer

    @objc class func setup() {
        // MARK: - Services
        container.register(CacheService.self) { _ in FileCacheService() }
        container.register(ApiService.self) { _ in FixerApiService() }

        // MARK: - Models
        container.register(Configuration.self) { _ in
            StandardConfiguration()
        }.inObjectScope(.container)

        container.register(Store.self) { resolver in
            ConverterStore(apiService: resolver.resolve(ApiService.self)!, cacheService: resolver.resolve(CacheService.self)!)
        }.inObjectScope(.container)

        // MARK: - View Models
        container.register(ConverterViewModel.self) { resolver in
            ConverterViewModel(store: resolver.resolve(Store.self)!, configuration: resolver.resolve(Configuration.self)!)
        }

        container.register(SettingsViewModel.self) { resolver in
            SettingsViewModel(configuration: resolver.resolve(Configuration.self)!)
        }

        container.register(UpdateIntervalViewModel.self) { resolver in
            UpdateIntervalViewModel(configuration: resolver.resolve(Configuration.self)!)
        }

        // MARK: - Controllers
        container.storyboardInitCompleted(ConverterViewController.self) { resolver, controller in
            controller.viewModel = resolver.resolve(ConverterViewModel.self)
        }

        container.storyboardInitCompleted(SettingsViewController.self) { resolver, controller in
            controller.viewModel = resolver.resolve(SettingsViewModel.self)
        }

        container.storyboardInitCompleted(UpdateIntervalViewController.self) { resolver, controller in
            controller.viewModel = resolver.resolve(UpdateIntervalViewModel.self)
        }
    }
}
