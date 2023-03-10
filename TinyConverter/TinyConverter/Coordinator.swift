//
//  Coordinator.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 22.11.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import UIKit

final class Coordinator {
    var rootViewController: UINavigationController!
    let container: RootComponent

    init(_ window: UIWindow, _ container: RootComponent) {
        self.container = container

        let converterVC = ConverterViewController(viewModel: self.container.converterComponent.converterViewModel)
        rootViewController = UINavigationController(rootViewController: converterVC)

        window.rootViewController = rootViewController
        window.makeKeyAndVisible()

        converterVC.delegate = self

        guard let rightBarButton = converterVC.navigationItem.rightBarButtonItem else { return }
        rightBarButton.title = "\u{2699}"
        rightBarButton.action = #selector(converterVC.delegate.navigateToSettings)
        rightBarButton.target = self
    }
}

extension Coordinator: ConverterViewControllerDelegate {
    func navigateToSettings() {
        let settingsVC = SettingsViewController(viewModel: self.container.settingsComponent.settingsViewModel)
        settingsVC.delegate = self

        rootViewController.pushViewController(settingsVC, animated: true)
    }
}

extension Coordinator: SettingsViewControllerDelegate {
    func selectUpdateInterval() {
        let updateIntervalVC = UpdateIntervalViewController(viewModel: self.container.updateIntervalComponent.updateIntervalViewModel)
        rootViewController.pushViewController(updateIntervalVC, animated: true)
    }
}
