//
//  Coordinator.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 22.11.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import UIKit
import SwinjectStoryboard

final class Coordinator {
    let rootViewController: UINavigationController
    let storyboard = SwinjectStoryboard.create(name: "Main", bundle: nil)

    init(_ window: UIWindow) {
        let converterVC = storyboard.instantiateViewController(withIdentifier: "converterViewController") as! ConverterViewController
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
        let settingsVC = storyboard.instantiateViewController(withIdentifier: "settingsViewController") as! SettingsViewController
        settingsVC.delegate = self

        rootViewController.pushViewController(settingsVC, animated: true)
    }
}

extension Coordinator: SettingsViewControllerDelegate {
    func selectUpdateInterval() {
        let updateIntervalVC = storyboard.instantiateViewController(withIdentifier: "updateIntervalViewController") as! UpdateIntervalViewController
        rootViewController.pushViewController(updateIntervalVC, animated: true)
    }
}
