//
//  SettingsTableViewController.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 13.02.20.
//  Copyright © 2020 Adnan Zildzic. All rights reserved.
//
import UIKit

protocol SettingsViewControllerDelegate: class {
    func selectUpdateInterval()
}

class SettingsViewController: UITableViewController {
    @IBOutlet weak var updateOnStartSwitch: UISwitch!
    @IBOutlet weak var autoUpdatesSwitch: UISwitch!
    @IBOutlet weak var updateIntervalValueLabel: UILabel!
    @IBOutlet weak var updateIntervalCell: UITableViewCell!

    weak var delegate: SettingsViewControllerDelegate!

    var viewModel: SettingsViewModel!
    var observations = [NSKeyValueObservation]()

    override func viewDidLoad() {
        super.viewDidLoad()

        observations = [
            viewModel.bind(\.updateOnStart, to: updateOnStartSwitch, at: \.isOn),
            viewModel.bind(\.automaticUpdates, to: autoUpdatesSwitch, at: \.isOn),
            viewModel.bind(\.updateInterval, to: updateIntervalValueLabel, at: \.text),
            viewModel.observe(\.automaticUpdates, options: [.initial, .new]) { [weak self] _, _ in
                guard let self = self else { return }

                self.updateIntervalCell.isUserInteractionEnabled = self.autoUpdatesSwitch.isOn
                self.updateIntervalCell.accessoryType = self.autoUpdatesSwitch.isOn ? .disclosureIndicator : .none
            }
        ]
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.refreshUpdateInterval()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 2 {
            delegate.selectUpdateInterval()
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }

    @IBAction func updateOnStartToggled(_ sender: UISwitch) {
        viewModel.updateOnStart = sender.isOn
    }

    @IBAction func autoUpdatesToggled(_ sender: UISwitch) {
        viewModel.automaticUpdates = sender.isOn
    }
}
