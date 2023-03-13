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
        converterVC.navigationItem.title = "Tiny Converter"
        converterVC.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "\u{2699}", style: .plain, target: self, action: #selector(converterVC.delegate.navigateToSettings))

        let appearance = UINavigationBarAppearance()

        guard let navbar = converterVC.navigationController?.navigationBar else { return }
        navbar.standardAppearance = appearance
        navbar.compactAppearance = appearance
        navbar.scrollEdgeAppearance = appearance
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
