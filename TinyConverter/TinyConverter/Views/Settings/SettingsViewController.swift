//
//  SettingsTableViewController.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 13.02.20.
//  Copyright © 2020 Adnan Zildzic. All rights reserved.
//
import UIKit
import Combine

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

    private var cancellable = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.$updateOnStart
            .receive(on: RunLoop.main)
            .assign(to: \.isOn, on: updateOnStartSwitch)
            .store(in: &cancellable)

        viewModel.$automaticUpdates
            .receive(on: RunLoop.main)
            .assign(to: \.isOn, on: autoUpdatesSwitch)
            .store(in: &cancellable)

        viewModel.$updateInterval
            .receive(on: RunLoop.main)
            .assign(to: \.text, on: updateIntervalValueLabel)
            .store(in: &cancellable)

        viewModel.$automaticUpdates
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }

                self.updateIntervalCell.isUserInteractionEnabled = self.autoUpdatesSwitch.isOn
                self.updateIntervalCell.accessoryType = self.autoUpdatesSwitch.isOn ? .disclosureIndicator : .none
            }
            .store(in: &cancellable)
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
